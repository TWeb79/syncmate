import Foundation

// Author = "Inventions4All - github:TWeb79"

/// Represents a synchronization job configuration
struct SyncJob: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var sourcePath: String
    var destinationPath: String
    var syncMode: SyncMode
    var includePatterns: [String]
    var excludePatterns: [String]
    var preservePermissions: Bool
    var followSymlinks: Bool
    var skipHiddenFiles: Bool
    var schedules: [SyncSchedule]
    var createdAt: Date
    var lastRunAt: Date?
    var lastRunResult: SyncStatus?
    
    init(
        id: UUID = UUID(),
        name: String = "New Sync Job",
        sourcePath: String = "",
        destinationPath: String = "",
        syncMode: SyncMode = .oneWayCopy,
        includePatterns: [String] = [],
        excludePatterns: [String] = [".DS_Store", "*.tmp", "*.swp"],
        preservePermissions: Bool = true,
        followSymlinks: Bool = false,
        skipHiddenFiles: Bool = false,
        schedules: [SyncSchedule] = [],
        createdAt: Date = Date(),
        lastRunAt: Date? = nil,
        lastRunResult: SyncStatus? = nil
    ) {
        self.id = id
        self.name = name
        self.sourcePath = sourcePath
        self.destinationPath = destinationPath
        self.syncMode = syncMode
        self.includePatterns = includePatterns
        self.excludePatterns = excludePatterns
        self.preservePermissions = preservePermissions
        self.followSymlinks = followSymlinks
        self.skipHiddenFiles = skipHiddenFiles
        self.schedules = schedules
        self.createdAt = createdAt
        self.lastRunAt = lastRunAt
        self.lastRunResult = lastRunResult
    }
}

// MARK: - Run Result Handling

extension SyncJob {
    mutating func addRunResult(_ result: SyncRunResult) {
        self.lastRunResult = result.status
        self.lastRunAt = result.endTime ?? Date()
        // Also store in LogStore
        LogStore.shared.addResult(result)
    }
}

/// Synchronization mode options
enum SyncMode: String, Codable, CaseIterable, Identifiable {
    case mirror = "Mirror"
    case oneWayCopy = "One-Way Copy"
    case twoWaySync = "Two-Way Sync"
    
    var id: String { rawValue }
    
    /// Returns the rsync flags for this sync mode
    var rsyncFlags: [String] {
        switch self {
        case .mirror:
            return ["-av", "--delete"]
        case .oneWayCopy:
            return ["-av"]
        case .twoWaySync:
            return ["-av", "--update"]
        }
    }
    
    /// Human-readable description of the sync mode
    var description: String {
        switch self {
        case .mirror:
            return "Destination matches source exactly (deletes extras)"
        case .oneWayCopy:
            return "Copy new/changed files, never delete"
        case .twoWaySync:
            return "Bidirectional sync, newest file wins"
        }
    }
}

/// Status of a sync run
enum SyncStatus: String, Codable {
    case success = "Success"
    case warning = "Warning"
    case error = "Error"
    case running = "Running"
    case idle = "Idle"
    
    var systemImage: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .running: return "arrow.triangle.2.circlepath"
        case .idle: return "circle"
        }
    }
}