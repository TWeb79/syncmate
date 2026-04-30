import SwiftUI

// Author = "Inventions4All - github:TWeb79"

/// A view that displays a status badge with a colored dot
struct StatusBadgeView: View {
    let status: SyncStatus
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch status {
        case .success:
            return .green
        case .warning:
            return .orange
        case .error:
            return .red
        case .running:
            return .blue
        case .idle:
            return .gray
        }
    }
    
    private var statusText: String {
        switch status {
        case .success:
            return "Success"
        case .warning:
            return "Warning"
        case .error:
            return "Error"
        case .running:
            return "Running"
        case .idle:
            return "Idle"
        }
    }
}

/// A view that displays a job status indicator
struct JobStatusIndicator: View {
    let status: SyncStatus
    let isAnimating: Bool
    
    var body: some View {
        ZStack {
            if status == .running && isAnimating {
                ProgressView()
                    .scaleEffect(0.7)
            } else {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
            }
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .success:
            return .green
        case .warning:
            return .orange
        case .error:
            return .red
        case .running:
            return .blue
        case .idle:
            return .gray
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StatusBadgeView(status: .success)
        StatusBadgeView(status: .warning)
        StatusBadgeView(status: .error)
        StatusBadgeView(status: .running)
        StatusBadgeView(status: .idle)
    }
    .padding()
}