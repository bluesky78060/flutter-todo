//
//  TodoWidgetsBundle.swift
//  TodoWidgets
//
//  Created by lee chanhee on 1/6/26.
//

import WidgetKit
import SwiftUI

@main
struct TodoWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TodoListWidget()
        TodoDetailWidget()
        TodoCalendarWidget()
    }
}
