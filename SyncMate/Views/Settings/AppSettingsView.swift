import SwiftUI

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
    
    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $appState.launchAtLogin)
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
            } header: {
                Text("History")
            }
        }
        .formStyle(.grouped)
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
                        showRsyncPicker = true
                    }
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
                Toggle("On Warning", isOn: $appState.notifyOnWarning)
                Toggle("On Error", isOn: $appState.notifyOnError)
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
    
    var body: some View {
        Form {
            Section {
                Button("Clear All Logs") {
                    appState.logStore.clearAllLogs()
                }
                .foregroundColor(.red)
                
                Button("Reset All Settings") {
                    resetSettings()
                }
                .foregroundColor(.red)
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