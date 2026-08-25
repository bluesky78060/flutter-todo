import AppIntents
import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
struct TodoDetailEntry: TimelineEntry {
    let date: Date
    let todos: [TodoItem]
}

// MARK: - Timeline Provider
struct TodoDetailProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodoDetailEntry {
        TodoDetailEntry(
            date: Date(),
            todos: [
                TodoItem(id: "1", title: "Meeting with team", description: "Discuss Q1 goals", dueDate: Date(), displayTime: nil, reminderTime: nil, isCompleted: false, categoryId: 1, categoryName: "Work", categoryColor: "#7B61FF"),
                TodoItem(id: "2", title: "Project deadline", description: "Submit final report", dueDate: Date(), displayTime: nil, reminderTime: nil, isCompleted: false, categoryId: 2, categoryName: "Project", categoryColor: "#42A5F5")
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TodoDetailEntry) -> Void) {
        let todos = SharedDataManager.shared.getIncompleteTodos()
        let entry = TodoDetailEntry(
            date: Date(),
            todos: Array(todos.prefix(2))
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodoDetailEntry>) -> Void) {
        // Debug: Log opacity values on timeline refresh
        print("📱 [TodoDetailWidget] getTimeline called")
        print("📱 [TodoDetailWidget] cardOpacityDark = \(WidgetAppearance.cardOpacityDark)")
        print("📱 [TodoDetailWidget] cardOpacityLight = \(WidgetAppearance.cardOpacityLight)")

        let todos = SharedDataManager.shared.getIncompleteTodos()
        let entry = TodoDetailEntry(
            date: Date(),
            todos: Array(todos.prefix(2))
        )

        // Update more frequently for testing (5 minutes)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget View (Design E: Timeline Style)
struct TodoDetailWidgetView: View {
    var entry: TodoDetailEntry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme

    var backgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.8) : Color.white.opacity(0.9)
    }

    var cardBackgroundColor: Color {
        WidgetAppearance.cardBackground(for: colorScheme)
    }

    var lineColor: Color {
        colorScheme == .dark ? Color(hex: "#333333") : Color(hex: "#E0E0E0")
    }

    var body: some View {
        VStack(spacing: 8) {
            // Header
            headerView

            // Timeline Content
            if entry.todos.isEmpty {
                emptyStateView
            } else {
                timelineView
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        // Glass 효과: 배경 제거하여 containerBackground의 material이 보이도록 함
    }

    // MARK: - Header View
    private var headerView: some View {
        HStack {
            // 마감이 가까운 순으로 보여 준다. "오늘 할 일"이 아니다.
            Text("다가오는 일정")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)

            Spacer()

            // Add Button
            ZStack {
                Circle()
                    .fill(Color(hex: "#7B61FF"))
                    .frame(width: 28, height: 28)

                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.5))

            Text("할 일이 없습니다")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Timeline View
    private var timelineView: some View {
        HStack(alignment: .top, spacing: 8) {
            // Timeline column (dots and line)
            VStack(spacing: 0) {
                ForEach(Array(entry.todos.enumerated()), id: \.element.id) { index, todo in
                    let dotColors = ["#7B61FF", "#42A5F5"]
                    let dotColor = todo.categoryColor ?? dotColors[index % dotColors.count]

                    VStack(spacing: 0) {
                        // Dot
                        Circle()
                            .fill(dotColor.toColor())
                            .frame(width: 10, height: 10)

                        // Line (if not last item)
                        if index < entry.todos.count - 1 {
                            Rectangle()
                                .fill(lineColor)
                                .frame(width: 2)
                                .frame(minHeight: 50)
                        }
                    }
                }

                // Bottom line extension
                Rectangle()
                    .fill(lineColor)
                    .frame(width: 2, height: 20)
            }
            .frame(width: 24)

            // Cards column
            VStack(spacing: 12) {
                ForEach(Array(entry.todos.enumerated()), id: \.element.id) { index, todo in
                    let dotColors = ["#7B61FF", "#42A5F5"]
                    let cardColor = todo.categoryColor ?? dotColors[index % dotColors.count]
                    todoCardView(todo: todo, accentColor: cardColor)
                }
            }
        }
    }

    // MARK: - Todo Card View
    private func todoCardView(todo: TodoItem, accentColor: String) -> some View {
        HStack(spacing: 10) {
            // Checkbox — 눌러서 바로 완료 처리한다 (앱을 열지 않는다)
            //
            // 탭 영역 44pt. 이유는 TodoListWidget 쪽 주석 참고.
            Button(intent: CompleteTodoIntent(todoId: todo.id)) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundColor(todo.isCompleted ? .green : .gray)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, -14)
            .padding(.leading, -14)
            .padding(.trailing, -14)

            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(todo.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(todo.isCompleted ? .secondary : .primary)
                    .strikethrough(todo.isCompleted)
                    .lineLimit(1)

                if let description = todo.description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Time badge
            //
            // Flutter 가 만든 문자열을 그대로 쓴다. formatTime 은 무조건 "h:mm a" 로
            // 그리기 때문에, "11/15" 같은 날짜가 "12:00 AM" 으로 바뀌어 버린다.
            if let label = todo.displayTime ?? todo.dueDate.map(formatTime) {
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(accentColor.toColor())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(accentColor.toColor().opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .padding(10)
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }

    // MARK: - Helper Functions
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Widget Configuration
struct TodoDetailWidget: Widget {
    let kind: String = "TodoDetailWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodoDetailProvider()) { entry in
            if #available(iOS 17.0, *) {
                TodoDetailWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                TodoDetailWidgetView(entry: entry)
                    .padding()
                    .background(Color(.systemBackground))
            }
        }
        .configurationDisplayName("할 일 상세")
        .description("타임라인으로 할 일 상세 보기")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview (iOS 15 compatible)
struct TodoDetailWidget_Previews: PreviewProvider {
    static var previews: some View {
        TodoDetailWidgetView(entry: TodoDetailEntry(
            date: Date(),
            todos: [
                TodoItem(id: "1", title: "Team meeting", description: "Discuss Q1 roadmap", dueDate: Date(), displayTime: nil, reminderTime: nil, isCompleted: false, categoryId: 1, categoryName: "Work", categoryColor: "#7B61FF"),
                TodoItem(id: "2", title: "Review code", description: "Check PR #123", dueDate: Date(), displayTime: nil, reminderTime: nil, isCompleted: false, categoryId: 2, categoryName: "Dev", categoryColor: "#42A5F5")
            ]
        ))
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
