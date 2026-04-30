import Foundation
import Combine

// Author = "Inventions4All - github:TWeb79"

/// Core synchronization engine that wraps rsync execution
@MainActor
class SyncEngine: ObservableObject {
    @Published var isRunning = false
    @Published var progress = SyncProgress()
    @Published var logLines: [String] = []
    
    private var currentProcess: Process?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?
    
    /// Progress tracking for sync operations
    struct SyncProgress {
        var filesTransferred: Int = 0
        var totalBytes: Int64 = 0
        var currentFile: String = ""
    }
    
    /// Run a sync job with the given configuration
    func runSync(job: SyncJob, rsyncPath: String) async throws -> SyncRunResult {
        isRunning = true
        progress = SyncProgress()
        logLines = []
        
        let startTime = Date()
        
        // Build rsync arguments
        var args = buildRsyncArguments(for: job)
        
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
        
        self.outputPipe = outputPipe
        self.errorPipe = errorPipe
        self.currentProcess = process
        
        // Read output asynchronously
        let outputHandle = outputPipe.fileHandleForReading
        let errorHandle = errorPipe.fileHandleForReading
        
        // Set up async reading
        outputHandle.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty, let line = String(data: data, encoding: .utf8) {
                Task { @MainActor in
                    self?.handleOutputLine(line)
                }
            }
        }
        
        errorHandle.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty, let line = String(data: data, encoding: .utf8) {
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
            
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            isRunning = false
            
            // Create result
            let result = SyncRunResult(
                jobId: job.id,
                jobName: job.name,
                startTime: startTime,
                endTime: endTime,
                status: process.terminationStatus == 0 ? .success : .error,
                filesTransferred: progress.filesTransferred,
                filesSkipped: 0,
                totalSize: progress.totalBytes,
                errorMessage: process.terminationStatus != 0 ? "rsync exited with code \(process.terminationStatus)" : nil
            )
            
            return result
        } catch {
            isRunning = false
            handleErrorLine("Failed to start rsync: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Cancel the current sync operation
    func cancelSync() {
        currentProcess?.terminate()
        currentProcess = nil
        isRunning = false
        logLines.append("Sync cancelled by user")
    }
    
    // MARK: - Private Methods
    
    private func buildRsyncArguments(for job: SyncJob) -> [String] {
        var args: [String] = []
        
        // Archive mode
        args.append("-a")
        
        // Progress info for parsing
        args.append("--info=progress2")
        
        // Verbose
        args.append("-v")
        
        // Handle sync mode
        switch job.syncMode {
        case .mirror:
            args.append("--delete")
        case .oneWayCopy:
            // Default behavior, no extra flags
            break
        case .twoWaySync:
            args.append("--update")
        }
        
        // Preserve permissions if enabled
        if job.preservePermissions {
            args.append("--perms")
        }
        
        // Handle symlinks
        if job.followSymlinks {
            args.append("-L")
        } else {
            args.append("-l")
        }
        
        // Skip hidden files if enabled
        if job.skipHiddenFiles {
            args.append("--exclude='.*'")
        }
        
        // Include patterns
        for pattern in job.includePatterns {
            args.append("--include=\(pattern)")
        }
        
        // Exclude patterns
        for pattern in job.excludePatterns {
            args.append("--exclude=\(pattern)")
        }
        
        // Dry run for testing (comment out for production)
        // args.append("--dry-run")
        
        return args
    }
    
    private func handleOutputLine(_ line: String) {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            logLines.append(trimmed)
            parseProgress(from: trimmed)
        }
    }
    
    private func handleErrorLine(_ line: String) {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            logLines.append("[ERROR] \(trimmed)")
        }
    }
    
    /// Parse progress information from rsync output
    private func parseProgress(from line: String) {
        // Look for file transfer progress (e.g., "file.txt")
        // Match rsync --info=progress2 format: lines with % and to-check=
        // These indicate individual files being transferred
        if line.contains("%") && line.contains("to-check=") {
            progress.filesTransferred += 1
        }
        
        // Also parse total bytes from summary lines
        if line.contains("sent") && line.contains("bytes") {
            let components = line.components(separatedBy: " ")
            for (index, component) in components.enumerated() {
                if component == "bytes" {
                    if index > 0, let bytes = Int64(components[index - 1]) {
                        progress.totalBytes = bytes
                    }
                }
            }
        }
    }
}