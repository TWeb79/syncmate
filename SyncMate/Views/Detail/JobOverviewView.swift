import SwiftUI

// Author = "Inventions4All - github:TWeb79"

/// Overview tab showing sync job summary and quick actions
struct JobOverviewView: View {
    @EnvironmentObject var appState: AppState
    let job: SyncJob
    @State private var showingLog = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer? = nil
    
    private var lastResult: SyncRunResult? {
        appState.logStore.lastResult(for: job.id)
    }
    
    private var isRunningThisJob: Bool {
        appState.isRunning && appState.selectedJob?.id == job.id
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with status
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(job.name)
                            .font(.title)
                            .fontWeight(.bold)
                        StatusBadgeView(status: job.lastRunResult ?? .idle)
                    }
                    Spacer()
                    runButton
                }
                
                // Live progress section (when running)
                if isRunningThisJob {
                    liveProgressSection
                }
                
                // Quick stats
                if let result = lastResult {
                    statsSection(lastResult: result)
                }
                
                // Source and destination
                foldersSection
                
                // Sync mode info
                syncModeSection
                
                // Recent activity
                recentActivitySection
            }
            .padding()
        }
        .sheet(isPresented: $showingLog) {
            JobLogView(syncEngine: appState.syncEngine)
        }
        .onAppear {
            startTimerIfNeeded()
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: appState.isRunning) { _, _ in
            startTimerIfNeeded()
        }
    }
    
    private var runButton: some View {
        Button(action: runSync) {
            HStack {
                if isRunningThisJob {
                    ProgressView()
                        .scaleEffect(0.8)
                        .padding(.trailing, 4)
                } else {
                    Image(systemName: "play.fill")
                }
                Text(isRunningThisJob ? "Running..." : "Run Now")
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(appState.isRunning)
        .help("Run this sync job now")
    }
    
    private var liveProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Live Progress")
                    .font(.headline)
                Spacer()
                Text(formattedElapsedTime)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 24) {
                VStack(alignment: .leading) {
                    Text("Files Transferred")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(appState.syncEngine.progress.filesTransferred)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)
                }
                
                VStack(alignment: .leading) {
                    Text("Bytes Sent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatBytes(appState.syncEngine.progress.totalBytes))
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(10)
    }
    
    private func runSync() {
        appState.runJob(job)
    }
    
    private func statsSection(lastResult: SyncRunResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last Run Summary")
                .font(.headline)
            
            HStack(spacing: 24) {
                VStack(alignment: .leading) {
                    Text("Duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(lastResult.durationString)
                        .font(.body)
                }
                
                VStack(alignment: .leading) {
                    Text("Files Transferred")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(lastResult.filesTransferred)")
                        .font(.body)
                }
                
                VStack(alignment: .leading) {
                    Text("Files Skipped")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(lastResult.filesSkipped)")
                        .font(.body)
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private var foldersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Folders")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "folder")
                        .foregroundColor(.blue)
                    Text(job.sourcePath.isEmpty ? "Not set" : job.sourcePath)
                        .lineLimit(1)
                }
                
                HStack {
                    Image(systemName: "arrow.right")
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Image(systemName: "folder")
                        .foregroundColor(.green)
                    Text(job.destinationPath.isEmpty ? "Not set" : job.destinationPath)
                        .lineLimit(1)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(10)
        }
    }
    
    private var syncModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sync Mode")
                .font(.headline)
            
            HStack(spacing: 12) {
                Image(systemName: syncModeIcon)
                    .font(.title)
                Text(job.syncMode.rawValue)
                    .font(.body)
                Text("-")
                Text(syncModeDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(10)
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
            
            if appState.logStore.runResults.isEmpty {
                Text("No recent sync activity")
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(appState.logStore.runResults.prefix(5)) { result in
                        if result.jobId == job.id {
                            HStack {
                                StatusBadgeView(status: result.status)
                                Text(result.jobName)
                                    .font(.subheadline)
                                Spacer()
                                Text(result.durationString)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(6)
                        }
                    }
                }
            }
        }
    }
    
    private var syncModeIcon: String {
        switch job.syncMode {
        case .mirror: return "arrow.left.arrow.right"
        case .oneWayCopy: return "arrow.right"
        case .twoWaySync: return "arrow.left.arrow.right.circle"
        }
    }
    
    private var syncModeDescription: String {
        switch job.syncMode {
        case .mirror:
            return "Destination matches source exactly"
        case .oneWayCopy:
            return "Copy new/changed files"
        case .twoWaySync:
            return "Bidirectional sync"
        }
    }
    
    // MARK: - Timer & Formatting Helpers
    
    private func startTimerIfNeeded() {
        stopTimer()
        if isRunningThisJob {
            elapsedTime = 0
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                elapsedTime += 1
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private var formattedElapsedTime: String {
        let totalSeconds = Int(elapsedTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
