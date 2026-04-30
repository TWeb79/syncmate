import Foundation

// Author = "Inventions4All - github:TWeb79"

/// Service responsible for storing and retrieving sync run history
class LogStore: ObservableObject {
    /// Shared instance
    static let shared = LogStore()
    
    /// All run results
    @Published var runResults: [SyncRunResult] = []
    
    /// UserDefaults key for storing results
    private let storageKey = "SyncMate.RunResults"
    
    /// Maximum number of results to keep per job
    private let maxResultsPerJob = 30
    
    private init() {
        loadResults()
    }
    
    /// Load results from storage
    func loadResults() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let results = try? JSONDecoder().decode([SyncRunResult].self, from: data) {
            runResults = results
        }
    }
    
    /// Save results to storage
    func saveResults() {
        if let data = try? JSONEncoder().encode(runResults) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    /// Add a new run result
    func addResult(_ result: SyncRunResult) {
        runResults.insert(result, at: 0)
        
        // Keep only the last maxResultsPerJob for each job
        let groupedResults = Dictionary(grouping: runResults) { $0.jobId }
        var trimmedResults: [SyncRunResult] = []
        
        for (_, results) in groupedResults {
            let sorted = results.sorted { $0.startTime > $1.startTime }
            let trimmed = Array(sorted.prefix(maxResultsPerJob))
            trimmedResults.append(contentsOf: trimmed)
        }
        
        runResults = trimmedResults.sorted { $0.startTime > $1.startTime }
        saveResults()
    }
    
    /// Get results for a specific job
    func results(for jobId: UUID) -> [SyncRunResult] {
        return runResults.filter { $0.jobId == jobId }
    }
    
    /// Get the last result for a job
    func lastResult(for jobId: UUID) -> SyncRunResult? {
        return results(for: jobId).first
    }
    
    /// Filter results by job name
    func filterResults(jobName: String? = nil, status: SyncStatus? = nil, startDate: Date? = nil, endDate: Date? = nil) -> [SyncRunResult] {
        var filtered = runResults
        
        if let jobName = jobName, !jobName.isEmpty {
            filtered = filtered.filter { $0.jobName.localizedCaseInsensitiveContains(jobName) }
        }
        
        if let status = status {
            filtered = filtered.filter { $0.status == status }
        }
        
        if let startDate = startDate {
            filtered = filtered.filter { $0.startTime >= startDate }
        }
        
        if let endDate = endDate {
            filtered = filtered.filter { $0.startTime <= endDate }
        }
        
        return filtered
    }
    
    /// Export results to CSV format
    func exportToCSV(results: [SyncRunResult]) -> String {
        var csv = "Job Name,Start Time,End Time,Duration (seconds),Status,Files Transferred,Files Skipped,Total Size (bytes),Error Message\n"
        
        let dateFormatter = ISO8601DateFormatter()
        
        for result in results {
            let startTime = dateFormatter.string(from: result.startTime)
            let endTime = result.endTime.map { dateFormatter.string(from: $0) } ?? ""
            let duration = result.endTime.map { $0.timeIntervalSince(result.startTime) } ?? 0
            let status = result.status.rawValue
            let errorMessage = result.errorMessage?.replacingOccurrences(of: ",", with: ";") ?? ""
            
            csv += "\"\(result.jobName)\",\(startTime),\(endTime),\(duration),\(status),\(result.filesTransferred),\(result.filesSkipped),\(result.totalSize),\"\(errorMessage)\"\n"
        }
        
        return csv
    }
    
    /// Export results to plain text format
    func exportToText(results: [SyncRunResult]) -> String {
        var text = "SyncMate Run History\n"
        text += "==================\n\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        for result in results {
            text += "Job: \(result.jobName)\n"
            text += "Start: \(dateFormatter.string(from: result.startTime))\n"
            if let endTime = result.endTime {
                text += "End: \(dateFormatter.string(from: endTime))\n"
                let duration = endTime.timeIntervalSince(result.startTime)
                text += "Duration: \(Int(duration)) seconds\n"
            }
            text += "Status: \(result.status.rawValue)\n"
            text += "Files Transferred: \(result.filesTransferred)\n"
            text += "Files Skipped: \(result.filesSkipped)\n"
            text += "Total Size: \(result.totalSize) bytes\n"
            if let error = result.errorMessage {
                text += "Error: \(error)\n"
            }
            text += "\n---\n\n"
        }
        
        return text
    }
    
    /// Clean up old results based on retention days
    func cleanupOldResults(retentionDays: Int) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) ?? Date()
        runResults = runResults.filter { $0.startTime >= cutoffDate }
        saveResults()
    }
    
    /// Clear all results
    func clearAllResults() {
        runResults = []
        saveResults()
    }
    
    /// Clear results for a specific job
    func clearResults(for jobId: UUID) {
        runResults = runResults.filter { $0.jobId != jobId }
        saveResults()
    }
}