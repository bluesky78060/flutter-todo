import Foundation

// MARK: - Widget Slot Model

/// App Group UserDefaults 의 `todo_N_*` 한 칸.
///
/// Flutter 는 항상 10칸을 채워 보내고 위젯은 앞의 2~3칸만 그린다.
/// 남는 칸이 있어야 앱을 다시 열지 않고도 연속으로 완료 처리할 수 있다.
struct WidgetTodoSlot: Equatable {
    var text: String
    var description: String
    var time: String
    var id: String
    var group: String
    var completed: Bool
}

/// 슬롯 배열 조작. **UserDefaults 를 모른다.**
///
/// 배열만 받아 배열을 돌려주므로 단독으로 검증할 수 있다.
/// 저장소를 직접 만지는 코드였다면 실기기 없이는 확인할 방법이 없었다.
enum WidgetSlotStore {
    static let slotCount = 10

    /// `slot` 번 칸을 빼고 뒤 항목을 한 칸씩 당긴다. 마지막 칸은 비운다.
    ///
    /// - Parameter slot: 1-based 슬롯 번호. 범위를 벗어나면 원본을 그대로 돌려준다.
    static func removing(slot: Int, from slots: [WidgetTodoSlot?]) -> [WidgetTodoSlot?] {
        guard slot >= 1, slot <= slots.count else { return slots }
        var next = slots
        next.remove(at: slot - 1)
        next.append(nil)
        return next
    }

    /// `pending_syncs` 문자열에 항목을 추가한다. 형식은 Android 와 같은
    /// `"id:completed,id:completed"` 이며, Dart 의 `WidgetSyncService` 가 그대로 읽는다.
    ///
    /// 같은 할 일의 옛 항목은 지운다. 안 그러면 `"7:true,7:false"` 처럼 쌓여
    /// 마지막 것이 이길지 첫 것이 이길지가 순서에 좌우된다.
    static func enqueue(id: String, completed: Bool, into raw: String) -> String {
        guard !id.isEmpty else { return raw }
        var entries = raw
            .split(separator: ",")
            .map(String.init)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        entries.removeAll { $0.hasPrefix("\(id):") }
        entries.append("\(id):\(completed)")
        return entries.joined(separator: ",")
    }
}
