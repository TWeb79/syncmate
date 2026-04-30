import SwiftUI

// Author = "Inventions4All - github:TWeb79"

/// Log tab showing real-time sync output
struct JobLogView: View {
    @ObservedObject var syncEngine: SyncEngine
    @State private var autoScroll = true
    @State private var searchText = ""
    
    var filteredLogs: [String] {
        if searchText.isEmpty {
            return syncEngine.logLines
        }
        return syncEngine.logLines.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                TextField("Search logs...", text: $searchText)
                    .textFieldStyle(.plain)
                
                Toggle("Auto-scroll", isOn: $autoScroll)
                    .toggleStyle(.switch)
                
                Button(action: exportLogs) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                
                Button(action: { syncEngine.logLines.removeAll() }) {
                    Label("Clear", systemImage: "trash")
                }
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
            
            // Log content
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(filteredLogs.enumerated()), id: \.offset) { index, line in
                            LogLineView(line: line)
                                .id(index)
                        }
                    }
                    .padding(8)
                }
                .background(Color(nsColor: .textBackgroundColor))
                .onChange(of: syncEngine.logLines.count) { _, _ in
                    if autoScroll, let lastIndex = syncEngine.logLines.indices.last {
                        withAnimation {
                            proxy.scrollTo(lastIndex, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Status bar
            HStack {
                Text("\(syncEngine.logLines.count) lines")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if syncEngine.isRunning {
                    HStack(spacing: 4) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Running...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
        }
    }
    
    private func exportLogs() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "sync_log.txt"
        
        if panel.runModal() == .OK, let url = panel.url {
            let content = syncEngine.logLines.joined(separator: "\n")
            try? content.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

/// Single log line with syntax highlighting
struct LogLineView: View {
    let line: String
    
    var body: some View {
        Text(line)
            .font(.system(.caption, design: .monospaced))
            .foregroundColor(lineColor)
            .textSelection(.enabled)
    }
    
    private var lineColor: Color {
        if line.contains("error") || line.contains("Error") || line.contains("ERROR") {
            return .red
        } else if line.contains("warning") || line.contains("Warning") || line.contains("WARNING") {
            return .orange
        } else if line.contains("sent ") || line.contains("Total sent") {
            return .green
        } else if line.hasPrefix(" ") || line.hasPrefix("\t") {
            return .secondary
        }
        return .primary
    }
}

#Preview {
    JobLogView(syncEngine: SyncEngine())
}