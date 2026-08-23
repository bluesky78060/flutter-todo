import AppIntents
import Foundation
import WidgetKit

// MARK: - Storage Access

extension SharedDataManager {
    /// 저장된 10칸을 그대로 읽는다. 빈 칸은 nil.
    func readSlots() -> [WidgetTodoSlot?] {
        guard let defaults = sharedDefaults else {
            return Array(repeating: nil, count: WidgetSlotStore.slotCount)
        }
        return (1...WidgetSlotStore.slotCount).map { slot -> WidgetTodoSlot? in
            guard let text = defaults.string(forKey: "todo_\(slot)_text"), !text.isEmpty else {
                return nil
            }
            return WidgetTodoSlot(
                text: text,
                description: defaults.string(forKey: "todo_\(slot)_description") ?? "",
                time: defaults.string(forKey: "todo_\(slot)_time") ?? "",
                id: defaults.string(forKey: "todo_\(slot)_id") ?? "",
                group: defaults.string(forKey: "todo_\(slot)_group") ?? "",
                completed: defaults.bool(forKey: "todo_\(slot)_completed")
            )
        }
    }

    func writeSlots(_ slots: [WidgetTodoSlot?]) {
        guard let defaults = sharedDefaults else { return }
        for (index, slot) in slots.prefix(WidgetSlotStore.slotCount).enumerated() {
            let n = index + 1
            // 빈 칸은 빈 문자열로 덮어쓴다. removeObject 를 쓰면 Flutter 가
            // 다음에 저장한 값과 섞여 옛 항목이 되살아날 수 있다.
            defaults.set(slot?.text ?? "", forKey: "todo_\(n)_text")
            defaults.set(slot?.description ?? "", forKey: "todo_\(n)_description")
            defaults.set(slot?.time ?? "", forKey: "todo_\(n)_time")
            defaults.set(slot?.id ?? "", forKey: "todo_\(n)_id")
            defaults.set(slot?.group ?? "", forKey: "todo_\(n)_group")
            defaults.set(slot?.completed ?? false, forKey: "todo_\(n)_completed")
        }
    }

    /// 위젯에서 할 일 하나를 완료 처리한다.
    ///
    /// **서버에는 여기서 쓰지 않는다.** 위젯 익스텐션에 Supabase 접근 토큰을 두지
    /// 않기 위해서다. 대신 `pending_syncs` 에 넣어 두면 앱이 다시 열릴 때
    /// `WidgetSyncService` 가 Supabase 에 반영한다. 반영에 실패하면 큐에 남아
    /// 다음 진입에서 다시 시도한다.
    ///
    /// - Returns: 처리했으면 true. 해당 id 를 못 찾으면 false.
    @discardableResult
    func completeTodo(id: String) -> Bool {
        guard let defaults = sharedDefaults, let slot = storageSlot(forTodoId: id) else {
            return false
        }

        let slots = readSlots()
        let removed = slots[slot - 1]
        writeSlots(WidgetSlotStore.removing(slot: slot, from: slots))

        // 진행률은 **오늘 기준**이라 오늘 항목일 때만 올린다.
        // 미래 일정을 완료했다고 올리면 3/2 같은 값이 나온다.
        if removed?.group == "today" {
            let total = defaults.integer(forKey: "todo_total_count")
            let completed = defaults.integer(forKey: "todo_completed_count")
            defaults.set(min(completed + 1, total), forKey: "todo_completed_count")
        }

        defaults.set(
            WidgetSlotStore.enqueue(
                id: id,
                completed: true,
                into: defaults.string(forKey: "pending_syncs") ?? ""
            ),
            forKey: "pending_syncs"
        )

        // 위젯이 10칸을 다 쓰면 더 당길 것이 없다. 앱이 다시 열릴 때
        // 다음 항목들을 새로 채우도록 표시해 둔다.
        defaults.set(true, forKey: "pending_widget_refresh")

        return true
    }
}

// MARK: - App Intent

/// 위젯의 동그라미를 눌렀을 때 실행된다. 앱은 열지 않는다.
@available(iOS 17.0, *)
struct CompleteTodoIntent: AppIntent {
    static let title: LocalizedStringResource = "할 일 완료"
    static let description = IntentDescription("위젯에서 할 일을 완료 처리합니다.")
    static let openAppWhenRun: Bool = false

    @Parameter(title: "Todo ID")
    var todoId: String

    init() {}

    init(todoId: String) {
        self.todoId = todoId
    }

    func perform() async throws -> some IntentResult {
        SharedDataManager.shared.completeTodo(id: todoId)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
