import SwiftUI

/// Settings tab for configuring sync job options
struct JobSettingsView: View {
    @ObservedObject var appState: AppState
    @Binding var job: SyncJob
    @State private var showingSourcePicker = false
    @State private var showingDestPicker = false
    
    var body: some View {
        Form {
            // Folders section
            Section {
                HStack {
                    Text("Source")
                    Spacer()
                    Text(job.sourcePath.isEmpty ? "Select folder..." : job.sourcePath)
                        .foregroundColor(job.sourcePath.isEmpty ? .secondary : .primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Button("Browse...") {
                        showingSourcePicker = true
                    }
                }
                
                HStack {
                    Text("Destination")
                    Spacer()
                    Text(job.destinationPath.isEmpty ? "Select folder..." : job.destinationPath)
                        .foregroundColor(job.destinationPath.isEmpty ? .secondary : .primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Button("Browse...") {
                        showingDestPicker = true
                    }
                }
            } header: {
                Text("Folders")
            }
            
            // Sync mode section
            Section {
                Picker("Mode", selection: $job.syncMode) {
                    ForEach(SyncMode.allCases, id: \.self) { mode in
                        HStack {
                            Image(systemName: mode.icon)
                            Text(mode.displayName)
                        }
                        .tag(mode)
                    }
                }
                
                Text(job.syncMode.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Sync Mode")
            }
            
            // File filters section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Include Patterns")
                        .font(.subheadline)
                    TextEditor(text: $job.includePatterns)
                        .frame(height: 60)
                        .font(.system(.body, design: .monospaced))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.3))
                        )
                    Text("One pattern per line (e.g., *.txt, documents/*)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Exclude Patterns")
                        .font(.subheadline)
                    TextEditor(text: $job.excludePatterns)
                        .frame(height: 60)
                        .font(.system(.body, design: .monospaced))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.3))
                        )
                    Text("One pattern per line (e.g., *.tmp, .DS_Store)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("File Filters")
            }
            
            // Options section
            Section {
                Toggle("Preserve Permissions", isOn: $job.preservePermissions)
                Toggle("Follow Symlinks", isOn: $job.followSymlinks)
                Toggle("Skip Hidden Files", isOn: $job.skipHiddenFiles)
            } header: {
                Text("Options")
            }
        }
        .formStyle(.grouped)
        .padding()
        .onChange(of: job.sourcePath) { _, _ in saveChanges() }
        .onChange(of: job.destinationPath) { _, _ in saveChanges() }
        .onChange(of: job.syncMode) { _, _ in saveChanges() }
        .onChange(of: job.includePatterns) { _, _ in saveChanges() }
        .onChange(of: job.excludePatterns) { _, _ in saveChanges() }
        .onChange(of: job.preservePermissions) { _, _ in saveChanges() }
        .onChange(of: job.followSymlinks) { _, _ in saveChanges() }
        .onChange(of: job.skipHiddenFiles) { _, _ in saveChanges() }
        .fileImporter(isPresented: $showingSourcePicker, allowedContentTypes: [.folder]) { result in
            if case .success(let url) = result {
                job.sourcePath = url.path
                saveChanges()
            }
        }
        .fileImporter(isPresented: $showingDestPicker, allowedContentTypes: [.folder]) { result in
            if case .success(let url) = result {
                job.destinationPath = url.path
                saveChanges()
            }
        }
    }
    
    private func saveChanges() {
        appState.saveJobs()
    }
}

#Preview {
    JobSettingsView(appState: AppState(), job: .constant(SyncJob(name: "Test")))
}