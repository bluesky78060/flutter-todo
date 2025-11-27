import WidgetKit
import SwiftUI

struct TodoCalendarEntry: TimelineEntry {
    let date: Date
    var calendarDays: [CalendarDay] = []
    var isEnabled: Bool = true
}

struct CalendarDay: Identifiable {
    let id: Int
    let day: Int
    let hasTask: Bool
    let isCompleted: Bool
    let isCurrentDay: Bool
}

struct TodoCalendarWidgetEntryView: View {
    var entry: TodoCalendarEntry

    var body: some View {
        VStack(spacing: 8) {
            // Header with month/year
            HStack {
                VStack(alignment: .leading) {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "MMMM yyyy"
                    Text(dateFormatter.string(from: entry.date))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                }

                Spacer()
            }

            Divider()

            // Calendar grid
            VStack(spacing: 6) {
                // Day of week headers
                HStack(spacing: 4) {
                    ForEach(["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"], id: \.self) { day in
                        Text(day)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }

                // Calendar days (showing 4 weeks)
                ForEach(0..<4, id: \.self) { week in
                    HStack(spacing: 4) {
                        ForEach(0..<7, id: \.self) { day in
                            let index = week * 7 + day
                            let calendarDay = index < entry.calendarDays.count ? entry.calendarDays[index] : nil

                            if let calendarDay = calendarDay, calendarDay.day > 0 {
                                VStack(spacing: 0) {
                                    Text("\(calendarDay.day)")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(
                                            calendarDay.isCurrentDay ? .white : .primary
                                        )

                                    if calendarDay.hasTask {
                                        Circle()
                                            .fill(
                                                calendarDay.isCompleted ? Color.green : Color.orange
                                            )
                                            .frame(width: 4, height: 4)
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(
                                    calendarDay.isCurrentDay ? Color.purple : Color.clear
                                )
                                .cornerRadius(4)
                            } else {
                                Color.clear
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        }
                    }
                }
            }

            Spacer()

            // Legend
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Circle().fill(Color.orange).frame(width: 4, height: 4)
                    Text("Pending").font(.system(size: 9))
                }

                HStack(spacing: 4) {
                    Circle().fill(Color.green).frame(width: 4, height: 4)
                    Text("Done").font(.system(size: 9))
                }

                Spacer()
            }
            .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color(UIColor.systemBackground))
    }
}

struct TodoCalendarWidget: Widget {
    let kind: String = "TodoCalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TodoCalendarWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Calendar")
        .description("Shows this month's tasks")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TodoCalendarEntry {
        generateCalendarDays(for: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (TodoCalendarEntry) -> Void) {
        let entry = generateCalendarDays(for: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        var entries: [TodoCalendarEntry] = []

        // Create entries for daily updates
        let currentDate = Date()
        for i in 0..<7 {
            let entryDate = Calendar.current.date(byAdding: .day, value: i, to: currentDate)!
            let entry = generateCalendarDays(for: entryDate)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    private func generateCalendarDays(for date: Date) -> TodoCalendarEntry {
        let calendar = Calendar.current
        let today = calendar.dateComponents([.year, .month, .day], from: Date())
        let dateComponents = calendar.dateComponents([.year, .month], from: date)

        // Get first day of month
        let firstDayOfMonth = calendar.date(from: DateComponents(
            year: dateComponents.year,
            month: dateComponents.month,
            day: 1
        ))!

        let firstDayWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: date)?.count ?? 31

        var calendarDays: [CalendarDay] = []

        // Add empty days for days before month starts (Monday = 1, Sunday = 7)
        let startDayOffset = (firstDayWeekday + 5) % 7 // Convert to Monday-based
        for _ in 0..<startDayOffset {
            calendarDays.append(CalendarDay(
                id: calendarDays.count,
                day: 0,
                hasTask: false,
                isCompleted: false,
                isCurrentDay: false
            ))
        }

        // Add days of month
        for day in 1...daysInMonth {
            let isCurrentDay = today.year == dateComponents.year &&
                today.month == dateComponents.month &&
                today.day == day

            // Random demo: some days have tasks
            let hasTask = Int.random(in: 0...3) == 0
            let isCompleted = Int.random(in: 0...1) == 0

            calendarDays.append(CalendarDay(
                id: calendarDays.count,
                day: day,
                hasTask: hasTask,
                isCompleted: isCompleted,
                isCurrentDay: isCurrentDay
            ))
        }

        return TodoCalendarEntry(
            date: date,
            calendarDays: calendarDays,
            isEnabled: true
        )
    }
}

#Preview(as: .systemSmall) {
    TodoCalendarWidget()
} timeline: {
    TodoCalendarEntry(
        date: Date(),
        calendarDays: [],
        isEnabled: true
    )
}
