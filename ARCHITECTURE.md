# Architecture Documentation

## System Structure

SyncMate is a macOS folder synchronization tool built with SwiftUI and the Combine framework. It wraps the `rsync` command-line utility to provide reliable file synchronization with a native user interface.

```
User Interface (SwiftUI)
    │
    ├── App Layer: AppState, AppDelegate
    │
    ├── View Layer: SwiftUI Views (Sidebar, Detail, Settings)
    │
    ├── Service Layer: SyncEngine, SchedulerService,
    │                  NotificationService, LogStore
    │
    └── Model Layer: SyncJob, SyncSchedule, SyncRunResult
```

## Module Responsibilities

### App/ (Application Layer)
- **AppState.swift**: Central state management for the application. Coordinates sync engine, jobs, and settings. ObservableObject published to all views.
- **SyncMateApp.swift**: Main entry point. Sets up window, menu commands, and environment.

### Models/ (Data Layer)
- **SyncJob.swift**: Encapsulates a single synchronization job configuration (source, destination, filters, modes).
- **SyncSchedule.swift**: Defines automated execution schedules (interval, daily, weekly).
- **SyncRunResult.swift**: Captures the outcome of a single sync operation.

### Services/ (Business Logic Layer)
- **SyncEngine.swift**: Core synchronization engine. Wraps `rsync` Process execution, real-time output parsing, progress tracking. Runs on @MainActor.
- **SchedulerService.swift**: Manages launchd plist creation, loading, and unloading for automated sync schedules.
- **NotificationService.swift**: Handles macOS UserNotifications authorization and delivery for sync completion events.
- **LogStore.swift**: Persistent storage of sync run history using UserDefaults with JSON encoding.

### Views/ (Presentation Layer)
- **Sidebar/**: Job list navigation and creation
- **Detail/**: Per-job configuration (Overview, Settings, Schedule, History, Log tabs)
- **Settings/**: Application-wide preferences
- **Shared/**: Reusable UI components (EmptyStateView, StatusBadgeView)

### Utilities/ (Helper Layer)
- **FilePickerHelper.swift**: NSOpenPanel wrapper for folder selection and rsync path discovery.
- **LaunchdPlistBuilder.swift**: Generates launchd XML plist files from schedule configurations.

## Data Flow

```
User Action (e.g., Run Job)
    │
    ▼
AppState.runJob(job)
    │
    ▼
SyncEngine.runSync(job)  [async, @MainActor]
    │
    ├─> Build rsync arguments from job config
    ├─> Spawn Process (rsync)
    ├─> Pipe stdout/stderr → handleOutputLine / handleErrorLine
    ├─> Parse progress → update SyncProgress @Published
    ├─> Append log lines → trigger UI updates
    └─> On completion: return SyncRunResult
          │
          ▼
    job.addRunResult(result)
          │
          ▼
    LogStore.shared.addResult(result)  [persistent]
          │
          ▼
    NotificationService.sendSyncNotification(for: job, result: result)
```

## External Dependencies

- **rsync**: System binary at `/usr/bin/rsync` (or Homebrew path). Core synchronization engine.
- **launchd**: macOS system daemon for schedule execution.
- **UserNotifications**: macOS framework for desktop notifications.
- **Combine**: Apple framework for reactive state management.
- **SwiftUI**: Apple framework for declarative UI.

## Service Boundaries

- **AppState** is the single source of truth for UI state (jobs, selection, running status).
- **SyncEngine** is the only component that spawns processes and interacts with rsync.
- **SchedulerService** is the only component that manages launchd plists.
- **LogStore** is the only component that reads/writes persistent history.
- **Views** never contain business logic - all actions delegated to AppState or Services.

## Persistence Strategy

- **Jobs**: Saved to UserDefaults as JSON on every modification (add, delete, update).
- **Run History**: Saved to UserDefaults as JSON after each sync completion. Max 30 results per job.
- **Settings**: Individual UserDefaults keys for each preference (rsync path, notifications, etc.).

## Threading Model

- All UI and state updates occur on the main thread via @MainActor.
- SyncEngine operations run asynchronously but publish all state changes on the main actor.
- Process pipes use background threads for I/O, then dispatch to main via Task { @MainActor }.
- Timer callbacks dispatch to main actor before updating progress.
