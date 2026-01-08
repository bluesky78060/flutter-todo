import Foundation
import WidgetKit
import SwiftUI

// MARK: - App Group ID
let appGroupId = "group.kr.bluesky.dodo"

// MARK: - Todo Data Model
struct TodoItem: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let dueDate: Date?
    let reminderTime: Date?
    let isCompleted: Bool
    let categoryId: Int?
    let categoryName: String?
    let categoryColor: String?

    var colorBarColor: String {
        categoryColor ?? "#7B61FF"
    }
}

// MARK: - Shared Data Manager
class SharedDataManager {
    static let shared = SharedDataManager()

    private init() {}

    var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    // MARK: - Read Todos
    // Reads from Flutter's home_widget format: todo_1_text, todo_1_id, etc.
    // Note: iOS home_widget does NOT use "flutter." prefix (unlike Android)
    func getTodos() -> [TodoItem] {
        guard let defaults = sharedDefaults else {
            return []
        }

        var todos: [TodoItem] = []

        // Flutter saves up to 10 todos with individual keys
        for i in 1...10 {
            guard let title = defaults.string(forKey: "todo_\(i)_text"),
                  !title.isEmpty else {
                continue
            }

            let id = defaults.string(forKey: "todo_\(i)_id") ?? "\(i)"
            let description = defaults.string(forKey: "todo_\(i)_description")
            let isCompleted = defaults.bool(forKey: "todo_\(i)_completed")
            let timeStr = defaults.string(forKey: "todo_\(i)_time") ?? ""

            // Parse time string to Date (format: "HH:mm" or "M/d")
            var dueDate: Date? = nil
            if !timeStr.isEmpty {
                let formatter = DateFormatter()
                if timeStr.contains("/") {
                    // Date format: M/d
                    formatter.dateFormat = "M/d"
                    if let parsed = formatter.date(from: timeStr) {
                        let calendar = Calendar.current
                        var components = calendar.dateComponents([.month, .day], from: parsed)
                        components.year = calendar.component(.year, from: Date())
                        dueDate = calendar.date(from: components)
                    }
                } else if timeStr.contains(":") {
                    // Time format: HH:mm
                    formatter.dateFormat = "HH:mm"
                    if let parsed = formatter.date(from: timeStr) {
                        let calendar = Calendar.current
                        let today = calendar.startOfDay(for: Date())
                        let timeComponents = calendar.dateComponents([.hour, .minute], from: parsed)
                        dueDate = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                                minute: timeComponents.minute ?? 0,
                                                second: 0,
                                                of: today)
                    }
                }
            }

            let todo = TodoItem(
                id: id,
                title: title,
                description: description?.isEmpty == true ? nil : description,
                dueDate: dueDate,
                reminderTime: nil,
                isCompleted: isCompleted,
                categoryId: nil,
                categoryName: nil,
                categoryColor: nil
            )
            todos.append(todo)
        }

        return todos
    }

    func getTodayTodos() -> [TodoItem] {
        let todos = getTodos()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        return todos.filter { todo in
            guard let dueDate = todo.dueDate else { return false }
            return dueDate >= today && dueDate < tomorrow && !todo.isCompleted
        }
    }

    func getIncompleteTodos() -> [TodoItem] {
        return getTodos().filter { !$0.isCompleted }
    }

    // MARK: - Calendar Data
    // Reads from Flutter's format: day_todos_12_17 = "title1|time1;;title2|time2"
    // Note: iOS home_widget does NOT use "flutter." prefix (unlike Android)
    func getTodosForMonth(year: Int, month: Int) -> [Int: [TodoItem]] {
        guard let defaults = sharedDefaults else {
            print("⚠️ [Widget] SharedDefaults is nil for group: \(appGroupId)")
            return [:]
        }

        // Debug: Print all keys in UserDefaults
        let allKeys = defaults.dictionaryRepresentation().keys
        print("📱 [Widget] All UserDefaults keys (\(allKeys.count) total):")
        for key in allKeys.sorted() {
            let value = defaults.object(forKey: key)
            print("   - \(key): \(String(describing: value).prefix(50))")
        }

        var todosByDay: [Int: [TodoItem]] = [:]

        // Get last day of month
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month + 1
        components.day = 0
        let lastDay = calendar.date(from: components).map { calendar.component(.day, from: $0) } ?? 31

        // Read day-specific todos from Flutter's format
        for day in 1...lastDay {
            let key = "day_todos_\(month)_\(day)"
            guard let todosStr = defaults.string(forKey: key),
                  !todosStr.isEmpty else {
                continue
            }

            // Parse format: "title1|time1;;title2|time2"
            let todoStrings = todosStr.components(separatedBy: ";;")
            var dayTodos: [TodoItem] = []

            for (index, todoStr) in todoStrings.enumerated() {
                let parts = todoStr.components(separatedBy: "|")
                let title = parts.first ?? ""
                let timeStr = parts.count > 1 ? parts[1] : ""

                var dueDate: Date? = nil
                if !timeStr.isEmpty {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    if let time = formatter.date(from: timeStr) {
                        var dateComponents = DateComponents()
                        dateComponents.year = year
                        dateComponents.month = month
                        dateComponents.day = day
                        dateComponents.hour = calendar.component(.hour, from: time)
                        dateComponents.minute = calendar.component(.minute, from: time)
                        dueDate = calendar.date(from: dateComponents)
                    }
                } else {
                    // Set dueDate to that day at midnight
                    var dateComponents = DateComponents()
                    dateComponents.year = year
                    dateComponents.month = month
                    dateComponents.day = day
                    dueDate = calendar.date(from: dateComponents)
                }

                let todo = TodoItem(
                    id: "\(month)_\(day)_\(index)",
                    title: title,
                    description: nil,
                    dueDate: dueDate,
                    reminderTime: nil,
                    isCompleted: false,
                    categoryId: nil,
                    categoryName: nil,
                    categoryColor: nil
                )
                dayTodos.append(todo)
            }

            if !dayTodos.isEmpty {
                todosByDay[day] = dayTodos
            }
        }

        // Also check calendar_day markers for days that have tasks (dots)
        for i in 1...42 {
            let key = "calendar_day_\(i)"
            if let dayStr = defaults.string(forKey: key),
               dayStr.contains("●") {
                // Extract day number from the string (e.g., "15●" -> 15)
                let dayNum = Int(dayStr.replacingOccurrences(of: "●", with: "").replacingOccurrences(of: "★", with: "")) ?? 0
                if dayNum > 0 && dayNum <= lastDay && todosByDay[dayNum] == nil {
                    // Create placeholder if we don't have detailed todos
                    todosByDay[dayNum] = []
                }
            }
        }

        return todosByDay
    }

    // MARK: - Korean Holidays (2025-2026)
    func getHolidays(year: Int, month: Int) -> [Int: String] {
        let holidays: [String: [String: [Int: String]]] = [
            "2025": [
                "1": [1: "신정", 28: "설날", 29: "설날", 30: "설날"],
                "3": [1: "삼일절"],
                "5": [5: "어린이날", 6: "석가탄신일"],
                "6": [6: "현충일"],
                "8": [15: "광복절"],
                "9": [6: "추석", 7: "추석", 8: "추석"],
                "10": [3: "개천절", 9: "한글날"],
                "12": [25: "성탄절"]
            ],
            "2026": [
                "1": [1: "신정"],
                "2": [16: "설날", 17: "설날", 18: "설날"],
                "3": [1: "삼일절"],
                "5": [5: "어린이날", 24: "석가탄신일", 25: "대체공휴일"],
                "6": [6: "현충일"],
                "8": [15: "광복절"],
                "9": [24: "추석", 25: "추석", 26: "추석"],
                "10": [3: "개천절", 9: "한글날"],
                "12": [25: "성탄절"]
            ]
        ]

        return holidays["\(year)"]?["\(month)"] ?? [:]
    }
}

// MARK: - Widget Appearance Settings
struct WidgetAppearance {
    // 카드 배경 투명도 (0.0 ~ 1.0)
    // 다크모드와 라이트모드 각각 설정 가능

    /// UserDefaults에서 Double 값을 유연하게 읽음 (NSNumber, Double, String 지원)
    private static func readDouble(from defaults: UserDefaults?, forKey key: String, default defaultValue: Double) -> Double {
        guard let defaults = defaults else {
            print("📱 [WidgetAppearance] \(key): defaults is nil, using default: \(defaultValue)")
            return defaultValue
        }

        // Force synchronize to get latest values from disk
        defaults.synchronize()

        guard let obj = defaults.object(forKey: key) else {
            print("📱 [WidgetAppearance] \(key): key not found, using default: \(defaultValue)")
            return defaultValue
        }

        print("📱 [WidgetAppearance] \(key): raw type=\(type(of: obj)), value=\(obj)")

        // Try NSNumber (most common from Flutter)
        if let num = obj as? NSNumber {
            let value = num.doubleValue
            print("📱 [WidgetAppearance] \(key): parsed as NSNumber -> \(value)")
            return value
        }

        // Try Double directly
        if let value = obj as? Double {
            print("📱 [WidgetAppearance] \(key): parsed as Double -> \(value)")
            return value
        }

        // Try String (fallback - some versions of home_widget may use this)
        if let str = obj as? String, let value = Double(str) {
            print("📱 [WidgetAppearance] \(key): parsed as String -> \(value)")
            return value
        }

        print("📱 [WidgetAppearance] \(key): could not parse, using default: \(defaultValue)")
        return defaultValue
    }

    static var cardOpacityDark: Double {
        let defaults = UserDefaults(suiteName: appGroupId)
        let value = readDouble(from: defaults, forKey: "widget_card_opacity_dark", default: 0.15)
        print("📱 [WidgetAppearance] cardOpacityDark final value: \(value)")
        return value
    }

    static var cardOpacityLight: Double {
        let defaults = UserDefaults(suiteName: appGroupId)
        let value = readDouble(from: defaults, forKey: "widget_card_opacity_light", default: 0.7)
        print("📱 [WidgetAppearance] cardOpacityLight final value: \(value)")
        return value
    }

    // 카드 배경색 조정
    static func cardBackground(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            return Color.white.opacity(cardOpacityDark)
        case .light:
            return Color.white.opacity(cardOpacityLight)
        @unknown default:
            return Color.white.opacity(0.5)
        }
    }

    // 캘린더 위젯용 카드 배경 (더 미묘한 효과)
    static func calendarCardBackground(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            return Color.white.opacity(cardOpacityDark * 0.67) // 0.1 기본값
        case .light:
            return Color.black.opacity(cardOpacityLight * 0.07) // 0.05 기본값
        @unknown default:
            return Color.gray.opacity(0.1)
        }
    }
}

// MARK: - Color Extension
extension String {
    func toColor() -> Color {
        var hexString = self.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }

        guard hexString.count == 6,
              let rgb = UInt64(hexString, radix: 16) else {
            return Color.purple
        }

        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0

        return Color(red: red, green: green, blue: blue)
    }
}
