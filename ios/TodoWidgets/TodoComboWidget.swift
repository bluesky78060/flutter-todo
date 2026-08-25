import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
struct ComboEntry: TimelineEntry {
    let date: Date
    let todos: [TodoItem]
    let currentMonth: Date
}

// MARK: - Timeline Provider
struct ComboProvider: TimelineProvider {
    func placeholder(in context: Context) -> ComboEntry {
        ComboEntry(
            date: Date(),
            todos: [
                TodoItem(id: "1", title: "회의 참석", description: nil, dueDate: Date(), reminderTime: nil, isCompleted: false, categoryId: nil, categoryName: nil, categoryColor: nil),
                TodoItem(id: "2", title: "보고서 작성", description: nil, dueDate: Date(), reminderTime: nil, isCompleted: false, categoryId: nil, categoryName: nil, categoryColor: nil)
            ],
            currentMonth: Date()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ComboEntry) -> Void) {
        let todos = SharedDataManager.shared.getTodayTodos()
        let entry = ComboEntry(
            date: Date(),
            todos: Array(todos.prefix(3)),
            currentMonth: Date()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ComboEntry>) -> Void) {
        let todos = SharedDataManager.shared.getTodayTodos()
        let entry = ComboEntry(
            date: Date(),
            todos: Array(todos.prefix(3)),
            currentMonth: Date()
        )

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Combo Widget View
struct ComboWidgetView: View {
    var entry: ComboEntry
    @Environment(\.colorScheme) var colorScheme

    private let calendar = Calendar.current
    private let weekdays = ["일", "월", "화", "수", "목", "금", "토"]

    var body: some View {
        HStack(spacing: 12) {
            // Left: Today's todos
            leftSection

            // Right: Mini calendar
            rightSection
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Left Section (Today's Todos)
    private var leftSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Date header
            Text(formattedDate)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)

            // Todos or empty state
            if entry.todos.isEmpty {
                Text("더 이상 이벤트 없음")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(entry.todos.prefix(3), id: \.id) { todo in
                        todoRow(todo)
                    }
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Todo Row
    private func todoRow(_ todo: TodoItem) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: todo.categoryColor ?? "#7B61FF"))
                .frame(width: 8, height: 8)

            Text(todo.title)
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer()

            if let dueDate = todo.dueDate {
                Text(formatTime(dueDate))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Right Section (Mini Calendar)
    private var rightSection: some View {
        VStack(spacing: 2) {
            // Month header
            Text(monthString)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)

            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(dayHeaderColor(day))
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            let days = generateCalendarDays()
            ForEach(0..<6, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { col in
                        let index = row * 7 + col
                        if index < days.count {
                            dayCell(days[index], column: col)
                        }
                    }
                }
            }
        }
        .frame(width: 150)
    }

    // MARK: - Day Cell
    private func dayCell(_ day: MiniCalendarDay, column: Int) -> some View {
        ZStack {
            if day.isToday {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 18, height: 18)
            }

            Text(day.isCurrentMonth ? "\(day.day)" : "")
                .font(.system(size: 11, weight: day.isToday ? .bold : .regular))
                .foregroundColor(dayColor(day, column: column))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 18)
    }

    // MARK: - Helper Functions
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 (E)"
        return formatter.string(from: entry.date)
    }

    private var monthString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월"
        return formatter.string(from: entry.currentMonth)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func dayHeaderColor(_ day: String) -> Color {
        switch day {
        case "일": return .red
        case "토": return .blue
        default: return .secondary
        }
    }

    private func dayColor(_ day: MiniCalendarDay, column: Int) -> Color {
        if day.isToday {
            return .primary
        }
        if column == 0 { // Sunday
            return .red
        }
        if column == 6 { // Saturday
            return .blue
        }
        return .primary
    }

    private func generateCalendarDays() -> [MiniCalendarDay] {
        let year = calendar.component(.year, from: entry.currentMonth)
        let month = calendar.component(.month, from: entry.currentMonth)

        var days: [MiniCalendarDay] = []

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        guard let firstOfMonth = calendar.date(from: components) else { return days }

        guard let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else { return days }
        let daysInMonth = range.count

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)

        let today = Date()
        let todayDay = calendar.component(.day, from: today)
        let todayMonth = calendar.component(.month, from: today)
        let todayYear = calendar.component(.year, from: today)
        let isCurrentMonth = todayYear == year && todayMonth == month

        // Empty cells before first day
        for _ in 0..<(firstWeekday - 1) {
            days.append(MiniCalendarDay(day: 0, isCurrentMonth: false, isToday: false))
        }

        // Days of month
        for day in 1...daysInMonth {
            let isToday = isCurrentMonth && day == todayDay
            days.append(MiniCalendarDay(day: day, isCurrentMonth: true, isToday: isToday))
        }

        // Fill remaining cells
        while days.count < 42 {
            days.append(MiniCalendarDay(day: 0, isCurrentMonth: false, isToday: false))
        }

        return days
    }
}

// MARK: - Mini Calendar Day Model
struct MiniCalendarDay {
    let day: Int
    let isCurrentMonth: Bool
    let isToday: Bool
}

// MARK: - Widget Configuration
struct TodoComboWidget: Widget {
    let kind: String = "TodoComboWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ComboProvider()) { entry in
            if #available(iOS 17.0, *) {
                ComboWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                ComboWidgetView(entry: entry)
                    .padding()
                    .background(Color(.systemBackground))
            }
        }
        .configurationDisplayName("할 일 + 캘린더")
        .description("오늘 할 일과 미니 캘린더를 함께 확인")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Preview
struct TodoComboWidget_Previews: PreviewProvider {
    static var previews: some View {
        ComboWidgetView(entry: ComboEntry(
            date: Date(),
            todos: [
                TodoItem(id: "1", title: "회의 참석", description: nil, dueDate: Date(), reminderTime: nil, isCompleted: false, categoryId: nil, categoryName: nil, categoryColor: "#7B61FF"),
                TodoItem(id: "2", title: "보고서 작성", description: nil, dueDate: Date(), reminderTime: nil, isCompleted: false, categoryId: nil, categoryName: nil, categoryColor: "#42A5F5")
            ],
            currentMonth: Date()
        ))
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
