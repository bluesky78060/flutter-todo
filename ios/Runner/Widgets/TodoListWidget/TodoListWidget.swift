import WidgetKit
import SwiftUI

struct TodoListWidgetEntry: TimelineEntry {
    let date: Date
    var todos: [TodoData] = []
    var isEnabled: Bool = true
    var completedCount: Int = 0
    var pendingCount: Int = 0
}

struct TodoData: Identifiable {
    let id: String
    let title: String
    let time: String
    let isCompleted: Bool
}

struct TodoListWidgetEntryView: View {
    var entry: TodoListWidgetEntry

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Tasks")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)

                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "MMM dd, yyyy"
                    Text(dateFormatter.string(from: entry.date))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Progress indicator
                if !entry.todos.isEmpty {
                    Text("\(entry.completedCount)/\(entry.todos.count)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.purple)
                }
            }

            Divider()

            // Todo list
            VStack(spacing: 8) {
                if entry.todos.isEmpty {
                    Text("No tasks for today")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    ForEach(entry.todos.prefix(3)) { todo in
                        HStack(spacing: 12) {
                            Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(todo.isCompleted ? .green : .gray)
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(todo.title)
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary)
                                    .strikethrough(todo.isCompleted)
                                    .lineLimit(1)

                                Text(todo.time)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                    }

                    if entry.todos.count > 3 {
                        Text("+\(entry.todos.count - 3) more")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
            }

            Spacer()

            // Footer
            Text("Tap to view all tasks")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
        }
        .padding(12)
        .background(Color(UIColor.systemBackground))
    }
}

struct TodoListWidget: Widget {
    let kind: String = "TodoListWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TodoListWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Today's Tasks")
        .description("Shows today's incomplete tasks")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TodoListWidgetEntry {
        TodoListWidgetEntry(
            date: Date(),
            todos: [
                TodoData(id: "1", title: "Sample Task", time: "10:00 AM", isCompleted: false)
            ],
            isEnabled: true,
            completedCount: 0,
            pendingCount: 1
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TodoListWidgetEntry) -> Void) {
        let entry = TodoListWidgetEntry(
            date: Date(),
            todos: [],
            isEnabled: true,
            completedCount: 0,
            pendingCount: 0
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        var entries: [TodoListWidgetEntry] = []

        // Create entries for the next hour, updating every 15 minutes
        let currentDate = Date()
        for i in 0..<4 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: i * 15, to: currentDate)!
            let entry = TodoListWidgetEntry(
                date: entryDate,
                todos: [],
                isEnabled: true,
                completedCount: 0,
                pendingCount: 0
            )
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

#Preview(as: .systemSmall) {
    TodoListWidget()
} timeline: {
    TodoListWidgetEntry(
        date: Date(),
        todos: [
            TodoData(id: "1", title: "Meeting with team", time: "10:00 AM", isCompleted: false),
            TodoData(id: "2", title: "Project deadline", time: "3:00 PM", isCompleted: false),
            TodoData(id: "3", title: "Review code", time: "2:00 PM", isCompleted: true)
        ],
        isEnabled: true,
        completedCount: 1,
        pendingCount: 2
    )
}
