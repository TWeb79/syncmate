import SwiftUI

/// Main application entry point
@main
struct SyncMateApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Sync Job") {
                    appState.addJob()
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            CommandGroup(after: .sidebar) {
                Button("Run Selected Job") {
                    if let job = appState.selectedJob {
                        appState.runJob(job)
                    }
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
        
        Settings {
            AppSettingsView()
                .environmentObject(appState)
        }
    }
}

/// Main content view with NavigationSplitView layout
struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            JobListView()
        } detail: {
            if let job = appState.selectedJob,
               let index = appState.jobs.firstIndex(where: { $0.id == job.id }) {
                JobDetailView(job: Binding(
                    get: { appState.jobs[index] },
                    set: { appState.jobs[index] = $0; appState.saveJobs() }
                ))
            } else {
                EmptyStateView(
                    title: "No Job Selected",
                    message: "Select a sync job from the sidebar or create a new one",
                    systemImage: "folder.badge.plus",
                    actionTitle: "Create Job",
                    action: { appState.addJob() }
                )
            }
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { appState.addJob() }) {
                    Label("Add Job", systemImage: "plus")
                }
                
                Button(action: {
                    if let job = appState.selectedJob {
                        appState.runJob(job)
                    }
                }) {
                    Label("Run Now", systemImage: "play.fill")
                }
                .disabled(appState.selectedJob == nil || appState.isRunning)
                
                Button(action: { NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil) }) {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
    }
}

/// Detail view for a selected sync job with tabs
struct JobDetailView: View {
    @EnvironmentObject var appState: AppState
    @Binding var job: SyncJob
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            JobOverviewView(job: job)
                .tabItem {
                    Label("Overview", systemImage: "info.circle")
                }
                .tag(0)
            
            JobSettingsView(appState: appState, job: $job)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(1)
            
            JobScheduleView(appState: appState, job: $job)
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
                .tag(2)
            
            JobHistoryView(job: job)
                .tabItem {
                    Label("History", systemImage: "clock")
                }
                .tag(3)
            
            JobLogView(syncEngine: appState.syncEngine)
                .tabItem {
                    Label("Log", systemImage: "doc.text")
                }
                .tag(4)
        }
        .navigationTitle(job.name)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { appState.runJob(job) }) {
                    Label("Run Now", systemImage: "play.fill")
                }
                .disabled(appState.isRunning)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
