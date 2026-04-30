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

### Deleting Jobs

- Right-click any job in the sidebar and select **Delete Job**, or use the `Delete` key
- Confirm the deletion in the dialog
- Deleting a job removes its schedules and run history

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

## Changelog

### [Unreleased]

#### Bug Fixes
- Fixed `JobRowView` hardcoded sync mode string - now displays actual `job.syncMode.rawValue`
- Fixed `JobListView` selection binding - `List` now properly binds to `appState.selectedJob`
- Fixed `SyncJob` to conform to `Hashable` for proper selection tracking
- Fixed `ScheduleRowView` delete action to actually remove schedule from `job.schedules`
- Fixed `AppState.runJob` error handling - now catches errors and updates `lastRunResult` to `.error`
- Fixed `JobOverviewView` to use `appState.isRunning` directly instead of local state
- Fixed toolbar button duplication - removed duplicate "Run Now" from ContentView
- Fixed toolbar `+` button to use consistent job creation flow

#### Missing Features
- Added **Cancel** button in `JobDetailView` toolbar when sync is running
- Added right-click context menu and swipe-to-delete on job rows
- Added **Export** button in `JobHistoryView` filter bar with NSSavePanel
- Implemented **Launch at Login** toggle using `SMAppService.mainApp` (macOS 13+)

#### UX Improvements
- `JobRowView` now shows relative last run time (e.g., "2 hours ago") instead of raw status
- `JobOverviewView` displays live elapsed time counter during sync
- `JobOverviewView` shows live `filesTransferred` count during sync
- `JobSettingsView` validates paths and shows inline warning if directory doesn't exist
- `JobSettingsView` shows rsync availability indicator with path
- Added confirmation dialogs for "Reset All Settings" and "Clear All Logs"
- Added keyboard shortcut hint in `EmptyStateView` ("Press ⌘N to create your first sync job")
- Added `.help()` tooltips to all toolbar buttons and toggles

#### Code Quality
- Consolidated duplicate `selectFolder` function in `FilePickerHelper`
- Improved `SyncEngine.parseProgress` to count individual file lines

## License

MIT License
