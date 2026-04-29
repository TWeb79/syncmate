import Foundation
import Combine

/// Service responsible for executing sync operations using rsync
@MainActor
class SyncEngine: ObservableObject {
    /// Currently running process
    private var currentProcess: Process?
    
    /// Output buffer for log lines
    @Published var logLines: [String] = []
    
    /// Current run result being built
    @Published var currentRunResult: SyncRunResult?
    
    /// Whether a sync is currently running
    @Published var isRunning: Bool = false
    
    /// Progress information
    @Published var progress: SyncProgress = SyncProgress()
    
    /// Reference to the job being synced
    private var currentJob: SyncJob?
    
    /// Timer for updating progress
    private var progressTimer: Timer?
    
    /// Initialize the sync engine
    init() {}
    
    /// Execute a sync job
    func runSync(job: SyncJob, rsyncPath: String = "/usr/bin/rsync", bandwidthLimit: Int? = nil) async throws -> SyncRunResult {
        guard !isRunning else {
            throw SyncError.alreadyRunning
        }
        
        currentJob = job
        isRunning = true
        logLines = []
        progress = SyncProgress()
        
        // Create initial run result
        var runResult = SyncRunResult(
            jobId: job.id,
            jobName: job.name,
            startTime: Date()
        )
        currentRunResult = runResult
        
        // Start progress timer
        startProgressTimer()
        
        // Build rsync arguments
        var args = buildRsyncArguments(for: job, bandwidthLimit: bandwidthLimit)
        
        // Add source and destination
        args.append(job.sourcePath)
        args.append(job.destinationPath)
        
        // Create process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: rsyncPath)
        process.arguments = args
        
        // Set up pipes
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        currentProcess = process
        
        // Read output asynchronously
        let outputHandle = outputPipe.fileHandleForReading
        let errorHandle = errorPipe.fileHandleForReading
        
        // Set up output reading
        outputHandle.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if let line = String(data: data, encoding: .utf8), !line.isEmpty {
                Task { @MainActor in
                    self?.handleOutputLine(line)
                }
            }
        }
        
        errorHandle.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if let line = String(data: data, encoding: .utf8), !line.isEmpty {
                Task { @MainActor in
                    self?.handleErrorLine(line)
                }
            }
        }
        
        do {
            try process.run()
            process.waitUntilExit()
            
            // Clean up handlers
            outputHandle.readabilityHandler = nil
            errorHandle.readabilityHandler = nil
            
            // Determine final status
            if process.terminationStatus == 0 {
                runResult.status = .success
            } else if process.terminationStatus == 23 || process.terminationStatus == 24 {
                // Partial transfer or vanished source
                runResult.status = .warning
                runResult.errorMessage = "rsync completed with warnings (exit code \(process.terminationStatus))"
            } else {
                runResult.status = .error
                runResult.errorMessage = "rsync failed with exit code \(process.terminationStatus)"
            }
        } catch {
            runResult.status = .error
            runResult.errorMessage = error.localizedDescription
        }
        
        // Finalize run result
        runResult.endTime = Date()
        runResult.logOutput = logLines.joined(separator: "\n")
        runResult.filesTransferred = progress.filesTransferred
        runResult.filesSkipped = progress.filesSkipped
        runResult.totalSize = progress.totalBytes
        
        stopProgressTimer()
        isRunning = false
        currentProcess = nil
        currentRunResult = runResult
        
        return runResult
    }
    
    /// Cancel the current sync operation
    func cancelSync() {
        currentProcess?.terminate()
        currentProcess = nil
        isRunning = false
        stopProgressTimer()
        
        if var result = currentRunResult {
            result.status = .error
            result.errorMessage = "Sync cancelled by user"
            result.endTime = Date()
            currentRunResult = result
        }
    }
    
    /// Build rsync arguments based on job configuration
    private func buildRsyncArguments(for job: SyncJob, bandwidthLimit: Int?) -> [String] {
        var args: [String] = []
        
        // Add mode-specific flags
        args.append(contentsOf: job.syncMode.rsyncFlags)
        
        // Preserve permissions
        if job.preservePermissions {
            args.append("--perms")
        }
        
        // Follow symlinks
        if !job.followSymlinks {
            args.append("--no-links")
        }
        
        // Skip hidden files
        if job.skipHiddenFiles {
            args.append("--exclude='.*'")
        }
        
        // Add exclude patterns
        for pattern in job.excludePatterns {
            args.append("--exclude=\(pattern)")
        }
        
        // Add include patterns
        for pattern in job.includePatterns {
            args.append("--include=\(pattern)")
        }
        
        // Add bandwidth limit if specified
        if let limit = bandwidthLimit, limit > 0 {
            args.append("--bwlimit=\(limit)")
        }
        
        // Progress output
        args.append("--info=progress2")
        
        // Verbose for logging
        args.append("-v")
        
        return args
    }
    
    /// Handle output line from rsync
    private func handleOutputLine(_ line: String) {
        logLines.append(line)
        
        // Parse progress information
        parseProgress(from: line)
    }
    
    /// Handle error line from rsync
    private func handleErrorLine(_ line: String) {
        logLines.append("[ERROR] \(line)")
    }
    
    /// Parse progress information from rsync output
    private func parseProgress(from line: String) {
        // Look for file transfer progress (e.g., "file.txt")
        if line.contains("sent") && line.contains("bytes") {
            // Summary line - parse bytes
            let components = line.components(separatedBy: " ")
            for (index, component) in components.enumerated() {
                if component == "bytes" {
                    if index > 0, let bytes = Int64(components[index - 1]) {
                        progress.totalBytes = bytes
                    }
                }
            }
        }
        
        // Count file transfers
        if line.contains("sent") && line.contains("received") {
            progress.filesTransferred += 1
        }
    }
    
    /// Start the progress timer
    private func startProgressTimer() {
        progress.startTime = Date()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateProgress()
            }
        }
    }
    
    /// Stop the progress timer
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    /// Update progress elapsed time
    private func updateProgress() {
        progress.elapsedTime = Date().timeIntervalSince(progress.startTime)
    }
}

/// Progress information for the current sync
struct SyncProgress {
    var filesTransferred: Int = 0
    var filesSkipped: Int = 0
    var totalBytes: Int64 = 0
    var elapsedTime: TimeInterval = 0
    var startTime: Date = Date()
    
    var elapsedTimeString: String {
        let totalSeconds = Int(elapsedTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var totalSizeString: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalBytes)
    }
}

/// Errors that can occur during sync
enum SyncError: LocalizedError {
    case alreadyRunning
    case rsyncNotFound
    case invalidPaths
    case processFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .alreadyRunning:
            return "A sync operation is already running"
        case .rsyncNotFound:
            return "rsync not found. Please install rsync or check the path in settings."
        case .invalidPaths:
            return "Invalid source or destination path"
        case .processFailed(let message):
            return "Sync failed: \(message)"
        }
    }
}