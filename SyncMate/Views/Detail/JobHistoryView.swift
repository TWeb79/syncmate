import SwiftUI

/// History tab showing past sync run results
struct JobHistoryView: View {
    let job: SyncJob
    @EnvironmentObject var appState: AppState
    @State private var filterStatus: SyncStatus? = nil
    @State private var searchText = ""
    
    var filteredHistory: [SyncRunResult] {
        appState.logStore.results(for: job.id).filter { result in
            let matchesStatus = filterStatus == nil || result.status == filterStatus
            let matchesSearch = searchText.isEmpty ||
                result.startTimeString.localizedCaseInsensitiveContains(searchText)
            return matchesStatus && matchesSearch
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter bar
            HStack {
                TextField("Search history...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Picker("Status", selection: $filterStatus) {
                    Text("All").tag(nil as SyncStatus?)
                    Text("Success").tag(SyncStatus.success as SyncStatus?)
                    Text("Warning").tag(SyncStatus.warning as SyncStatus?)
                    Text("Error").tag(SyncStatus.error as SyncStatus?)
                }
                .frame(width: 120)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            
            if filteredHistory.isEmpty {
                emptyState
            } else {
                historyList
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No History")
                .font(.title3)
                .fontWeight(.medium)
            Text("Run the sync job to see history here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var historyList: some View {
        List {
            ForEach(filteredHistory) { result in
                HistoryRowView(result: result)
            }
        }
        .listStyle(.plain)
    }
}

/// Row view for a single history entry
struct HistoryRowView: View {
    let result: SyncRunResult
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                VStack(alignment: .leading) {
                    Text(result.startTimeString)
                        .fontWeight(.medium)
                    Text("\(result.filesTransferred) files • \(result.durationString)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
                .buttonStyle(.borderless)
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    detailRow("Files Transferred", "\(result.filesTransferred)")
                    detailRow("Files Skipped", "\(result.filesSkipped)")
                    detailRow("Total Size", ByteCountFormatter.string(fromByteCount: result.totalSize, countStyle: .file))
                    detailRow("Duration", result.durationString)
                    detailRow("Status", result.status.rawValue)
                    if let error = result.errorMessage, !error.isEmpty {
                        Text("Error: \(error)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.leading, 32)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
        }
    }
    
    private var statusIcon: String {
        switch result.status {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .running: return "arrow.triangle.2.circlepath"
        case .idle: return "circle"
        }
    }
    
    private var statusColor: Color {
        switch result.status {
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        case .running: return .blue
        case .idle: return .gray
        }
    }
}

#Preview {
    JobHistoryView(job: SyncJob(name: "Test"))
        .environmentObject(AppState())
}
