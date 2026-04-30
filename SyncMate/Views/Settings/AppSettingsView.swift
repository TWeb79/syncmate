import SwiftUI
import ServiceManagement
import Foundation

// Author = "Inventions4All - github:TWeb79"

/// App-level settings view
struct AppSettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
            SyncSettingsView()
                .tabItem {
                    Label("Sync", systemImage: "arrow.triangle.2.circlepath")
                }
            
            NotificationSettingsView()
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }
            
            AdvancedSettingsView()
                .tabItem {
                    Label("Advanced", systemImage: "slider.horizontal.3")
                }
        }
        .frame(width: 450, height: 300)
        .padding()
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLaunchError = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: Binding(
                    get: { UserDefaults.standard.bool(forKey: "launchAtLogin") },
                    set: { enabled in
                        UserDefaults.standard.set(enabled, forKey: "launchAtLogin")
                        updateLaunchAtLogin(enabled: enabled)
                    }
                ))
                .help("Automatically start SyncMate when you log in")
            } header: {
                Text("Startup")
            }
            
            Section {
                Picker("Log Retention", selection: $appState.logRetentionDays) {
                    Text("7 days").tag(7)
                    Text("14 days").tag(14)
                    Text("30 days").tag(30)
                    Text("90 days").tag(90)
                }
                .help("How long to keep sync run history")
            } header: {
                Text("History")
            }
        }
        .formStyle(.grouped)
        .alert("Could Not Enable Login Item", isPresented: $showLaunchError) {
            Button("OK") {}
        } message: {
            Text("Unable to register the login item. This may require additional permissions.")
        }
    }
    
    private func updateLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            showLaunchError = true
            // Revert the toggle
            UserDefaults.standard.set(!enabled, forKey: "launchAtLogin")
        }
    }
}

// MARK: - Sync Settings

struct SyncSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showRsyncPicker = false
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Rsync Path")
                    Spacer()
                    Text(appState.rsyncPath)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Button("Browse...") {
                        if let url = FilePickerHelper.selectFolder(title: "Select rsync Binary", mustExist: true) {
                            // Check if it's actually rsync
                            let path = url.path
                            if FilePickerHelper.isRsyncAvailable(at: path) {
                                appState.rsyncPath = path
                            } else {
                                // Maybe the selected folder contains rsync; try default location
                                let defaultPath = "/usr/bin/rsync"
                                appState.rsyncPath = FilePickerHelper.isRsyncAvailable(at: defaultPath) ? defaultPath : path
                            }
                        }
                    }
                    .help("Select the rsync binary path")
                }
            } header: {
                Text("Binary")
            }
            
            Section {
                HStack {
                    Text("Bandwidth Limit")
                    Spacer()
                    TextField("KB/s", value: $appState.bandwidthLimit, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    Text("KB/s")
                        .foregroundColor(.secondary)
                }
                
                Text("Leave at 0 for unlimited")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Performance")
            }
        }
        .formStyle(.grouped)
        .fileImporter(
            isPresented: $showRsyncPicker,
            allowedContentTypes: [.unixExecutable],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                appState.rsyncPath = url.path
            }
        }
    }
}

// MARK: - Notification Settings

struct NotificationSettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Form {
            Section {
                Toggle("On Success", isOn: $appState.notifyOnSuccess)
                    .help("Show notification when sync completes successfully")
                Toggle("On Warning", isOn: $appState.notifyOnWarning)
                    .help("Show notification when sync completes with warnings")
                Toggle("On Error", isOn: $appState.notifyOnError)
                    .help("Show notification when sync fails with an error")
            } header: {
                Text("Sync Notifications")
            } footer: {
                Text("Choose when to receive desktop notifications after sync jobs complete.")
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Advanced Settings

struct AdvancedSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showResetConfirm = false
    @State private var showClearConfirm = false
    
    var body: some View {
        Form {
            Section {
                Button("Clear All Logs") {
                    showClearConfirm = true
                }
                .foregroundColor(.red)
                .confirmationDialog("Clear All Logs?", isPresented: $showClearConfirm, titleVisibility: .visible) {
                    Button("Clear All", role: .destructive) {
                        appState.logStore.clearAllResults()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will permanently delete all sync history for all jobs. This cannot be undone.")
                }
                
                Button("Reset All Settings") {
                    showResetConfirm = true
                }
                .foregroundColor(.red)
                .confirmationDialog("Reset All Settings?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                    Button("Reset", role: .destructive) {
                        resetSettings()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will reset all settings to defaults (rsync path, notifications, log retention, etc.).")
                }
            } header: {
                Text("Danger Zone")
            }
        }
        .formStyle(.grouped)
    }
    
    private func resetSettings() {
        appState.rsyncPath = "/usr/bin/rsync"
        appState.launchAtLogin = false
        appState.logRetentionDays = 30
        appState.notifyOnSuccess = true
        appState.notifyOnWarning = true
        appState.notifyOnError = true
        appState.bandwidthLimit = 0
    }
}

#Preview {
    AppSettingsView()
        .environmentObject(AppState())
}