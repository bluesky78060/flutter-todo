package kr.bluesky.dodo.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import kr.bluesky.dodo.R
import android.util.Log

/**
 * Today's Todo List Widget - Advanced Interactive Version
 * Uses RemoteViews with dynamic content from RemoteViewsFactory
 * Supports multiple themes and direct widget interactions
 */
class TodoListWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        Log.d(TAG, "onUpdate called for ${appWidgetIds.size} widgets")

        for (widgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, widgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        Log.d(TAG, "Updating widget $appWidgetId with RemoteViews")

        // Create the RemoteViews object with dynamic layout
        val views = RemoteViews(context.packageName, R.layout.widget_todo_list_dynamic)

        // Set up the RemoteViews for the ListView
        val intent = Intent(context, TodoListRemoteViewsService::class.java)
        views.setRemoteAdapter(R.id.widget_todo_list, intent)

        // Handle empty list
        views.setEmptyView(R.id.widget_todo_list, R.id.empty_list)

        // Update the app widget
        appWidgetManager.updateAppWidget(appWidgetId, views)

        Log.d(TAG, "Widget $appWidgetId updated with RemoteViews")
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        Log.d(TAG, "Widget received broadcast: ${intent.action}")
    }

    companion object {
        private const val TAG = "TodoListWidget"
    }
}
