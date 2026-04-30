import SwiftUI
import Foundation

// Author = "Inventions4All - github:TWeb79"

/// Settings tab for configuring sync job options
struct JobSettingsView: View {
    @ObservedObject var appState: AppState
    @Binding var job: SyncJob
    @State private var showingSourcePicker = false
    @State private var showingDestPicker = false
    @State private var sourcePathWarning = false
    @State private var destPathWarning = false
    
    var body: some View {
        Form {
            foldersSection
            rsyncStatusSection
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
        .onChange(of: appState.rsyncPath) { _, _ in
            rsyncAvailable = FilePickerHelper.isRsyncAvailable(at: appState.rsyncPath)
        }
        .onAppear {
            // Validate paths on appear
            sourcePathWarning = !job.sourcePath.isEmpty && !FilePickerHelper.isValidDirectory(job.sourcePath)
            destPathWarning = !job.destinationPath.isEmpty && !FilePickerHelper.isValidDirectory(job.destinationPath)
            rsyncAvailable = FilePickerHelper.isRsyncAvailable(at: appState.rsyncPath)
        }
    }
    @State private var rsyncAvailable = true
    
    private var foldersSection: some View {
        Section {
            sourceFolderRow
            destinationFolderRow
        } header: {
            Text("Folders")
        }
    }
    
    private var sourceFolderRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Source")
                Spacer()
                Text(job.sourcePath.isEmpty ? "Select folder..." : job.sourcePath)
                    .foregroundColor(job.sourcePath.isEmpty ? .secondary : .primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Button("Browse...") {
                    if let url = FilePickerHelper.selectFolder(title: "Select Source Folder", mustExist: true) {
                        job.sourcePath = url.path
                        sourcePathWarning = !FilePickerHelper.isValidDirectory(job.sourcePath)
                        saveChanges()
                    }
                }
            }
            if sourcePathWarning && !job.sourcePath.isEmpty {
                Text("⚠ Path does not exist or is not a directory")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    private var destinationFolderRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Destination")
                Spacer()
                Text(job.destinationPath.isEmpty ? "Select folder..." : job.destinationPath)
                    .foregroundColor(job.destinationPath.isEmpty ? .secondary : .primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Button("Browse...") {
                    if let url = FilePickerHelper.selectFolder(title: "Select Destination Folder", mustExist: true) {
                        job.destinationPath = url.path
                        destPathWarning = !FilePickerHelper.isValidDirectory(job.destinationPath)
                        saveChanges()
                    }
                }
            }
            if destPathWarning && !job.destinationPath.isEmpty {
                Text("⚠ Path does not exist or is not a directory")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    private var rsyncStatusSection: some View {
        Section {
            HStack {
                Text("rsync Path")
                Spacer()
                Text(appState.rsyncPath)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Button(action: { windowOpenPanelForRsync() }) {
                    Image(systemName: "folder")
                }
                .buttonStyle(.borderless)
                .help("Change rsync binary path")
            }
            HStack {
                Image(systemName: rsyncAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(rsyncAvailable ? .green : .red)
                Text(rsyncAvailable ? "rsync available" : "rsync not found")
                    .font(.caption)
                    .foregroundColor(rsyncAvailable ? .green : .red)
            }
            if !rsyncAvailable {
                Text("Install rsync or update path in Settings")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        } header: {
            Text("Rsync Configuration")
        }
    }
    
    private func windowOpenPanelForRsync() {
        let panel = NSOpenPanel()
        panel.title = "Select rsync Binary"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.unixExecutable]
        
        if panel.runModal() == .OK, let url = panel.url {
            appState.rsyncPath = url.path
            rsyncAvailable = FilePickerHelper.isRsyncAvailable(at: url.path)
        }
    }
    
    private var syncModeSection: some View {
        Section {
            Picker("Mode", selection: $job.syncMode) {
                ForEach(SyncMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
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
            TextEditor(text: $job.includePatternsString)
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
            TextEditor(text: $job.excludePatternsString)
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
    
    private var optionsSection: some View {
        Section {
            Toggle("Preserve Permissions", isOn: $job.preservePermissions)
                .help("Preserve original file permissions during rsync")
            Toggle("Follow Symlinks", isOn: $job.followSymlinks)
                .help("Follow symbolic links instead of skipping them")
            Toggle("Skip Hidden Files", isOn: $job.skipHiddenFiles)
                .help("Exclude hidden files (starting with .) from sync")
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