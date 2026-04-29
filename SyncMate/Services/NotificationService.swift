import Foundation
import UserNotifications

/// Service responsible for sending notifications
class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    /// Shared instance
    static let shared = NotificationService()
    
    /// Whether notifications are authorized
    @Published var isAuthorized: Bool = false
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorization()
    }
    
    /// Request notification authorization
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            return false
        }
    }
    
    /// Check current authorization status
    func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    /// Send a sync completed notification
    func sendSyncCompletedNotification(jobName: String, status: SyncStatus, filesTransferred: Int, duration: String) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        
        switch status {
        case .success:
            content.title = "Sync Completed"
            content.body = "\(jobName): \(filesTransferred) files synced in \(duration)"
            content.sound = .default
        case .warning:
            content.title = "Sync Completed with Warnings"
            content.body = "\(jobName): \(filesTransferred) files synced in \(duration)"
            content.sound = .default
        case .error:
            content.title = "Sync Failed"
            content.body = "\(jobName) failed to complete"
            content.sound = .default
        case .running, .idle:
            return
        }
        
        content.categoryIdentifier = "SYNC_COMPLETE"
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Send a sync started notification
    func sendSyncStartedNotification(jobName: String) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Sync Started"
        content.body = "\(jobName) is now syncing..."
        content.sound = nil
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        // Handle notification tap
    }
}