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
                TodoItem(id: "1", title: "Meeting with team", description: "Discuss Q1 goals", dueDate: Date(), reminderTime: nil, isCompleted: false, categoryId: 1, categoryName: "Work", categoryColor: "#7B61FF"),
                TodoItem(id: "2", title: "Project deadline", description: "Submit final report", dueDate: Date(), reminderTime: nil, isCompleted: false, categoryId: 2, categoryName: "Project", categoryColor: "#42A5F5")
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
    @Environment(\.widgetRenderingMode) var renderingMode

    var backgroundColor: Color {
        Color.clear  // Glass 효과를 위해 투명 배경
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
            Text("오늘 할 일")
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
            // Checkbox
            Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16))
                .foregroundColor(todo.isCompleted ? .green : .gray)

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
            if let dueDate = todo.dueDate {
                Text(formatTime(dueDate))
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
            TodoDetailWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    // iOS 26 Glass Effect - 시스템 기본 glass 배경
                    Rectangle()
                        .fill(.clear)
                        .glassEffect()
                }
        }
        .configurationDisplayName("할 일 상세")
        .description("타임라인으로 할 일 상세 보기")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

// MARK: - Preview
#Preview(as: .systemMedium) {
    TodoDetailWidget()
} timeline: {
    TodoDetailEntry(
        date: Date(),
        todos: [
            TodoItem(id: "1", title: "Team meeting", description: "Discuss Q1 roadmap", dueDate: Date(), reminderTime: nil, isCompleted: false, categoryId: 1, categoryName: "Work", categoryColor: "#7B61FF"),
            TodoItem(id: "2", title: "Review code", description: "Check PR #123", dueDate: Date(), reminderTime: nil, isCompleted: false, categoryId: 2, categoryName: "Dev", categoryColor: "#42A5F5")
        ]
    )
}
