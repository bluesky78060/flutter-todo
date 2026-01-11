import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
struct CalendarEntry: TimelineEntry {
    let date: Date
    let displayMonth: Date
    let todosByDay: [Int: [TodoItem]]
    let holidays: [Int: String]
    let selectedDay: Int?
}

// MARK: - Timeline Provider
struct CalendarProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalendarEntry {
        CalendarEntry(
            date: Date(),
            displayMonth: Date(),
            todosByDay: [:],
            holidays: [:],
            selectedDay: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)

        let todosByDay = SharedDataManager.shared.getTodosForMonth(year: year, month: month)
        let holidays = SharedDataManager.shared.getHolidays(year: year, month: month)

        let entry = CalendarEntry(
            date: now,
            displayMonth: now,
            todosByDay: todosByDay,
            holidays: holidays,
            selectedDay: nil
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarEntry>) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)

        // Debug: Check if UserDefaults is accessible
        let defaults = UserDefaults(suiteName: "group.kr.bluesky.dodo")
        let allKeys = defaults?.dictionaryRepresentation().keys.count ?? -1
        print("📱 [CalendarWidget] UserDefaults keys count: \(allKeys)")

        // Check for specific Flutter widget data keys
        let viewType = defaults?.string(forKey: "view_type") ?? "nil"
        let calendarDay1 = defaults?.string(forKey: "calendar_day_1") ?? "nil"
        print("📱 [CalendarWidget] view_type: \(viewType), calendar_day_1: \(calendarDay1)")

        let todosByDay = SharedDataManager.shared.getTodosForMonth(year: year, month: month)
        let holidays = SharedDataManager.shared.getHolidays(year: year, month: month)

        print("📱 [CalendarWidget] todosByDay count: \(todosByDay.count)")

        let entry = CalendarEntry(
            date: now,
            displayMonth: now,
            todosByDay: todosByDay,
            holidays: holidays,
            selectedDay: nil
        )

        // Update more frequently for testing (every 5 minutes instead of 30)
        let nextUpdate = calendar.date(byAdding: .minute, value: 5, to: now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget View
struct CalendarWidgetView: View {
    var entry: CalendarEntry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme

    var backgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.8) : Color.white.opacity(0.9)
    }

    var cardBackgroundColor: Color {
        WidgetAppearance.calendarCardBackground(for: colorScheme)
    }

    var textPrimaryColor: Color {
        colorScheme == .dark ? .white : .black
    }

    var textSecondaryColor: Color {
        colorScheme == .dark ? Color(hex: "#888888") : Color(hex: "#666666")
    }

    var body: some View {
        VStack(spacing: 4) {
            // Header
            headerView

            // Calendar Grid
            calendarGridView

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 4)
        // Glass 효과: 배경 제거하여 containerBackground의 material이 보이도록 함
    }

    // MARK: - Header View
    private var headerView: some View {
        HStack {
            // Month/Year Title
            Text(monthYearString)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(textPrimaryColor)

            // Debug: Show todo count
            let totalTodos = entry.todosByDay.values.flatMap { $0 }.count
            Text("(\(totalTodos))")
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "#7B61FF"))

            Spacer()

            // Add Button
            ZStack {
                Circle()
                    .fill(Color(hex: "#7B61FF"))
                    .frame(width: 26, height: 26)

                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Calendar Grid View
    private var calendarGridView: some View {
        VStack(spacing: 2) {
            // Day names header
            dayNamesHeader

            // Calendar days grid
            let days = generateCalendarDays()
            ForEach(0..<6, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { col in
                        let index = row * 7 + col
                        if index < days.count {
                            dayCell(day: days[index], column: col)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Day Names Header
    private var dayNamesHeader: some View {
        HStack(spacing: 0) {
            ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                Text(day)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(dayNameColor(for: day))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Day Cell
    private func dayCell(day: CalendarDay, column: Int) -> some View {
        VStack(spacing: 0) {
            // Day number
            Text(day.isCurrentMonth ? "\(day.day)" : "")
                .font(.system(size: 11, weight: day.isToday ? .bold : .medium))
                .foregroundColor(dayColor(day: day, column: column))
                .frame(width: 20, height: 14)
                .background(
                    day.isToday ?
                    Circle()
                        .fill(Color(hex: "#7B61FF"))
                        .frame(width: 18, height: 18)
                    : nil
                )

            // Holiday name (날짜 바로 아래)
            if day.isCurrentMonth, let holiday = day.holidayName {
                Text(truncateTitle(holiday, maxLength: 3))
                    .font(.system(size: 6))
                    .foregroundColor(Color(hex: "#E53935"))
                    .lineLimit(1)
                    .frame(height: 9)
            } else {
                Spacer()
                    .frame(height: 9)
            }

            // Todo titles (휴일 아래)
            if day.isCurrentMonth && !day.todoTitles.isEmpty {
                VStack(spacing: 1) {
                    // 첫 번째 할 일 제목 표시 - 더 밝고 큰 폰트
                    Text(truncateTitle(day.todoTitles.first ?? "", maxLength: 4))
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(Color(hex: "#4DD0E1"))  // 밝은 시안색 (다크모드 가독성)
                        .lineLimit(1)

                    // 추가 할 일이 있으면 +N 표시
                    if day.todoCount > 1 {
                        Text("+\(day.todoCount - 1)")
                            .font(.system(size: 7, weight: .medium))
                            .foregroundColor(Color(hex: "#B0BEC5"))  // 밝은 회색
                    }
                }
                .frame(height: 18)
            } else {
                Spacer()
                    .frame(height: 18)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 44)
    }

    // 제목을 지정된 길이로 제한
    private func truncateTitle(_ title: String, maxLength: Int) -> String {
        if title.count <= maxLength {
            return title
        }
        return String(title.prefix(maxLength - 1)) + "…"
    }

    // MARK: - Upcoming Events View
    private var upcomingEventsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header
            HStack {
                Text("다가오는 일정")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(textSecondaryColor)

                Spacer()

                let totalCount = entry.todosByDay.values.flatMap { $0 }.count
                if totalCount > 0 {
                    Text("\(totalCount)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "#64B5F6"))
                }
            }

            // Events list
            let upcomingTodos = getUpcomingTodos()
            if upcomingTodos.isEmpty {
                Text("일정이 없습니다")
                    .font(.system(size: 12))
                    .foregroundColor(textSecondaryColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
            } else {
                ForEach(Array(upcomingTodos.prefix(3).enumerated()), id: \.offset) { index, todo in
                    eventRow(todo: todo)
                }
            }
        }
    }

    // MARK: - Event Row
    private func eventRow(todo: TodoItem) -> some View {
        HStack(spacing: 8) {
            // Date box
            if let dueDate = todo.dueDate {
                Text(formatDate(dueDate))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "#64B5F6"))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: "#64B5F6").opacity(0.2))
                    )
            }

            // Title and time
            VStack(alignment: .leading, spacing: 1) {
                Text(todo.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(textPrimaryColor)
                    .lineLimit(1)

                if let dueDate = todo.dueDate {
                    Text(formatTime(dueDate))
                        .font(.system(size: 10))
                        .foregroundColor(textSecondaryColor)
                }
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }

    // MARK: - Helper Functions
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: entry.displayMonth)
    }

    private func dayNameColor(for day: String) -> Color {
        switch day {
        case "일": return Color(hex: "#E53935")
        case "토": return Color(hex: "#1976D2")
        default: return textSecondaryColor
        }
    }

    private func dayColor(day: CalendarDay, column: Int) -> Color {
        if day.isToday {
            return .white
        }
        if day.holidayName != nil || column == 0 {
            return Color(hex: "#E53935")
        }
        if column == 6 {
            return Color(hex: "#1976D2")
        }
        return textPrimaryColor
    }

    private func generateCalendarDays() -> [CalendarDay] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: entry.displayMonth)
        let month = calendar.component(.month, from: entry.displayMonth)

        var days: [CalendarDay] = []

        // Get first day of month
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        guard let firstOfMonth = calendar.date(from: components) else { return days }

        // Get number of days in month
        guard let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else { return days }
        let daysInMonth = range.count

        // Get weekday of first day (1 = Sunday, 7 = Saturday)
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)

        // Get today's day
        let today = Date()
        let todayDay = calendar.component(.day, from: today)
        let todayMonth = calendar.component(.month, from: today)
        let todayYear = calendar.component(.year, from: today)
        let isCurrentMonth = todayYear == year && todayMonth == month

        // Add empty days for alignment
        for _ in 0..<(firstWeekday - 1) {
            days.append(CalendarDay(day: 0, isCurrentMonth: false, isToday: false, todoCount: 0, holidayName: nil, todoTitles: []))
        }

        // Add days of month
        for day in 1...daysInMonth {
            let todos = entry.todosByDay[day] ?? []
            let todoCount = todos.count
            let todoTitles = todos.map { $0.title }
            let holidayName = entry.holidays[day]
            let isToday = isCurrentMonth && day == todayDay

            days.append(CalendarDay(
                day: day,
                isCurrentMonth: true,
                isToday: isToday,
                todoCount: todoCount,
                holidayName: holidayName,
                todoTitles: todoTitles
            ))
        }

        // Fill remaining cells
        while days.count < 42 {
            days.append(CalendarDay(day: 0, isCurrentMonth: false, isToday: false, todoCount: 0, holidayName: nil, todoTitles: []))
        }

        return days
    }

    private func getUpcomingTodos() -> [TodoItem] {
        var allTodos: [TodoItem] = []
        let calendar = Calendar.current
        let today = calendar.component(.day, from: Date())

        // Get todos from today onwards
        for day in today...31 {
            if let todos = entry.todosByDay[day] {
                allTodos.append(contentsOf: todos)
            }
        }

        // Sort by due date
        return allTodos.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Calendar Day Model
struct CalendarDay {
    let day: Int
    let isCurrentMonth: Bool
    let isToday: Bool
    let todoCount: Int
    let holidayName: String?
    let todoTitles: [String]  // 할 일 제목 목록
}

// MARK: - Widget Configuration
struct TodoCalendarWidget: Widget {
    let kind: String = "TodoCalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarProvider()) { entry in
            if #available(iOS 17.0, *) {
                CalendarWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                CalendarWidgetView(entry: entry)
                    .padding()
                    .background(Color(.systemBackground))
            }
        }
        .configurationDisplayName("할 일 캘린더")
        .description("월별 캘린더에서 할 일 확인")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Preview (iOS 15 compatible)
struct TodoCalendarWidget_Previews: PreviewProvider {
    static var previews: some View {
        CalendarWidgetView(entry: CalendarEntry(
            date: Date(),
            displayMonth: Date(),
            todosByDay: [
                18: [TodoItem(id: "1", title: "Team meeting", description: nil, dueDate: Date(), reminderTime: nil, isCompleted: false, categoryId: 1, categoryName: "Work", categoryColor: "#7B61FF")],
                20: [TodoItem(id: "2", title: "Project deadline", description: nil, dueDate: Date(), reminderTime: nil, isCompleted: false, categoryId: 2, categoryName: "Dev", categoryColor: "#42A5F5")],
                25: [TodoItem(id: "3", title: "Christmas", description: nil, dueDate: Date(), reminderTime: nil, isCompleted: false, categoryId: nil, categoryName: nil, categoryColor: nil)]
            ],
            holidays: [25: "Christmas"],
            selectedDay: nil
        ))
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
