import SwiftUI

/// Sidebar view displaying the list of sync jobs
struct JobListView: View {
    @ObservedObject var appState: AppState
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
            if appState.syncJobs.isEmpty {
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
                List(selection: $appState.selectedJobId) {
                    ForEach(appState.syncJobs) { job in
                        JobRowView(job: job, appState: appState)
                            .tag(job.id)
                    }
                    .onDelete(perform: deleteJobs)
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
        appState.syncJobs.append(job)
        appState.selectedJobId = job.id
        appState.saveJobs()
        newJobName = ""
    }
    
    private func deleteJobs(at offsets: IndexSet) {
        for index in offsets {
            let job = appState.syncJobs[index]
            // Remove associated schedules
            SchedulerService.shared.removeSchedules(for: job)
        }
        appState.syncJobs.remove(atOffsets: offsets)
        appState.saveJobs()
    }
}

/// Row view for a single sync job in the sidebar
struct JobRowView: View {
    let job: SyncJob
    @ObservedObject var appState: AppState
    @State private var isRunning = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            JobStatusIndicator(
                status: job.status,
                isAnimating: isRunning
            )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(job.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                HStack(spacing: 4) {
                    Text(job.syncMode.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let lastRun = job.lastRunResult {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(lastRun.formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Quick actions
            if job.status != .running {
                Button(action: { runJobNow() }) {
                    Image(systemName: "play.fill")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("Run now")
            } else {
                ProgressView()
                    .scaleEffect(0.6)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            appState.selectedJobId = job.id
        }
    }
    
    private func runJobNow() {
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

#Preview {
    JobListView(appState: AppState())
}