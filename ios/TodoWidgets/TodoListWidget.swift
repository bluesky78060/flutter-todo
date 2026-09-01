import AppIntents
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
                TodoItem(id: "1", title: "Sample Task 1", description: nil, dueDate: Date(), displayTime: nil, reminderTime: nil, isCompleted: false, categoryId: 1, categoryName: "Work", categoryColor: "#7B61FF"),
                TodoItem(id: "2", title: "Sample Task 2", description: nil, dueDate: Date(), displayTime: nil, reminderTime: nil, isCompleted: false, categoryId: 2, categoryName: "Personal", categoryColor: "#42A5F5")
            ],
            completedCount: 0,
            totalCount: 2
        )
    }

    /// 목록은 Flutter 가 "다가오는 순서"로 정렬해 저장해 둔 미완료 할 일이다.
    ///
    /// 예전에는 `getTodayTodos()` 로 오늘만 걸렀다. 그 필터는 **표시용 문자열을
    /// 되파싱해서** 날짜를 복원하는 방식이라, 라벨 형식이 "8/25 09:00" 처럼
    /// 바뀌면 파싱에 실패해 항목이 통째로 사라진다. 필터를 없애는 쪽이 맞다 —
    /// 무엇을 보여줄지는 Flutter 가 이미 정해서 보냈다.
    private func makeEntry() -> TodoListEntry {
        let todos = SharedDataManager.shared.getIncompleteTodos()
        let counts = SharedDataManager.shared.getProgressCounts()
        return TodoListEntry(
            date: Date(),
            todos: Array(todos.prefix(3)),
            completedCount: counts.completed,
            totalCount: counts.total
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TodoListEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodoListEntry>) -> Void) {
        // Update more frequently for testing (5 minutes)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
        let timeline = Timeline(entries: [makeEntry()], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget View (Design B: Card with Color Bar)
/// 목록 항목의 완료 체크박스.
///
/// 위젯 안에서 눌러 바로 완료 처리하는 버튼은 AppIntents 기반이라 iOS 17
/// 부터다. CompleteTodoIntent 자체는 @available(iOS 17.0, *) 로 표시돼
/// 있었는데 쓰는 쪽에 가드가 없어, 익스텐션 배포 타깃(15.6)에서는
/// 컴파일되지 않았다.
///
/// 17 미만에서는 같은 모양의 표시용 체크박스만 두고, 탭은 위젯 전체의
/// 앱 열기로 떨어지게 둔다. 기능이 줄 뿐 화면은 같다.
struct CompletionCheckbox: View {
    let todo: TodoItem

    /// 글리프 크기. 목록 위젯은 18, 상세 위젯은 16 을 쓴다.
    /// 탭 영역(44pt)은 크기와 무관하게 같다.
    var glyphSize: CGFloat = 18

    /// 탭 영역을 44pt 로 넓힌다. 글리프 크기(18pt)만으로는 HIG 최소치에
    /// 한참 못 미쳐서, 살짝 빗나간 탭이 버튼을 지나쳐 **위젯 전체의
    /// 앱 열기**로 떨어진다. 앱을 열지 않는 것이 이 기능의 목적이다.
    private var glyph: some View {
        Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
            .font(.system(size: glyphSize))
            .foregroundColor(todo.isCompleted ? .green : .gray)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
    }

    var body: some View {
        if #available(iOS 17.0, *) {
            Button(intent: CompleteTodoIntent(todoId: todo.id)) {
                glyph
            }
            .buttonStyle(.plain)
        } else {
            glyph
        }
    }
}

struct TodoListWidgetView: View {
    var entry: TodoListEntry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme

    var backgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.8) : Color.white.opacity(0.9)
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
            // 마감이 가까운 순으로 보여 준다. "오늘 할 일"이 아니다.
            Text("다가오는 일정")
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
                // Checkbox — 눌러서 바로 완료 처리한다 (앱을 열지 않는다)
                //
                // 탭 영역을 44pt 로 넓힌다. 글리프 크기(18pt)만으로는 HIG 최소치에
                // 한참 못 미쳐서, 살짝 빗나간 탭이 버튼을 지나쳐 **위젯 전체의
                // 앱 열기**로 떨어진다. 앱을 열지 않는 것이 이 기능의 목적이다.
                // 음수 여백으로 겉보기 배치는 그대로 둔다.
                CompletionCheckbox(todo: todo)
                    .padding(.vertical, -13)
                    .padding(.leading, -13)
                    .padding(.trailing, -13)

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(todo.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(todo.isCompleted ? .secondary : .primary)
                        .strikethrough(todo.isCompleted)
                        .lineLimit(1)

                    if let label = todo.displayTime ?? todo.dueDate.map(formatTime) {
                        // Flutter 가 만든 문자열을 그대로 쓴다.
                        // formatTime 은 무조건 "h:mm a" 로 그리기 때문에,
                        // "11/15" 같은 날짜가 "12:00 AM" 으로 바뀌어 버린다.
                        Text(label)
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
            if #available(iOS 17.0, *) {
                TodoListWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                TodoListWidgetView(entry: entry)
                    .padding()
                    .background(Color(.systemBackground))
            }
        }
        .configurationDisplayName("할 일 목록")
        .description("마감이 가까운 할 일을 한눈에 확인하세요")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview (iOS 15 compatible)
struct TodoListWidget_Previews: PreviewProvider {
    static var previews: some View {
        TodoListWidgetView(entry: TodoListEntry(
            date: Date(),
            todos: [
                TodoItem(id: "1", title: "Team meeting", description: nil, dueDate: Date(), displayTime: nil, reminderTime: nil, isCompleted: false, categoryId: 1, categoryName: "Work", categoryColor: "#7B61FF"),
                TodoItem(id: "2", title: "Review PR", description: nil, dueDate: Date(), displayTime: nil, reminderTime: nil, isCompleted: true, categoryId: 1, categoryName: "Work", categoryColor: "#42A5F5"),
                TodoItem(id: "3", title: "Grocery shopping", description: nil, dueDate: Date(), displayTime: nil, reminderTime: nil, isCompleted: false, categoryId: 2, categoryName: "Personal", categoryColor: "#66BB6A")
            ],
            completedCount: 1,
            totalCount: 3
        ))
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
