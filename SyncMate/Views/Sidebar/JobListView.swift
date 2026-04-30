import SwiftUI

/// Sidebar view displaying the list of sync jobs
struct JobListView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddJob = false
    @State private var newJobName = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Sync Jobs")
                    .font(.headline)
                Spacer()
                Button(action: { showingAddJob = true }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .help("Add new sync job")
            }
            .padding()
            
            Divider()
            
            // Job list
            if appState.jobs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No sync jobs")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(appState.jobs) { job in
                    JobRowView(job: job)
                        .tag(job.id)
                }
                .listStyle(.sidebar)
            }
        }
        .frame(minWidth: 220)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { showingAddJob = true }) {
                    Image(systemName: "plus")
                }
                .help("Add new sync job")
            }
        }
        .alert("New Sync Job", isPresented: $showingAddJob) {
            TextField("Job Name", text: $newJobName)
            Button("Cancel", role: .cancel) {
                newJobName = ""
            }
            Button("Create") {
                createJob()
            }
        } message: {
            Text("Enter a name for your new sync job")
        }
    }
    
    private func createJob() {
        guard !newJobName.isEmpty else { return }
        let job = SyncJob(name: newJobName)
        appState.jobs.append(job)
        appState.selectedJob = job
        appState.saveJobs()
        newJobName = ""
    }
}

/// Row view for a single sync job in the sidebar
struct JobRowView: View {
    let job: SyncJob
    @State private var isRunning = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            JobStatusIndicator(
                status: job.lastRunResult ?? .idle,
                isAnimating: isRunning
            )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(job.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                HStack(spacing: 4) {
                    Text("One-Way Copy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let lastRun = job.lastRunResult {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(lastRun.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

#Preview {
    JobListView()
        .environmentObject(AppState())
}
