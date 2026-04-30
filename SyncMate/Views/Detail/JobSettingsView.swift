import SwiftUI

// Author = "Inventions4All - github:TWeb79"

/// Settings tab for configuring sync job options
struct JobSettingsView: View {
    @ObservedObject var appState: AppState
    @Binding var job: SyncJob
    @State private var showingSourcePicker = false
    @State private var showingDestPicker = false
    
    var body: some View {
        Form {
            foldersSection
            syncModeSection
            fileFiltersSection
            optionsSection
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
    
    private var foldersSection: some View {
        Section {
            sourceFolderRow
            destinationFolderRow
        } header: {
            Text("Folders")
        }
    }
    
    private var sourceFolderRow: some View {
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
    }
    
    private var destinationFolderRow: some View {
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
    }
    
    private var syncModeSection: some View {
        Section {
            Picker("Mode", selection: $job.syncMode) {
                ForEach(SyncMode.allCases) { mode in
                    Text(mode.rawValue)
                        .tag(mode)
                }
            }
            
            Text(job.syncMode.description)
                .font(.caption)
                .foregroundColor(.secondary)
        } header: {
            Text("Sync Mode")
        }
    }
    
    private var fileFiltersSection: some View {
        Section {
            includePatternsView
            excludePatternsView
        } header: {
            Text("File Filters")
        }
    }
    
    private var includePatternsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Include Patterns")
                .font(.subheadline)
            TextEditor(text: includePatternsBinding)
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
    }
    
    private var excludePatternsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Exclude Patterns")
                .font(.subheadline)
            TextEditor(text: excludePatternsBinding)
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
    }
    
    private var includePatternsBinding: Binding<String> {
        Binding(
            get: { job.includePatterns.joined(separator: "\n") },
            set: { job.includePatterns = $0.split(separator: "\n").map(String.init) }
        )
    }
    
    private var excludePatternsBinding: Binding<String> {
        Binding(
            get: { job.excludePatterns.joined(separator: "\n") },
            set: { job.excludePatterns = $0.split(separator: "\n").map(String.init) }
        )
    }
    
    private var optionsSection: some View {
        Section {
            Toggle("Preserve Permissions", isOn: $job.preservePermissions)
            Toggle("Follow Symlinks", isOn: $job.followSymlinks)
            Toggle("Skip Hidden Files", isOn: $job.skipHiddenFiles)
        } header: {
            Text("Options")
        }
    }
    
    private func saveChanges() {
        appState.saveJobs()
    }
}

#Preview {
    JobSettingsView(appState: AppState(), job: .constant(SyncJob(name: "Test")))
}