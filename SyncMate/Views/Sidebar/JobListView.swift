import SwiftUI

// Author = "Inventions4All - github:TWeb79"

/// Sidebar view displaying the list of sync jobs
struct JobListView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddJob = false
    @State private var newJobName = ""
    @State private var showingDeleteAlert = false
    @State private var jobToDelete: SyncJob?
    
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
                List(selection: $appState.selectedJob) {
                    ForEach(appState.jobs) { job in
                        JobRowView(job: job)
                            .tag(job.id)
                            .contextMenu {
                                Button(role: .destructive) {
                                    jobToDelete = job
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete Job", systemImage: "trash")
                                }
                            }
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
        .alert("Delete Job?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let job = jobToDelete {
                    appState.deleteJob(job)
                }
            }
        } message: {
            if let job = jobToDelete {
                Text("Delete '\(job.name)'? This cannot be undone.")
            }
        }
        .onChange(of: showingDeleteAlert) { _, _ in
            if !showingDeleteAlert {
                jobToDelete = nil
            }
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
    
    private func deleteJobs(at offsets: IndexSet) {
        for index in offsets {
            let job = appState.jobs[index]
            appState.deleteJob(job)
        }
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
                    Text(job.syncMode.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let lastRun = job.lastRunAt {
                        Text(timeAgo(date: lastRun))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Never run")
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
    
    private func timeAgo(date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    JobListView()
        .environmentObject(AppState())
}
