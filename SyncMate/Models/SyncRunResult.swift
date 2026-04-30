import Foundation

// Author = "Inventions4All - github:TWeb79"

/// Represents the result of a sync run
struct SyncRunResult: Identifiable, Codable, Equatable {
    var id: UUID
    var jobId: UUID
    var jobName: String
    var startTime: Date
    var endTime: Date?
    var status: SyncStatus
    var filesTransferred: Int
    var filesSkipped: Int
    var totalSize: Int64
    var errorMessage: String?
    var logOutput: String
    
    init(
        id: UUID = UUID(),
        jobId: UUID,
        jobName: String,
        startTime: Date = Date(),
        endTime: Date? = nil,
        status: SyncStatus = .running,
        filesTransferred: Int = 0,
        filesSkipped: Int = 0,
        totalSize: Int64 = 0,
        errorMessage: String? = nil,
        logOutput: String = ""
    ) {
        self.id = id
        self.jobId = jobId
        self.jobName = jobName
        self.startTime = startTime
        self.endTime = endTime
        self.status = status
        self.filesTransferred = filesTransferred
        self.filesSkipped = filesSkipped
        self.totalSize = totalSize
        self.errorMessage = errorMessage
        self.logOutput = logOutput
    }
    
    /// Duration of the sync run
    var duration: TimeInterval {
        guard let endTime = endTime else {
            return Date().timeIntervalSince(startTime)
        }
        return endTime.timeIntervalSince(startTime)
    }
    
    /// Formatted duration string
    var durationString: String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    /// Formatted total size string
    var totalSizeString: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSize)
    }
    
    /// Formatted start time string
    var startTimeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
}