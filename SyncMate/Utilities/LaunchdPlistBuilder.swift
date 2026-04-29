import Foundation

/// Builder for creating launchd plist files
struct LaunchdPlistBuilder {
    /// Build a launchd plist for a sync job schedule
    /// - Parameters:
    ///   - job: The sync job
    ///   - schedule: The schedule to create a plist for
    /// - Returns: The plist content as a string
    func buildPlist(for job: SyncJob, schedule: SyncSchedule) -> String {
        let label = "com.syncmate.\(job.id.uuidString).\(schedule.id.uuidString)"
        let appPath = Bundle.main.bundlePath
        let executablePath = Bundle.main.executablePath ?? "\(appPath)/Contents/MacOS/SyncMate"
        
        var plist: [String: Any] = [
            "Label": label,
            "ProgramArguments": [executablePath, "--run-job", job.id.uuidString],
            "RunAtLoad": schedule.runAtLogin,
            "Disabled": !schedule.isEnabled,
            "StandardOutPath": "/tmp/syncmate-\(job.id.uuidString).out.log",
            "StandardErrorPath": "/tmp/syncmate-\(job.id.uuidString).err.log"
        ]
        
        // Add schedule-based triggers
        switch schedule.scheduleType {
        case .interval:
            // Run every N minutes
            let intervalInSeconds = schedule.intervalMinutes * 60
            plist["StartInterval"] = intervalInSeconds
            
        case .daily:
            // Run at specific time
            var calendar = Calendar.current
            calendar.timeZone = TimeZone.current
            var components = calendar.dateComponents([.hour, .minute], from: schedule.specificTime)
            components.second = 0
            plist["StartCalendarInterval"] = components
            
        case .weekly:
            // Run on specific weekdays
            var calendar = Calendar.current
            calendar.timeZone = TimeZone.current
            var components = calendar.dateComponents([.hour, .minute], from: schedule.specificTime)
            components.second = 0
            components.weekday = schedule.weekdays.first?.rawValue ?? 1
            plist["StartCalendarInterval"] = components
            
        case .onLogin, .onWake:
            // These are handled by RunAtLoad and other mechanisms
            break
        }
        
        // Generate XML plist
        return generateXML(from: plist)
    }
    
    /// Generate XML plist from dictionary
    private func generateXML(from dictionary: [String: Any]) -> String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
        xml += "<plist version=\"1.0\">\n"
        xml += "<dict>\n"
        
        for (key, value) in dictionary.sorted(by: { $0.key < $1.key }) {
            xml += "\t<key>\(escapeXML(key))</key>\n"
            xml += "\t\(xmlValue(from: value, indent: 1))\n"
        }
        
        xml += "</dict>\n"
        xml += "</plist>\n"
        
        return xml
    }
    
    /// Convert a value to XML representation
    private func xmlValue(from value: Any, indent: Int) -> String {
        let indentString = String(repeating: "\t", count: indent)
        
        if let string = value as? String {
            return "<string>\(escapeXML(string))</string>"
        } else if let int = value as? Int {
            return "<integer>\(int)</integer>"
        } else if let bool = value as? Bool {
            return "<\(bool ? "true" : "false")/>"
        } else if let array = value as? [String] {
            var xml = "<array>\n"
            for item in array {
                xml += "\(indentString)\t<string>\(escapeXML(item))</string>\n"
            }
            xml += "\(indentString)</array>"
            return xml
        } else if let dict = value as? [String: Any] {
            var xml = "<dict>\n"
            for (key, val) in dict.sorted(by: { $0.key < $1.key }) {
                xml += "\(indentString)\t<key>\(escapeXML(key))</key>\n"
                xml += "\(indentString)\t\(xmlValue(from: val, indent: indent + 1))\n"
            }
            xml += "\(indentString)</dict>"
            return xml
        } else if let date = value as? Date {
            let formatter = ISO8601DateFormatter()
            return "<date>\(formatter.string(from: date))</date>"
        }
        
        return "<string></string>"
    }
    
    /// Escape special XML characters
    private func escapeXML(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&")
            .replacingOccurrences(of: "<", with: "<")
            .replacingOccurrences(of: ">", with: ">")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "'")
    }
    
    /// Parse a plist file
    /// - Parameter content: The plist content as a string
    /// - Returns: A dictionary representation of the plist
    static func parsePlist(_ content: String) -> [String: Any]? {
        guard let data = content.data(using: .utf8) else { return nil }
        
        do {
            return try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
        } catch {
            return nil
        }
    }
}