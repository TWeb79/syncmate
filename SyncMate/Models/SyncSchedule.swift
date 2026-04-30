import Foundation

// Author = "Inventions4All - github:TWeb79"

/// Represents a schedule for automated sync execution
struct SyncSchedule: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var isEnabled: Bool
    var scheduleType: ScheduleType
    var intervalMinutes: Int?
    var timeOfDay: Date?
    var weekdays: [Weekday]
    var triggerOnLogin: Bool
    var triggerOnWake: Bool
    
    init(
        id: UUID = UUID(),
        isEnabled: Bool = true,
        scheduleType: ScheduleType = .daily,
        intervalMinutes: Int? = nil,
        timeOfDay: Date? = nil,
        weekdays: [Weekday] = [],
        triggerOnLogin: Bool = false,
        triggerOnWake: Bool = false
    ) {
        self.id = id
        self.isEnabled = isEnabled
        self.scheduleType = scheduleType
        self.intervalMinutes = intervalMinutes
        self.timeOfDay = timeOfDay
        self.weekdays = weekdays
        self.triggerOnLogin = triggerOnLogin
        self.triggerOnWake = triggerOnWake
    }
    
    /// Returns a human-readable description of the schedule
    var description: String {
        switch scheduleType {
        case .interval:
            if let minutes = intervalMinutes {
                if minutes >= 60 {
                    return "Every \(minutes / 60) hour\(minutes / 60 > 1 ? "s" : "")"
                }
                return "Every \(minutes) minute\(minutes > 1 ? "s" : "")"
            }
            return "Every hour"
        case .daily:
            if let time = timeOfDay {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return "Daily at \(formatter.string(from: time))"
            }
            return "Daily"
        case .weekly:
            if weekdays.isEmpty {
                return "Weekly"
            }
            let dayNames = weekdays.map { $0.shortName }.joined(separator: ", ")
            if let time = timeOfDay {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return "\(dayNames) at \(formatter.string(from: time))"
            }
            return "Weekly on \(dayNames)"
        case .manual:
            return "Manual only"
        }
    }
    
    /// Calculates the next run time based on the schedule
    func nextRunTime(from date: Date = Date()) -> Date? {
        guard isEnabled else { return nil }
        
        let calendar = Calendar.current
        
        switch scheduleType {
        case .interval:
            guard let minutes = intervalMinutes, minutes > 0 else { return nil }
            return calendar.date(byAdding: .minute, value: minutes, to: date)
            
        case .daily:
            guard let time = timeOfDay else { return nil }
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
            dateComponents.hour = timeComponents.hour
            dateComponents.minute = timeComponents.minute
            
            if let scheduledTime = calendar.date(from: dateComponents) {
                if scheduledTime > date {
                    return scheduledTime
                }
                // Next day
                return calendar.date(byAdding: .day, value: 1, to: scheduledTime)
            }
            return nil
            
        case .weekly:
            guard !weekdays.isEmpty, let time = timeOfDay else { return nil }
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            let currentWeekday = calendar.component(.weekday, from: date)
            
            // Find next scheduled weekday
            for offset in 0..<8 {
                let checkDate = calendar.date(byAdding: .day, value: offset, to: date)!
                let checkWeekday = calendar.component(.weekday, from: checkDate)
                
                if weekdays.contains(where: { $0.calendarWeekday == checkWeekday }) {
                    var dateComponents = calendar.dateComponents([.year, .month, .day], from: checkDate)
                    dateComponents.hour = timeComponents.hour
                    dateComponents.minute = timeComponents.minute
                    
                    if let scheduledTime = calendar.date(from: dateComponents), scheduledTime > date {
                        return scheduledTime
                    }
                }
            }
            return nil
            
        case .manual:
            return nil
        }
    }
}

/// Type of schedule
enum ScheduleType: String, Codable, CaseIterable, Identifiable {
    case interval = "Interval"
    case daily = "Daily"
    case weekly = "Weekly"
    case manual = "Manual"
    
    var id: String { rawValue }
}

/// Days of the week
enum Weekday: String, Codable, CaseIterable, Identifiable {
    case sunday = "Sunday"
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    
    var id: String { rawValue }
    
    /// Short name for display
    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
    
    /// Calendar weekday number (1 = Sunday)
    var calendarWeekday: Int {
        switch self {
        case .sunday: return 1
        case .monday: return 2
        case .tuesday: return 3
        case .wednesday: return 4
        case .thursday: return 5
        case .friday: return 6
        case .saturday: return 7
        }
    }
}