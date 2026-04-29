import SwiftUI

/// Schedule tab for configuring sync job schedules
struct JobScheduleView: View {
    @ObservedObject var appState: AppState
    @Binding var job: SyncJob
    @State private var showingAddSchedule = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Schedules")
                    .font(.headline)
                Spacer()
                Button(action: { showingAddSchedule = true }) {
                    Label("Add Schedule", systemImage: "plus")
                }
            }
            
            if job.schedules.isEmpty {
                emptyState
            } else {
                scheduleList
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingAddSchedule) {
            AddScheduleView(job: $job, appState: appState)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No Schedules")
                .font(.title3)
                .fontWeight(.medium)
            Text("Add a schedule to automatically run this sync job")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Add Schedule") {
                showingAddSchedule = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var scheduleList: some View {
        VStack(spacing: 12) {
            ForEach($job.schedules) { $schedule in
                ScheduleRowView(schedule: $schedule, job: job, appState: appState)
            }
        }
    }
}

/// Row view for a single schedule
struct ScheduleRowView: View {
    @Binding var schedule: SyncSchedule
    let job: SyncJob
    @ObservedObject var appState: AppState
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Toggle("", isOn: $schedule.isEnabled)
                        .labelsHidden()
                    Text(schedule.displayName)
                        .fontWeight(.medium)
                }
                Text(schedule.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if schedule.isEnabled, let nextRun = schedule.nextRunDate {
                    Text("Next: \(nextRun.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                }
            }
            Spacer()
            Button(action: { showingDeleteConfirmation = true }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .onChange(of: schedule.isEnabled) { _, isEnabled in
            if isEnabled {
                SchedulerService.shared.registerSchedule(schedule, for: job)
            } else {
                SchedulerService.shared.unregisterSchedule(schedule, for: job)
            }
            appState.saveJobs()
        }
        .alert("Delete Schedule?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                SchedulerService.shared.removeSchedule(schedule, for: job)
                job.schedules.removeAll { $0.id == schedule.id }
                appState.saveJobs()
            }
        } message: {
            Text("This schedule will be permanently removed.")
        }
    }
}

/// View for adding a new schedule
struct AddScheduleView: View {
    @Binding var job: SyncJob
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var scheduleType: ScheduleType = .daily
    @State private var intervalMinutes: Int = 60
    @State private var dailyTime = Date()
    @State private var selectedWeekdays: Set<Int> = []
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Schedule")
                .font(.headline)
            
            Form {
                Picker("Type", selection: $scheduleType) {
                    Text("Every N Minutes").tag(ScheduleType.interval)
                    Text("Daily").tag(ScheduleType.daily)
                    Text("Weekly").tag(ScheduleType.weekly)
                }
                
                switch scheduleType {
                case .interval:
                    Stepper("Every \(intervalMinutes) minutes", value: $intervalMinutes, in: 1...1440)
                case .daily:
                    DatePicker("Time", selection: $dailyTime, displayedComponents: .hourAndMinute)
                case .weekly:
                    WeekdayPicker(selectedDays: $selectedWeekdays)
                }
            }
            .formStyle(.grouped)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                Spacer()
                Button("Add") {
                    addSchedule()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(scheduleType == .weekly && selectedWeekdays.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
    
    private func addSchedule() {
        let schedule: SyncSchedule
        switch scheduleType {
        case .interval:
            schedule = SyncSchedule(type: .interval, intervalMinutes: intervalMinutes)
        case .daily:
            let hour = Calendar.current.component(.hour, from: dailyTime)
            let minute = Calendar.current.component(.minute, from: dailyTime)
            schedule = SyncSchedule(type: .daily, hour: hour, minute: minute)
        case .weekly:
            schedule = SyncSchedule(type: .weekly, weekdays: Array(selectedWeekdays))
        }
        job.schedules.append(schedule)
        if schedule.isEnabled {
            SchedulerService.shared.registerSchedule(schedule, for: job)
        }
        appState.saveJobs()
    }
}

/// Weekday picker component
struct WeekdayPicker: View {
    @Binding var selectedDays: Set<Int>
    
    private let weekdays = [
        (1, "Sun"), (2, "Mon"), (3, "Tue"), (4, "Wed"),
        (5, "Thu"), (6, "Fri"), (7, "Sat")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Days")
                .font(.subheadline)
            HStack {
                ForEach(weekdays, id: \.0) { day, name in
                    Button(action: { toggleDay(day) }) {
                        Text(name)
                            .font(.caption)
                            .frame(width: 36, height: 36)
                            .background(selectedDays.contains(day) ? Color.accentColor : Color.clear)
                            .foregroundColor(selectedDays.contains(day) ? .white : .primary)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
    }
    
    private func toggleDay(_ day: Int) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
}

#Preview {
    JobScheduleView(appState: AppState(), job: .constant(SyncJob(name: "Test")))
}