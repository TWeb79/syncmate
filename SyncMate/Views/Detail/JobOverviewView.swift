import SwiftUI

/// Overview tab showing sync job summary and quick actions
struct JobOverviewView: View {
    @EnvironmentObject var appState: AppState
    let job: SyncJob
    @State private var isRunning = false
    @State private var showingLog = false
    
    private var lastResult: SyncRunResult? {
        appState.logStore.lastResult(for: job.id)
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
    }
    
    private var runButton: some View {
        Button(action: runSync) {
            HStack {
                if isRunning {
                    ProgressView()
                        .scaleEffect(0.8)
                        .padding(.trailing, 4)
                } else {
                    Image(systemName: "play.fill")
                }
                Text(isRunning ? "Running..." : "Run Now")
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(appState.isRunning)
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
}