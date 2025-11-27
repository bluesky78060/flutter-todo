package kr.bluesky.dodo.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import kr.bluesky.dodo.R
import kr.bluesky.dodo.MainActivity
import android.util.Log

/**
 * Today's Todo List Widget - Using HomeWidgetProvider (home_widget 0.8.1)
 * Features:
 * - Dark theme with rounded corners
 * - Add button to open app with add todo action
 * - Checkbox to toggle todo completion
 * - Click on todo to open app
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

        val views = RemoteViews(context.packageName, R.layout.widget_todo_list)

        // Set up Add Button click - opens app with add todo action
        val addIntent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("dodo://add-todo")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val addPendingIntent = PendingIntent.getActivity(
            context,
            1001,
            addIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_add_button, addPendingIntent)
        Log.d(TAG, "Add button click handler set")

        // Set up container click to open app
        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            context,
            1000,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_container, openAppPendingIntent)

        // Load and display todos (4 items for new design)
        try {
            for (index in 1..4) {
                val todoText = widgetData.getString("todo_${index}_text", null)
                val todoTime = widgetData.getString("todo_${index}_time", "") ?: ""
                val todoId = widgetData.getString("todo_${index}_id", "") ?: ""
                val isCompleted = widgetData.getBoolean("todo_${index}_completed", false)

                val textViewId = context.resources.getIdentifier(
                    "widget_todo_${index}_text", "id", context.packageName
                )
                val timeViewId = context.resources.getIdentifier(
                    "widget_todo_${index}_time", "id", context.packageName
                )
                val checkboxId = context.resources.getIdentifier(
                    "widget_todo_${index}_checkbox", "id", context.packageName
                )
                val containerId = context.resources.getIdentifier(
                    "widget_todo_${index}_container", "id", context.packageName
                )

                if (todoText != null && todoText.isNotEmpty()) {
                    // Show the container
                    if (containerId != 0) {
                        views.setViewVisibility(containerId, android.view.View.VISIBLE)
                    }

                    // Update text
                    if (textViewId != 0) {
                        views.setTextViewText(textViewId, todoText)
                        // Apply different color for completed items
                        if (isCompleted) {
                            views.setTextColor(textViewId, 0xFF888888.toInt())
                        } else {
                            views.setTextColor(textViewId, 0xFFFFFFFF.toInt())
                        }
                    }

                    // Update time
                    if (timeViewId != 0 && todoTime.isNotEmpty()) {
                        views.setTextViewText(timeViewId, todoTime)
                        views.setViewVisibility(timeViewId, android.view.View.VISIBLE)
                    } else if (timeViewId != 0) {
                        views.setViewVisibility(timeViewId, android.view.View.GONE)
                    }

                    // Update checkbox appearance
                    if (checkboxId != 0) {
                        if (isCompleted) {
                            views.setImageViewResource(checkboxId, R.drawable.widget_checkbox_checked)
                        } else {
                            views.setImageViewResource(checkboxId, R.drawable.widget_checkbox_unchecked)
                        }

                        // Set checkbox click handler - toggle completion via deep link
                        val toggleIntent = Intent(context, MainActivity::class.java).apply {
                            action = Intent.ACTION_VIEW
                            data = Uri.parse("dodo://toggle-todo?id=${todoId}&index=${index}")
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        }
                        val togglePendingIntent = PendingIntent.getActivity(
                            context,
                            2000 + index,
                            toggleIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        views.setOnClickPendingIntent(checkboxId, togglePendingIntent)
                    }

                    Log.d(TAG, "Updated todo $index: $todoText (time: $todoTime, completed: $isCompleted)")
                } else {
                    // Hide empty todo items
                    if (containerId != 0) {
                        views.setViewVisibility(containerId, android.view.View.GONE)
                    }
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
        super.onReceive(context, intent)
        Log.d(TAG, "Widget received broadcast: ${intent.action}")
    }
}
