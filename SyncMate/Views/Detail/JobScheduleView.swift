import SwiftUI

// Author = "Inventions4All - github:TWeb79"

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
                .help("Add a new schedule for this sync job")
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
                ScheduleRowView(schedule: $schedule, job: $job, appState: appState)
            }
        }
    }
}

/// Row view for a single schedule
struct ScheduleRowView: View {
    @Binding var schedule: SyncSchedule
    @Binding var job: SyncJob
    @ObservedObject var appState: AppState
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Toggle("", isOn: $schedule.isEnabled)
                        .labelsHidden()
                        .help("Enable or disable this schedule")
                    Text(schedule.scheduleType.rawValue)
                        .fontWeight(.medium)
                }
                Text(schedule.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if schedule.isEnabled, let nextRun = schedule.nextRunTime() {
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
            .help("Delete this schedule")
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .onChange(of: schedule.isEnabled) { _, isEnabled in
            if isEnabled {
                Task {
                    try? await SchedulerService.shared.enableSchedule(for: job, schedule: schedule)
                }
            } else {
                try? SchedulerService.shared.disableSchedule(for: job, schedule: schedule)
            }
            appState.saveJobs()
        }
        .alert("Delete Schedule?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                try? SchedulerService.shared.disableSchedule(for: job, schedule: schedule)
                if let index = job.schedules.firstIndex(where: { $0.id == schedule.id }) {
                    job.schedules.remove(at: index)
                }
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
    @State private var selectedWeekdays: Set<Weekday> = []
    
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
            .help("Select the schedule type")
                
                switch scheduleType {
                case .interval:
                    Stepper("Every \(intervalMinutes) minutes", value: $intervalMinutes, in: 1...1440)
                        .help("Set the sync interval in minutes")
                case .daily:
                    DatePicker("Time", selection: $dailyTime, displayedComponents: .hourAndMinute)
                        .help("Select the daily sync time")
                case .weekly:
                    WeekdayPicker(selectedDays: $selectedWeekdays)
                case .manual:
                    Text("Manual schedules cannot be created here")
                        .foregroundColor(.secondary)
                }
            }
            .formStyle(.grouped)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .help("Cancel without adding schedule")
                Spacer()
                Button("Add") {
                    addSchedule()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .help("Add this schedule to the job")
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
            schedule = SyncSchedule(
                isEnabled: true,
                scheduleType: .interval,
                intervalMinutes: intervalMinutes
            )
        case .daily:
            schedule = SyncSchedule(
                isEnabled: true,
                scheduleType: .daily,
                timeOfDay: dailyTime
            )
        case .weekly:
            schedule = SyncSchedule(
                isEnabled: true,
                scheduleType: .weekly,
                timeOfDay: dailyTime,
                weekdays: Array(selectedWeekdays)
            )
        case .manual:
            return
        }
        job.schedules.append(schedule)
        if schedule.isEnabled {
            Task {
                try? await SchedulerService.shared.enableSchedule(for: job, schedule: schedule)
            }
        }
        appState.saveJobs()
    }
}

/// Weekday picker component
struct WeekdayPicker: View {
    @Binding var selectedDays: Set<Weekday>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Days")
                .font(.subheadline)
            HStack {
                ForEach(Weekday.allCases) { day in
                    Button(action: { toggleDay(day) }) {
                        Text(day.shortName)
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
    
    private func toggleDay(_ day: Weekday) {
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