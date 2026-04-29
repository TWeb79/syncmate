# SyncMate

A professional folder synchronization tool for macOS, inspired by robocopy/rsync with a clean, native SwiftUI interface.

## Features

- **Multiple Sync Jobs**: Create and manage multiple named synchronization jobs
- **Flexible Sync Modes**: Mirror, One-Way Copy, and Two-Way Sync
- **File Filtering**: Include/exclude patterns (e.g., `*.tmp`, `.DS_Store`)
- **Scheduler**: Automated sync via launchd (time-based, daily, weekly, on login/wake)
- **Run History**: Track the last 30 runs per job with detailed logs
- **Notifications**: macOS notifications on sync completion (success/warning/error)
- **Real-time Logging**: Live rsync output streaming

## Requirements

- macOS 13 Ventura or later
- Xcode 15+
- rsync (pre-installed on macOS, or via Homebrew)

## Installation

1. Clone the repository
2. Generate the Xcode project:
   ```bash
   xcodegen generate
   ```
3. Open `SyncMate.xcodeproj` in Xcode
4. Build and run (Cmd+R)

## Usage

### Creating a Sync Job

1. Click the **+** button in the toolbar to add a new job
2. Enter a name for the job
3. Select source and destination folders using the folder picker
4. Choose a sync mode:
   - **Mirror**: Destination matches source exactly (deletes extras)
   - **One-Way Copy**: Copy new/changed files, never delete
   - **Two-Way Sync**: Bidirectional sync, newest file wins
5. Configure optional filters and options
6. Click **Save**

### Running a Sync

- Click **Run Now** in the toolbar to start the selected job
- View real-time progress in the Log tab
- Enable schedules in the Schedule tab for automated syncs

### Settings

Access app settings via the gear icon:
- Launch at login
- Log retention period
- Rsync binary path
- Notification preferences
- Global bandwidth limit

## Architecture

```
SyncMate/
├── App/                    # Application entry point
├── Models/                 # Data models (SyncJob, SyncSchedule, SyncRunResult)
├── Views/                  # SwiftUI views
│   ├── Sidebar/           # Job list sidebar
│   ├── Detail/            # Job detail views (Overview, Settings, Schedule, History, Log)
│   ├── Shared/            # Reusable components
│   └── Settings/          # App settings
├── Services/              # Business logic
│   ├── SyncEngine.swift   # rsync wrapper
│   ├── SchedulerService.swift  # launchd management
│   ├── NotificationService.swift
│   └── LogStore.swift     # Persistent log storage
└── Utilities/             # Helper utilities
```

## Sync Modes Explained

### Mirror (`rsync -av --delete`)
- Source is the master; destination is an exact copy
- Files deleted in source are deleted in destination
- Use with caution!

### One-Way Copy (`rsync -av`)
- Copy new and changed files from source to destination
- Never deletes files in destination
- Safe for backups

### Two-Way Sync (`rsync -av --update` bidirectional)
- Syncs changes in both directions
- Newer file wins on conflicts
- Maintains consistency between both folders

## Technical Details

- **Persistence**: UserDefaults with JSON encoding
- **Scheduling**: launchd plist files in `~/Library/LaunchAgents/`
- **Sync Engine**: Swift Process API wrapping rsync
- **UI Framework**: SwiftUI with NavigationSplitView

## License

MIT License