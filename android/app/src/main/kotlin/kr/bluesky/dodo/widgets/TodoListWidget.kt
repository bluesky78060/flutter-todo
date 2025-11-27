package kr.bluesky.dodo.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import kr.bluesky.dodo.R
import kr.bluesky.dodo.MainActivity

/**
 * Today's Todo List Widget
 * Displays today's incomplete tasks
 * Supports multiple themes: light, dark, transparent, blue, purple
 */
class TodoListWidget : HomeWidgetProvider() {

    companion object {
        const val THEME_LIGHT = "light"
        const val THEME_DARK = "dark"
        const val THEME_TRANSPARENT = "transparent"
        const val THEME_BLUE = "blue"
        const val THEME_PURPLE = "purple"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_todo_list).apply {
                // Get theme setting
                val theme = widgetData.getString("widget_theme", THEME_LIGHT) ?: THEME_LIGHT

                // Apply theme
                applyTheme(this, theme)

                // Get localized default strings from resources
                val defaultTitle = context.getString(R.string.widget_today_tasks)
                val defaultFooter = context.getString(R.string.widget_tap_to_view)
                val defaultTask1 = context.getString(R.string.widget_task_1)
                val defaultTask2 = context.getString(R.string.widget_task_2)
                val defaultTask3 = context.getString(R.string.widget_task_3)
                val defaultTask4 = context.getString(R.string.widget_task_4)
                val defaultTask5 = context.getString(R.string.widget_task_5)

                // Get data from Flutter via SharedPreferences (with localized defaults)
                val title = widgetData.getString("widget_title", null) ?: defaultTitle

                // Set title
                setTextViewText(R.id.widget_title, title)

                // Get todo items (5 items)
                val todo1Text = widgetData.getString("todo_1_text", null) ?: defaultTask1
                val todo1Time = widgetData.getString("todo_1_time", "") ?: ""
                val todo2Text = widgetData.getString("todo_2_text", null) ?: defaultTask2
                val todo2Time = widgetData.getString("todo_2_time", "") ?: ""
                val todo3Text = widgetData.getString("todo_3_text", null) ?: defaultTask3
                val todo3Time = widgetData.getString("todo_3_time", "") ?: ""
                val todo4Text = widgetData.getString("todo_4_text", null) ?: defaultTask4
                val todo4Time = widgetData.getString("todo_4_time", "") ?: ""
                val todo5Text = widgetData.getString("todo_5_text", null) ?: defaultTask5
                val todo5Time = widgetData.getString("todo_5_time", "") ?: ""

                // Set todo items (5 items)
                setTextViewText(R.id.widget_todo_1_text, todo1Text)
                setTextViewText(R.id.widget_todo_1_time, todo1Time)
                setTextViewText(R.id.widget_todo_2_text, todo2Text)
                setTextViewText(R.id.widget_todo_2_time, todo2Time)
                setTextViewText(R.id.widget_todo_3_text, todo3Text)
                setTextViewText(R.id.widget_todo_3_time, todo3Time)
                setTextViewText(R.id.widget_todo_4_text, todo4Text)
                setTextViewText(R.id.widget_todo_4_time, todo4Time)
                setTextViewText(R.id.widget_todo_5_text, todo5Text)
                setTextViewText(R.id.widget_todo_5_time, todo5Time)

                // Set footer text
                val footerText = widgetData.getString("footer_text", null) ?: defaultFooter
                setTextViewText(R.id.widget_footer, footerText)

                // Set click action to open the app
                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                // Make the entire widget clickable
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun applyTheme(views: RemoteViews, theme: String) {
        val (bgResId, titleColor, textColor, subTextColor) = when (theme) {
            THEME_DARK -> Quadruple(
                R.drawable.widget_background_dark,
                Color.WHITE,
                Color.parseColor("#E0E0E0"),
                Color.parseColor("#9E9E9E")
            )
            THEME_TRANSPARENT -> Quadruple(
                R.drawable.widget_background_transparent,
                Color.WHITE,
                Color.WHITE,
                Color.parseColor("#E0E0E0")
            )
            THEME_BLUE -> Quadruple(
                R.drawable.widget_background_blue,
                Color.WHITE,
                Color.parseColor("#E3F2FD"),
                Color.parseColor("#BBDEFB")
            )
            THEME_PURPLE -> Quadruple(
                R.drawable.widget_background_purple,
                Color.WHITE,
                Color.parseColor("#EDE7F6"),
                Color.parseColor("#D1C4E9")
            )
            else -> Quadruple( // THEME_LIGHT
                R.drawable.widget_background,
                Color.parseColor("#212121"),
                Color.parseColor("#212121"),
                Color.parseColor("#757575")
            )
        }

        // Apply background
        views.setInt(R.id.widget_container, "setBackgroundResource", bgResId)

        // Apply text colors
        views.setTextColor(R.id.widget_title, titleColor)
        views.setTextColor(R.id.widget_todo_1_text, textColor)
        views.setTextColor(R.id.widget_todo_2_text, textColor)
        views.setTextColor(R.id.widget_todo_3_text, textColor)
        views.setTextColor(R.id.widget_todo_4_text, textColor)
        views.setTextColor(R.id.widget_todo_5_text, textColor)
        views.setTextColor(R.id.widget_todo_1_time, subTextColor)
        views.setTextColor(R.id.widget_todo_2_time, subTextColor)
        views.setTextColor(R.id.widget_todo_3_time, subTextColor)
        views.setTextColor(R.id.widget_todo_4_time, subTextColor)
        views.setTextColor(R.id.widget_todo_5_time, subTextColor)
        views.setTextColor(R.id.widget_todo_1_checkbox, subTextColor)
        views.setTextColor(R.id.widget_todo_2_checkbox, subTextColor)
        views.setTextColor(R.id.widget_todo_3_checkbox, subTextColor)
        views.setTextColor(R.id.widget_todo_4_checkbox, subTextColor)
        views.setTextColor(R.id.widget_todo_5_checkbox, subTextColor)
        views.setTextColor(R.id.widget_footer, subTextColor)
    }

    // Helper data class for theme values
    private data class Quadruple<A, B, C, D>(val first: A, val second: B, val third: C, val fourth: D)
}
