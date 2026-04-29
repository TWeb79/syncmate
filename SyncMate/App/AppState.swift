import SwiftUI
import Combine

/// Global application state managing sync jobs and engine
class AppState: ObservableObject {
    @Published var jobs: [SyncJob] = []
    @Published var selectedJob: SyncJob?
    @Published var isRunning = false
    
    let schedulerService = SchedulerService.shared
    let notificationService = NotificationService.shared
    let logStore = LogStore.shared
    
    var syncEngine: SyncEngine!
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadJobs()
        syncEngine = DispatchQueue.main.sync {
            SyncEngine()
        }
        setupBindings()
    }
    
    private func setupBindings() {
        // Listen for sync completion
        syncEngine.$isRunning
            .receive(on: DispatchQueue.main)
            .sink { [weak self] running in
                self?.isRunning = running
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Job Management
    
    func addJob() {
        let newJob = SyncJob(name: "New Sync Job")
        jobs.append(newJob)
        selectedJob = newJob
        saveJobs()
    }
    
    func deleteJob(_ job: SyncJob) {
        schedulerService.removeSchedules(for: job.id)
        jobs.removeAll { $0.id == job.id }
        if selectedJob?.id == job.id {
            selectedJob = jobs.first
        }
        saveJobs()
    }
    
    func runJob(_ job: SyncJob) {
        guard !isRunning else { return }
        
        Task { @MainActor in
            let result = await syncEngine.runSync(job: job)
            
            // Update job history
            if let index = jobs.firstIndex(where: { $0.id == job.id }) {
                jobs[index].addRunResult(result)
                if selectedJob?.id == job.id {
                    selectedJob = jobs[index]
                }
            }
            
            saveJobs()
            
            // Send notification
            await notificationService.sendSyncNotification(for: job, result: result)
        }
    }
    
    // MARK: - Persistence
    
    private func loadJobs() {
        if let data = UserDefaults.standard.data(forKey: "syncJobs"),
           let decoded = try? JSONDecoder().decode([SyncJob].self, from: data) {
            jobs = decoded
            selectedJob = jobs.first
        }
    }
    
    func saveJobs() {
        if let encoded = try? JSONEncoder().encode(jobs) {
            UserDefaults.standard.set(encoded, forKey: "syncJobs")
        }
    }
    
    // MARK: - Settings
    
    var rsyncPath: String {
        get { UserDefaults.standard.string(forKey: "rsyncPath") ?? "/usr/bin/rsync" }
        set { UserDefaults.standard.set(newValue, forKey: "rsyncPath") }
    }
    
    var launchAtLogin: Bool {
        get { UserDefaults.standard.bool(forKey: "launchAtLogin") }
        set { UserDefaults.standard.set(newValue, forKey: "launchAtLogin") }
    }
    
    var logRetentionDays: Int {
        get { UserDefaults.standard.integer(forKey: "logRetentionDays").nonZeroOr(30) }
        set { UserDefaults.standard.set(newValue, forKey: "logRetentionDays") }
    }
    
    var notifyOnSuccess: Bool {
        get { UserDefaults.standard.object(forKey: "notifyOnSuccess") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "notifyOnSuccess") }
    }
    
    var notifyOnWarning: Bool {
        get { UserDefaults.standard.object(forKey: "notifyOnWarning") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "notifyOnWarning") }
    }
    
    var notifyOnError: Bool {
        get { UserDefaults.standard.object(forKey: "notifyOnError") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "notifyOnError") }
    }
    
    var bandwidthLimit: Int {
        get { UserDefaults.standard.integer(forKey: "bandwidthLimit") }
        set { UserDefaults.standard.set(newValue, forKey: "bandwidthLimit") }
    }
}

// MARK: - Int Extension

private extension Int {
    func nonZeroOr(_ defaultValue: Int) -> Int {
        self == 0 ? defaultValue : self
    }
}
