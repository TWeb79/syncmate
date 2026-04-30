import Foundation

// Author = "Inventions4All - github:TWeb79"

/// Service responsible for managing scheduled sync jobs via launchd
class SchedulerService {
    /// Shared instance
    static let shared = SchedulerService()
    
    /// Launch agents directory
    private let launchAgentsPath: String
    
    private init() {
        launchAgentsPath = NSHomeDirectory() + "/Library/LaunchAgents"
    }
    
    /// Create a launchd plist for a sync job schedule
    func createLaunchdPlist(for job: SyncJob, schedule: SyncSchedule) throws -> URL {
        let plistBuilder = LaunchdPlistBuilder()
        let plistContent = plistBuilder.buildPlist(for: job, schedule: schedule)
        
        // Create LaunchAgents directory if needed
        let launchAgentsURL = URL(fileURLWithPath: launchAgentsPath)
        try FileManager.default.createDirectory(at: launchAgentsURL, withIntermediateDirectories: true)
        
        // Write plist file
        let plistFileName = "com.syncmate.\(job.id.uuidString).\(schedule.id.uuidString).plist"
        let plistURL = launchAgentsURL.appendingPathComponent(plistFileName)
        
        try plistContent.write(to: plistURL, atomically: true, encoding: .utf8)
        
        return plistURL
    }
    
    /// Remove a launchd plist for a schedule
    func removeLaunchdPlist(for job: SyncJob, schedule: SyncSchedule) throws {
        let plistFileName = "com.syncmate.\(job.id.uuidString).\(schedule.id.uuidString).plist"
        let plistURL = URL(fileURLWithPath: launchAgentsPath).appendingPathComponent(plistFileName)
        
        // Unload the job first
        try unloadJob(label: "com.syncmate.\(job.id.uuidString).\(schedule.id.uuidString)")
        
        // Remove the file
        if FileManager.default.fileExists(atPath: plistURL.path) {
            try FileManager.default.removeItem(at: plistURL)
        }
    }
    
    /// Remove all launchd plists for a job
    func removeSchedules(for jobId: UUID) throws {
        let jobs = getAllJobs().filter { $0.contains("com.syncmate.\(jobId.uuidString)") }
        for job in jobs {
            let label = job.components(separatedBy: " ").first ?? ""
            if !label.isEmpty {
                let plistFileName = "\(label).plist"
                let plistURL = URL(fileURLWithPath: launchAgentsPath).appendingPathComponent(plistFileName)
                try? unloadJob(label: label)
                if FileManager.default.fileExists(atPath: plistURL.path) {
                    try FileManager.default.removeItem(at: plistURL)
                }
            }
        }
    }
    
    /// Load a launchd job
    func loadJob(label: String) throws {
        let plistPath = "\(launchAgentsPath)/\(label).plist"
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["load", plistPath]
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw SchedulerError.loadFailed("Failed to load \(label)")
        }
    }
    
    /// Unload a launchd job
    func unloadJob(label: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["unload", "\(launchAgentsPath)/\(label).plist"]
        
        try process.run()
        process.waitUntilExit()
    }
    
    /// Check if a launchd job is loaded
    func isJobLoaded(label: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["list", label]
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    /// Enable a schedule by loading its launchd job
    func enableSchedule(for job: SyncJob, schedule: SyncSchedule) async throws {
        let plistURL = try createLaunchdPlist(for: job, schedule: schedule)
        let label = "com.syncmate.\(job.id.uuidString).\(schedule.id.uuidString)"
        try loadJob(label: label)
    }
    
    /// Disable a schedule by unloading its launchd job
    func disableSchedule(for job: SyncJob, schedule: SyncSchedule) throws {
        let label = "com.syncmate.\(job.id.uuidString).\(schedule.id.uuidString)"
        try unloadJob(label: label)
    }
    
    /// Get all SyncMate launchd jobs
    func getAllJobs() -> [String] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["list"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.components(separatedBy: "\n")
                    .filter { $0.contains("com.syncmate") }
            }
        } catch {
            return []
        }
        
        return []
    }
}

/// Errors that can occur during scheduling
enum SchedulerError: LocalizedError {
    case plistCreationFailed
    case loadFailed(String)
    case unloadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .plistCreationFailed:
            return "Failed to create launchd plist"
        case .loadFailed(let message):
            return "Failed to load launchd job: \(message)"
        case .unloadFailed(let message):
            return "Failed to unload launchd job: \(message)"
        }
    }
}
