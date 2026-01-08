import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
struct TodoListEntry: TimelineEntry {
    let date: Date
    let todos: [TodoItem]
    let completedCount: Int
    let totalCount: Int
}

// MARK: - Timeline Provider
struct TodoListProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodoListEntry {
        TodoListEntry(
            date: Date(),
            todos: [
                TodoItem(id: "1", title: "Sample Task 1", description: nil, dueDate: Date(), reminderTime: nil, isCompleted: false, categoryId: 1, categoryName: "Work", categoryColor: "#7B61FF"),
                TodoItem(id: "2", title: "Sample Task 2", description: nil, dueDate: Date(), reminderTime: nil, isCompleted: false, categoryId: 2, categoryName: "Personal", categoryColor: "#42A5F5")
            ],
            completedCount: 0,
            totalCount: 2
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TodoListEntry) -> Void) {
        let todos = SharedDataManager.shared.getTodayTodos()
        let entry = TodoListEntry(
            date: Date(),
            todos: Array(todos.prefix(3)),
            completedCount: todos.filter { $0.isCompleted }.count,
            totalCount: todos.count
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodoListEntry>) -> Void) {
        // Debug: Log opacity values on timeline refresh
        print("📱 [TodoListWidget] getTimeline called")
        print("📱 [TodoListWidget] cardOpacityDark = \(WidgetAppearance.cardOpacityDark)")
        print("📱 [TodoListWidget] cardOpacityLight = \(WidgetAppearance.cardOpacityLight)")

        let todos = SharedDataManager.shared.getTodayTodos()
        let entry = TodoListEntry(
            date: Date(),
            todos: Array(todos.prefix(3)),
            completedCount: todos.filter { $0.isCompleted }.count,
            totalCount: todos.count
        )

        // Update more frequently for testing (5 minutes)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget View (Design B: Card with Color Bar)
struct TodoListWidgetView: View {
    var entry: TodoListEntry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.widgetRenderingMode) var renderingMode

    var backgroundColor: Color {
        Color.clear  // Glass 효과를 위해 투명 배경
    }

    var cardBackgroundColor: Color {
        WidgetAppearance.cardBackground(for: colorScheme)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Header
            headerView

            // Todo Cards
            if entry.todos.isEmpty {
                emptyStateView
            } else {
                todoCardsView
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        // Glass 효과: 배경 제거하여 containerBackground의 material이 보이도록 함
    }

    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Text("할 일")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)

            Spacer()

            if entry.totalCount > 0 {
                Text("\(entry.completedCount)/\(entry.totalCount)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.trailing, 8)
            }

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
            Image(systemName: "checkmark.circle")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.5))

            Text("할 일이 없습니다")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Todo Cards View
    private var todoCardsView: some View {
        VStack(spacing: 8) {
            ForEach(Array(entry.todos.enumerated()), id: \.element.id) { index, todo in
                todoCardView(todo: todo, colorIndex: index)
            }
        }
    }

    // MARK: - Individual Todo Card
    private func todoCardView(todo: TodoItem, colorIndex: Int) -> some View {
        let colorBars = ["#7B61FF", "#42A5F5", "#66BB6A", "#FFA726"]
        let barColor = todo.categoryColor ?? colorBars[colorIndex % colorBars.count]

        return HStack(spacing: 0) {
            // Color Bar
            Rectangle()
                .fill(barColor.toColor())
                .frame(width: 4)

            // Content
            HStack(spacing: 10) {
                // Checkbox
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(todo.isCompleted ? .green : .gray)

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(todo.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(todo.isCompleted ? .secondary : .primary)
                        .strikethrough(todo.isCompleted)
                        .lineLimit(1)

                    if let dueDate = todo.dueDate {
                        Text(formatTime(dueDate))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Category Badge
                if let categoryName = todo.categoryName {
                    Text(categoryName)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(barColor.toColor())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(barColor.toColor().opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        }
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

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Widget Configuration
struct TodoListWidget: Widget {
    let kind: String = "TodoListWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodoListProvider()) { entry in
            TodoListWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    // iOS 26 Glass Effect - 시스템 기본 glass 배경
                    Rectangle()
                        .fill(.clear)
                        .glassEffect()
                }
        }
        .configurationDisplayName("할 일 목록")
        .description("오늘의 할 일을 한눈에 확인하세요")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

// MARK: - Preview
#Preview(as: .systemMedium) {
    TodoListWidget()
} timeline: {
    TodoListEntry(
        date: Date(),
        todos: [
            TodoItem(id: "1", title: "Team meeting", description: nil, dueDate: Date(), reminderTime: nil, isCompleted: false, categoryId: 1, categoryName: "Work", categoryColor: "#7B61FF"),
            TodoItem(id: "2", title: "Review PR", description: nil, dueDate: Date(), reminderTime: nil, isCompleted: true, categoryId: 1, categoryName: "Work", categoryColor: "#42A5F5"),
            TodoItem(id: "3", title: "Grocery shopping", description: nil, dueDate: Date(), reminderTime: nil, isCompleted: false, categoryId: 2, categoryName: "Personal", categoryColor: "#66BB6A")
        ],
        completedCount: 1,
        totalCount: 3
    )
}
