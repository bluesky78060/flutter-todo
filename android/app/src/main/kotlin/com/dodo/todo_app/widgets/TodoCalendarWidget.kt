package com.dodo.todo_app.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.time.LocalDate
import java.time.YearMonth

/**
 * Calendar Widget
 * Displays current month calendar with task indicators
 */
class TodoCalendarWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: MutableMap<String, Any?>
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds, widgetData)

        appWidgetIds.forEach { appWidgetId ->
            updateAppWidget(context, appWidgetManager, appWidgetId, widgetData)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        widgetData: Map<String, Any?>
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_calendar)

        // Extract data from widget data map
        val viewType = widgetData["view_type"] as? String ?: "none"

        if (viewType == "none") {
            // Widget disabled
            views.setTextViewText(
                R.id.calendar_title,
                context.getString(R.string.widget_disabled)
            )
            appWidgetManager.updateAppWidget(appWidgetId, views)
            return
        }

        // Get current month
        val today = LocalDate.now()
        val yearMonth = YearMonth.now()
        val monthName = yearMonth.month.toString().take(3)
        val year = yearMonth.year

        views.setTextViewText(
            R.id.calendar_title,
            "$monthName $year"
        )

        // Calculate calendar grid
        val firstDay = today.withDayOfMonth(1)
        val lastDay = today.withDayOfMonth(today.lengthOfMonth())
        val startDayOfWeek = firstDay.dayOfWeek.value % 7 // 0 = Sunday

        // Update calendar cells with day numbers
        updateCalendarGrid(views, startDayOfWeek, lastDay.dayOfMonth)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun updateCalendarGrid(
        views: RemoteViews,
        startDayOfWeek: Int,
        daysInMonth: Int
    ) {
        // Grid row IDs
        val rowIds = intArrayOf(
            R.id.calendar_row_1,
            R.id.calendar_row_2,
            R.id.calendar_row_3,
            R.id.calendar_row_4,
            R.id.calendar_row_5,
            R.id.calendar_row_6
        )

        var dayNumber = 1
        var row = 0
        var col = startDayOfWeek

        // Clear all cells first
        for (r in rowIds) {
            // Clear implementation
        }

        // Fill calendar grid
        while (dayNumber <= daysInMonth && row < rowIds.size) {
            if (col < 7) {
                // Set day text
                val dayTextId = getDayTextId(row, col)
                views.setTextViewText(dayTextId, dayNumber.toString())
                dayNumber++
            }
            col++
            if (col >= 7) {
                col = 0
                row++
            }
        }
    }

    private fun getDayTextId(row: Int, col: Int): Int {
        // Return appropriate text view ID based on row and column
        // This would map to your actual layout IDs
        return R.id.calendar_day_1
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        // Clean up if needed
    }
}
