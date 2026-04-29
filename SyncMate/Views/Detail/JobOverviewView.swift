import SwiftUI

/// Overview tab showing sync job summary and quick actions
struct JobOverviewView: View {
    @ObservedObject var appState: AppState
    let job: SyncJob
    @State private var isRunning = false
    @State private var showingLog = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with status
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(job.name)
                            .font(.title)
                            .fontWeight(.bold)
                        StatusBadgeView(status: job.status)
                    }
                    Spacer()
                    runButton
                }
                
                // Quick stats
                if let lastResult = job.lastRunResult {
                    statsSection(lastResult: lastResult)
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
            JobLogView(job: job, appState: appState)
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
        .disabled(isRunning || job.status == .running)
    }
    
    private func statsSection(lastResult: SyncRunResult) -> some View {
        Section {
            HStack(spacing: 20) {
                StatCard(
                    title: "Files Synced",
                    value: "\(lastResult.filesSynced)",
                    icon: "doc.on.doc"
                )
                StatCard(
                    title: "Total Size",
                    value: ByteCountFormatter.string(fromByteCount: lastResult.totalBytes, countStyle: .file),
                    icon: "externaldrive"
                )
                StatCard(
                    title: "Duration",
                    value: lastResult.formattedDuration,
                    icon: "clock"
                )
                StatCard(
                    title: "Status",
                    value: lastResult.status.displayName,
                    icon: lastResult.status == .success ? "checkmark.circle" : 
                           lastResult.status == .warning ? "exclamationmark.triangle" : "xmark.circle"
                )
            }
        } header: {
            Text("Last Run Summary")
                .font(.headline)
        }
    }
    
    private var foldersSection: some View {
        Section {
            VStack(spacing: 12) {
                FolderPathRow(title: "Source", path: job.sourcePath, icon: "folder")
                FolderPathRow(title: "Destination", path: job.destinationPath, icon: "arrow.right.circle")
            }
        } header: {
            Text("Folders")
                .font(.headline)
        }
    }
    
    private var syncModeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: job.syncMode.icon)
                        .foregroundColor(.accentColor)
                    Text(job.syncMode.displayName)
                        .fontWeight(.medium)
                }
                Text(job.syncMode.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        } header: {
            Text("Sync Mode")
                .font(.headline)
        }
    }
    
    private var recentActivitySection: some View {
        Section {
            if job.runHistory.isEmpty {
                Text("No recent activity")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(job.runHistory.prefix(5)) { result in
                        HStack {
                            Image(systemName: result.status == .success ? "checkmark.circle.fill" :
                                  result.status == .warning ? "exclamationmark.triangle.fill" : "xmark.circle.fill")
                                .foregroundColor(result.status == .success ? .green :
                                                result.status == .warning ? .orange : .red)
                            VStack(alignment: .leading) {
                                Text(result.formattedDate)
                                    .font(.caption)
                                Text("\(result.filesSynced) files • \(result.formattedDuration)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            Button("View Full History") {
                showingLog = true
            }
            .buttonStyle(.link)
        } header: {
            Text("Recent Activity")
                .font(.headline)
        }
    }
    
    private func runSync() {
        isRunning = true
        Task {
            await SyncEngine.shared.runSync(job: job) { result in
                DispatchQueue.main.async {
                    isRunning = false
                    if let result = result {
                        appState.updateJobResult(jobId: job.id, result: result)
                    }
                }
            }
        }
    }
}

/// Card view for displaying a statistic
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

/// Row showing a folder path
struct FolderPathRow: View {
    let title: String
    let path: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(path.isEmpty ? "Not set" : path)
                    .font(.body)
                    .foregroundColor(path.isEmpty ? .secondary : .primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    JobOverviewView(appState: AppState(), job: SyncJob(name: "Test Job"))
}