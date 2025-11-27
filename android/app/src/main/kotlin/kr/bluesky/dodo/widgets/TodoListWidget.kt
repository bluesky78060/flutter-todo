package kr.bluesky.dodo.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import kr.bluesky.dodo.R
import android.util.Log

/**
 * Today's Todo List Widget - Using HomeWidgetProvider (home_widget 0.8.1)
 * Updates widget with top 5 pending todos from SharedPreferences
 * Supports multiple themes and direct widget interactions
 */
class TodoListWidget : HomeWidgetProvider() {

    companion object {
        private const val TAG = "TodoListWidget"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        Log.d(TAG, "onUpdate called for ${appWidgetIds.size} widgets with HomeWidgetProvider")

        appWidgetIds.forEach { widgetId ->
            updateAppWidget(context, appWidgetManager, widgetId, widgetData)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        widgetData: SharedPreferences
    ) {
        Log.d(TAG, "Updating widget $appWidgetId")

        // Create the RemoteViews object with static layout
        val views = RemoteViews(context.packageName, R.layout.widget_todo_list)

        // Load and display top 5 todos from widgetData (provided by home_widget)
        try {
            // Load and display top 5 todos
            for (index in 1..5) {
                val todoText = widgetData.getString("todo_${index}_text", null)
                val todoTime = widgetData.getString("todo_${index}_time", "") ?: ""

                if (todoText != null && todoText.isNotEmpty()) {
                    // Update text
                    val textViewId = context.resources.getIdentifier(
                        "widget_todo_${index}_text", "id", context.packageName
                    )
                    if (textViewId != 0) {
                        views.setTextViewText(textViewId, todoText)
                    }

                    // Update time if available
                    if (todoTime.isNotEmpty()) {
                        val timeViewId = context.resources.getIdentifier(
                            "widget_todo_${index}_time", "id", context.packageName
                        )
                        if (timeViewId != 0) {
                            views.setTextViewText(timeViewId, todoTime)
                        }
                    }

                    Log.d(TAG, "Updated todo $index: $todoText (time: $todoTime)")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error loading todo data", e)
        }

        // Update the app widget
        appWidgetManager.updateAppWidget(appWidgetId, views)

        Log.d(TAG, "Widget $appWidgetId updated successfully")
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)  // ← Important: Call super to let home_widget handle broadcasts
        Log.d(TAG, "Widget received broadcast: ${intent.action}")
    }
}
