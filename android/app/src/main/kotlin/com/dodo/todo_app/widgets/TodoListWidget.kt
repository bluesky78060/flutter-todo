package com.dodo.todo_app.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.time.LocalDate
import java.time.format.DateTimeFormatter

/**
 * Today's Todo List Widget
 * Displays today's incomplete tasks with quick actions
 */
class TodoListWidget : HomeWidgetProvider() {
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
        val views = RemoteViews(context.packageName, R.layout.widget_todo_list)

        // Extract data from widget data map
        val viewType = widgetData["view_type"] as? String ?: "none"

        if (viewType == "none") {
            // Widget disabled
            views.setTextViewText(
                R.id.widget_title,
                context.getString(R.string.widget_disabled)
            )
            appWidgetManager.updateAppWidget(appWidgetId, views)
            return
        }

        // Get today's date
        val today = LocalDate.now()
        val dateFormatter = DateTimeFormatter.ofPattern("MMM dd, yyyy")
        val dateString = today.format(dateFormatter)

        views.setTextViewText(
            R.id.widget_title,
            "Today - $dateString"
        )

        // Update widget with current data
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        // Clean up if needed
    }
}
