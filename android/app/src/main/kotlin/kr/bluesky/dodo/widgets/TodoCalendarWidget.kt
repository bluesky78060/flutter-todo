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
import java.text.SimpleDateFormat
import java.util.*

/**
 * Calendar Widget
 * Displays this month's calendar with task indicators
 * Supports multiple themes: light, dark, transparent, blue, purple
 * Supports month navigation with prev/next buttons
 */
class TodoCalendarWidget : HomeWidgetProvider() {

    companion object {
        const val THEME_LIGHT = "light"
        const val THEME_DARK = "dark"
        const val THEME_TRANSPARENT = "transparent"
        const val THEME_BLUE = "blue"
        const val THEME_PURPLE = "purple"

        const val ACTION_PREV_MONTH = "kr.bluesky.dodo.widgets.PREV_MONTH"
        const val ACTION_NEXT_MONTH = "kr.bluesky.dodo.widgets.NEXT_MONTH"
        const val PREF_MONTH_OFFSET = "calendar_month_offset"
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        when (intent.action) {
            ACTION_PREV_MONTH, ACTION_NEXT_MONTH -> {
                val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
                val currentOffset = prefs.getInt(PREF_MONTH_OFFSET, 0)
                val newOffset = if (intent.action == ACTION_PREV_MONTH) currentOffset - 1 else currentOffset + 1

                prefs.edit().putInt(PREF_MONTH_OFFSET, newOffset).apply()

                // Request widget update
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val componentName = android.content.ComponentName(context, TodoCalendarWidget::class.java)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

                // Trigger onUpdate
                val updateIntent = Intent(context, TodoCalendarWidget::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
                }
                context.sendBroadcast(updateIntent)
            }
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        // Get month offset from preferences
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val monthOffset = prefs.getInt(PREF_MONTH_OFFSET, 0)
        android.util.Log.d("CalendarWidget", "onUpdate: monthOffset = $monthOffset")

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_calendar).apply {
                // Get theme setting
                val theme = widgetData.getString("calendar_theme", THEME_LIGHT) ?: THEME_LIGHT

                // Apply theme
                applyTheme(context, this, theme)

                // Calculate the display month based on offset
                val calendar = Calendar.getInstance()
                calendar.add(Calendar.MONTH, monthOffset)
                val displayYear = calendar.get(Calendar.YEAR)
                val displayMonth = calendar.get(Calendar.MONTH) // 0-indexed

                val locale = context.resources.configuration.locales[0]
                val title = if (locale.language == "ko") {
                    SimpleDateFormat("yyyy년 M월", Locale.KOREAN).format(calendar.time)
                } else {
                    SimpleDateFormat("MMMM yyyy", Locale.ENGLISH).format(calendar.time)
                }

                // Set calendar title
                setTextViewText(R.id.calendar_title, title)

                // Apply nav button colors based on theme
                val navColor = getNavButtonColor(theme)
                setTextColor(R.id.btn_prev_month, navColor)
                setTextColor(R.id.btn_next_month, navColor)

                // Get holiday color based on current theme
                val holidayColor = getHolidayColor(theme)

                // Calculate calendar grid for the display month
                val firstDayOfMonth = Calendar.getInstance().apply {
                    set(Calendar.YEAR, displayYear)
                    set(Calendar.MONTH, displayMonth)
                    set(Calendar.DAY_OF_MONTH, 1)
                }
                val daysInMonth = firstDayOfMonth.getActualMaximum(Calendar.DAY_OF_MONTH)

                // Get first weekday (Sunday = 1, Saturday = 7 in Calendar)
                // Convert to 0-indexed (Sunday = 0)
                val firstWeekday = firstDayOfMonth.get(Calendar.DAY_OF_WEEK) - 1 // 0=Sun, 6=Sat

                // Get holidays from Flutter data (format: "3,9,25" for days 3, 9, 25)
                val holidaysKey = "calendar_holidays_${displayYear}_${displayMonth + 1}"
                val defaultHolidaysKey = "calendar_holidays"
                val holidaysStr = if (monthOffset == 0) {
                    widgetData.getString(defaultHolidaysKey, "") ?: ""
                } else {
                    widgetData.getString(holidaysKey, "") ?: ""
                }
                val holidays = holidaysStr.split(",").mapNotNull { it.trim().toIntOrNull() }.toSet()

                // Get tasks from Flutter data
                val tasksKey = "calendar_tasks_${displayYear}_${displayMonth + 1}"
                val tasksStr = widgetData.getString(tasksKey, "") ?: ""
                val tasksFromFlutter = tasksStr.split(",").mapNotNull { it.trim().toIntOrNull() }.toSet()

                // For current month, use the existing calendar_day_X data
                // For other months, we need to generate the grid ourselves

                // Clear all 42 cells first
                for (i in 1..42) {
                    val resId = context.resources.getIdentifier("calendar_day_$i", "id", context.packageName)
                    if (resId != 0) {
                        setTextViewText(resId, "")
                    }
                }

                // Fill in the days
                for (day in 1..daysInMonth) {
                    val gridPosition = firstWeekday + day
                    val resId = context.resources.getIdentifier("calendar_day_$gridPosition", "id", context.packageName)
                    if (resId != 0) {
                        // For current month (offset == 0), use Flutter data which includes task indicators
                        if (monthOffset == 0) {
                            val dayKey = "calendar_day_$gridPosition"
                            var dayText = widgetData.getString(dayKey, "") ?: ""
                            // Debug log for ALL days that have task indicator
                            if (dayText.contains("●")) {
                                android.util.Log.d("CalendarWidget", "HAS TASK: day=$day, key=$dayKey, rawValue='$dayText', resId=$resId")
                            }
                            val isHoliday = dayText.contains("★")
                            dayText = dayText.replace("★", "")

                            // Log setTextViewText call
                            android.util.Log.d("CalendarWidget", "setTextViewText: resId=$resId, text='$dayText'")
                            setTextViewText(resId, dayText)

                            if (isHoliday && dayText.isNotEmpty()) {
                                setTextColor(resId, holidayColor)
                            }
                        } else {
                            // For other months, just show the day number
                            // Check if it's a known holiday from pre-calculated data
                            val isHoliday = holidays.contains(day) || isKnownHoliday(displayYear, displayMonth + 1, day)
                            val hasTask = tasksFromFlutter.contains(day)
                            val dayText = if (hasTask) "$day●" else "$day"
                            setTextViewText(resId, dayText)

                            if (isHoliday) {
                                setTextColor(resId, holidayColor)
                            }
                        }
                    }
                }

                // Set up navigation button click actions
                val prevIntent = Intent(context, TodoCalendarWidget::class.java).apply {
                    action = ACTION_PREV_MONTH
                }
                val prevPendingIntent = PendingIntent.getBroadcast(
                    context,
                    100,
                    prevIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.btn_prev_month, prevPendingIntent)

                val nextIntent = Intent(context, TodoCalendarWidget::class.java).apply {
                    action = ACTION_NEXT_MONTH
                }
                val nextPendingIntent = PendingIntent.getBroadcast(
                    context,
                    101,
                    nextIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.btn_next_month, nextPendingIntent)

                // Set click action to open the app (on title area)
                val appIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val appPendingIntent = PendingIntent.getActivity(
                    context,
                    1,
                    appIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.calendar_title, appPendingIntent)

                // Update events section
                updateEventsSection(context, this, widgetData, displayYear, displayMonth + 1, theme, locale.language == "ko")
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    /**
     * Update the events section with upcoming todos (across all months)
     */
    private fun updateEventsSection(
        context: Context,
        views: RemoteViews,
        widgetData: SharedPreferences,
        year: Int,
        month: Int,
        theme: String,
        isKorean: Boolean
    ) {
        android.util.Log.d("CalendarWidget", "updateEventsSection: loading upcoming events")

        // Event item IDs: container, date, title, time
        data class EventViewIds(val container: Int, val date: Int, val title: Int, val time: Int)
        val eventItemIds = listOf(
            EventViewIds(R.id.event_item_1, R.id.event_1_date, R.id.event_1_title, R.id.event_1_time),
            EventViewIds(R.id.event_item_2, R.id.event_2_date, R.id.event_2_title, R.id.event_2_time),
            EventViewIds(R.id.event_item_3, R.id.event_3_date, R.id.event_3_title, R.id.event_3_time)
        )

        // Get upcoming events from SharedPreferences
        // Format: "upcoming_event_1" = "10|15|14:00|회의", "upcoming_event_2" = "11|3||프로젝트 마감"
        data class EventItem(val month: Int, val day: Int, val time: String, val title: String)
        val events = mutableListOf<EventItem>()

        // Debug: Log all keys in SharedPreferences
        val allKeys = widgetData.all.keys.filter { it.contains("upcoming") }
        android.util.Log.d("CalendarWidget", "Upcoming event keys in prefs: $allKeys")

        for (i in 1..5) {
            val eventKey = "upcoming_event_$i"
            val eventData = widgetData.getString(eventKey, null)
            android.util.Log.d("CalendarWidget", "Checking $eventKey = $eventData")
            // Check for both null and empty string (Flutter saves "" to clear events)
            if (!eventData.isNullOrEmpty() && eventData.contains("|")) {
                val parts = eventData.split("|", limit = 4)
                val eventMonth = parts[0].toIntOrNull()
                val eventDay = parts.getOrNull(1)?.toIntOrNull()
                val time = parts.getOrNull(2) ?: ""
                val title = parts.getOrNull(3) ?: ""
                if (eventMonth != null && eventDay != null && title.isNotEmpty()) {
                    events.add(EventItem(eventMonth, eventDay, time, title))
                    android.util.Log.d("CalendarWidget", "Added upcoming event: month=$eventMonth, day=$eventDay, time=$time, title=$title")
                }
            }
        }

        android.util.Log.d("CalendarWidget", "Total upcoming events found: ${events.size}")

        // Apply theme colors
        val (headerColor, dateColor, titleColor, emptyColor) = getEventColors(theme)

        views.setTextColor(R.id.events_header, headerColor)
        views.setTextColor(R.id.events_count, dateColor)
        views.setTextColor(R.id.events_empty, emptyColor)

        // Update header text
        val headerText = if (isKorean) "다가오는 이벤트" else "Upcoming Events"
        views.setTextViewText(R.id.events_header, headerText)

        if (events.isEmpty()) {
            // Show empty message
            views.setViewVisibility(R.id.events_empty, android.view.View.VISIBLE)
            val emptyText = if (isKorean) "일정이 없습니다" else "No events"
            views.setTextViewText(R.id.events_empty, emptyText)
            views.setTextViewText(R.id.events_count, "")

            // Hide all event items
            eventItemIds.forEach { eventIds ->
                views.setViewVisibility(eventIds.container, android.view.View.GONE)
            }
        } else {
            views.setViewVisibility(R.id.events_empty, android.view.View.GONE)

            // Show event count
            val countText = "${events.size}${if (isKorean) "개" else ""}"
            views.setTextViewText(R.id.events_count, countText)

            // Show up to 3 events
            val displayEvents = events.take(3)
            val timeColor = getTimeColor(theme)
            eventItemIds.forEachIndexed { index, eventIds ->
                if (index < displayEvents.size) {
                    val event = displayEvents[index]
                    views.setViewVisibility(eventIds.container, android.view.View.VISIBLE)

                    // Show date as "10월\n15" style (month on top, day below)
                    val monthStr = if (isKorean) "${event.month}월" else getMonthAbbr(event.month)
                    val dateText = "$monthStr\n${event.day}"
                    views.setTextViewText(eventIds.date, dateText)

                    // Show title (13sp, bold) and time (11sp) in separate TextViews
                    views.setTextViewText(eventIds.title, event.title)

                    val timeText = if (event.time.isNotEmpty()) {
                        formatTimeString(event.time, isKorean)
                    } else {
                        if (isKorean) "하루 종일" else "All day"
                    }
                    views.setTextViewText(eventIds.time, timeText)

                    views.setTextColor(eventIds.date, dateColor)
                    views.setTextColor(eventIds.title, titleColor)
                    views.setTextColor(eventIds.time, timeColor)
                } else {
                    views.setViewVisibility(eventIds.container, android.view.View.GONE)
                }
            }

        }
    }

    /**
     * Get event section colors based on theme
     */
    private fun getEventColors(theme: String): List<Int> {
        return when (theme) {
            THEME_DARK -> listOf(
                Color.parseColor("#BBBBBB"), // header
                Color.parseColor("#1565C0"), // date - dark blue for visibility on light bg box
                Color.WHITE,                 // title - white for better visibility
                Color.parseColor("#666666")  // empty
            )
            THEME_TRANSPARENT -> listOf(
                Color.parseColor("#EEEEEE"), // header - light for dark bg wallpaper
                Color.WHITE,                 // date - white for better visibility on dark bg
                Color.WHITE,                 // title - white for dark bg visibility
                Color.parseColor("#AAAAAA")  // empty
            )
            THEME_BLUE -> listOf(
                Color.parseColor("#BBDEFB"),
                Color.parseColor("#90CAF9"),
                Color.WHITE,                 // title - white for better visibility
                Color.parseColor("#64B5F6")
            )
            THEME_PURPLE -> listOf(
                Color.parseColor("#D1C4E9"),
                Color.parseColor("#B39DDB"),
                Color.WHITE,                 // title - white for better visibility
                Color.parseColor("#9575CD")
            )
            else -> listOf( // THEME_LIGHT
                Color.parseColor("#757575"),
                Color.parseColor("#1976D2"),
                Color.parseColor("#424242"),
                Color.parseColor("#9E9E9E")
            )
        }
    }

    /**
     * Get time text color based on theme
     */
    private fun getTimeColor(theme: String): Int {
        return when (theme) {
            THEME_DARK -> Color.parseColor("#CCCCCC") // light gray for dark theme
            THEME_TRANSPARENT -> Color.parseColor("#CCCCCC") // light gray for dark bg wallpaper
            THEME_BLUE -> Color.parseColor("#E3F2FD") // light blue for blue theme
            THEME_PURPLE -> Color.parseColor("#EDE7F6") // light purple for purple theme
            else -> Color.parseColor("#757575") // THEME_LIGHT
        }
    }

    private fun getNavButtonColor(theme: String): Int {
        return when (theme) {
            THEME_DARK, THEME_TRANSPARENT, THEME_BLUE, THEME_PURPLE ->
                Color.WHITE
            else ->
                Color.parseColor("#424242")
        }
    }

    private fun getHolidayColor(theme: String): Int {
        return when (theme) {
            THEME_DARK, THEME_TRANSPARENT, THEME_BLUE, THEME_PURPLE ->
                Color.parseColor("#EF5350")
            else ->
                Color.parseColor("#E53935")
        }
    }

    /**
     * Check if a day is a known Korean holiday
     * This is a fallback for months where Flutter hasn't provided holiday data
     */
    private fun isKnownHoliday(year: Int, month: Int, day: Int): Boolean {
        // Fixed holidays (양력)
        val fixedHolidays = setOf(
            Pair(1, 1),   // 신정
            Pair(3, 1),   // 삼일절
            Pair(5, 5),   // 어린이날
            Pair(6, 6),   // 현충일
            Pair(8, 15),  // 광복절
            Pair(10, 3),  // 개천절
            Pair(10, 9),  // 한글날
            Pair(12, 25)  // 성탄절
        )

        if (fixedHolidays.contains(Pair(month, day))) {
            return true
        }

        // Lunar holidays for specific years (pre-calculated)
        val lunarHolidays = mapOf(
            2025 to setOf(
                Pair(1, 28), Pair(1, 29), Pair(1, 30), // 설날
                Pair(5, 5), Pair(5, 6), // 부처님오신날 + 대체공휴일
                Pair(10, 5), Pair(10, 6), Pair(10, 7), Pair(10, 8) // 추석
            ),
            2026 to setOf(
                Pair(2, 16), Pair(2, 17), Pair(2, 18), // 설날
                Pair(5, 24), Pair(5, 25), // 부처님오신날
                Pair(9, 24), Pair(9, 25), Pair(9, 26) // 추석
            )
        )

        return lunarHolidays[year]?.contains(Pair(month, day)) == true
    }

    /**
     * Get month abbreviation for English
     */
    private fun getMonthAbbr(month: Int): String {
        return when (month) {
            1 -> "Jan"
            2 -> "Feb"
            3 -> "Mar"
            4 -> "Apr"
            5 -> "May"
            6 -> "Jun"
            7 -> "Jul"
            8 -> "Aug"
            9 -> "Sep"
            10 -> "Oct"
            11 -> "Nov"
            12 -> "Dec"
            else -> "$month"
        }
    }

    /**
     * Format time string to localized format
     * "14:00" -> "오후 2:00" (Korean) or "2:00 PM" (English)
     */
    private fun formatTimeString(time: String, isKorean: Boolean): String {
        try {
            val parts = time.split(":")
            if (parts.size != 2) return time

            val hour = parts[0].toIntOrNull() ?: return time
            val minute = parts[1]

            val hour12 = when {
                hour == 0 -> 12
                hour > 12 -> hour - 12
                else -> hour
            }
            val period = if (hour < 12) {
                if (isKorean) "오전" else "AM"
            } else {
                if (isKorean) "오후" else "PM"
            }

            return if (isKorean) {
                "$period $hour12:$minute"
            } else {
                "$hour12:$minute $period"
            }
        } catch (e: Exception) {
            return time
        }
    }

    private fun applyTheme(context: Context, views: RemoteViews, theme: String) {
        data class ThemeColors(
            val bgResId: Int,
            val titleColor: Int,
            val textColor: Int,
            val weekdayColor: Int,
            val saturdayColor: Int,
            val sundayColor: Int
        )

        val colors = when (theme) {
            THEME_DARK -> ThemeColors(
                R.drawable.widget_background_dark,
                Color.WHITE,
                Color.parseColor("#E0E0E0"),
                Color.parseColor("#BDBDBD"),
                Color.parseColor("#64B5F6"),
                Color.parseColor("#EF5350")
            )
            THEME_TRANSPARENT -> ThemeColors(
                R.drawable.widget_background_transparent,
                Color.WHITE,
                Color.WHITE,
                Color.parseColor("#E0E0E0"),
                Color.parseColor("#64B5F6"),
                Color.parseColor("#EF5350")
            )
            THEME_BLUE -> ThemeColors(
                R.drawable.widget_background_blue,
                Color.WHITE,
                Color.parseColor("#E3F2FD"),
                Color.parseColor("#BBDEFB"),
                Color.parseColor("#90CAF9"),
                Color.parseColor("#EF5350")
            )
            THEME_PURPLE -> ThemeColors(
                R.drawable.widget_background_purple,
                Color.WHITE,
                Color.parseColor("#EDE7F6"),
                Color.parseColor("#D1C4E9"),
                Color.parseColor("#64B5F6"),
                Color.parseColor("#EF5350")
            )
            else -> ThemeColors(
                R.drawable.widget_background,
                Color.parseColor("#212121"),
                Color.parseColor("#212121"),
                Color.parseColor("#424242"),
                Color.parseColor("#1976D2"),
                Color.parseColor("#E53935")
            )
        }

        views.setInt(R.id.calendar_container, "setBackgroundResource", colors.bgResId)
        views.setTextColor(R.id.calendar_title, colors.titleColor)

        views.setTextColor(R.id.calendar_day_mon, colors.weekdayColor)
        views.setTextColor(R.id.calendar_day_tue, colors.weekdayColor)
        views.setTextColor(R.id.calendar_day_wed, colors.weekdayColor)
        views.setTextColor(R.id.calendar_day_thu, colors.weekdayColor)
        views.setTextColor(R.id.calendar_day_fri, colors.weekdayColor)
        views.setTextColor(R.id.calendar_day_sat, colors.saturdayColor)
        views.setTextColor(R.id.calendar_day_sun, colors.sundayColor)

        for (i in 1..42) {
            val resId = context.resources.getIdentifier("calendar_day_$i", "id", context.packageName)
            if (resId != 0) {
                val dayColor = when {
                    i % 7 == 1 -> colors.sundayColor
                    i % 7 == 0 -> colors.saturdayColor
                    else -> colors.textColor
                }
                views.setTextColor(resId, dayColor)
            }
        }
    }
}
