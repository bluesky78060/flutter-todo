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
        const val ACTION_SELECT_DAY = "kr.bluesky.dodo.widgets.SELECT_DAY"
        const val PREF_MONTH_OFFSET = "calendar_month_offset"
        const val PREF_SELECTED_DAY = "calendar_selected_day"
        const val EXTRA_SELECTED_DAY = "selected_day"
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        when (intent.action) {
            ACTION_PREV_MONTH, ACTION_NEXT_MONTH -> {
                val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
                val currentOffset = prefs.getInt(PREF_MONTH_OFFSET, 0)
                val newOffset = if (intent.action == ACTION_PREV_MONTH) currentOffset - 1 else currentOffset + 1

                // Clear selected day when changing month
                prefs.edit()
                    .putInt(PREF_MONTH_OFFSET, newOffset)
                    .putInt(PREF_SELECTED_DAY, 0)
                    .apply()

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
            ACTION_SELECT_DAY -> {
                val selectedDay = intent.getIntExtra(EXTRA_SELECTED_DAY, 0)
                android.util.Log.d("CalendarWidget", "Day selected: $selectedDay")

                val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
                val currentSelected = prefs.getInt(PREF_SELECTED_DAY, 0)

                // Toggle selection: if same day clicked, deselect
                val newSelected = if (currentSelected == selectedDay) 0 else selectedDay
                prefs.edit().putInt(PREF_SELECTED_DAY, newSelected).apply()

                // Request widget update
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val componentName = android.content.ComponentName(context, TodoCalendarWidget::class.java)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

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
        // Get month offset and selected day from preferences
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val monthOffset = prefs.getInt(PREF_MONTH_OFFSET, 0)
        val selectedDay = prefs.getInt(PREF_SELECTED_DAY, 0)
        android.util.Log.d("CalendarWidget", "onUpdate: monthOffset = $monthOffset, selectedDay = $selectedDay")

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

                // Fill in the days and set click listeners
                for (day in 1..daysInMonth) {
                    val gridPosition = firstWeekday + day
                    val resId = context.resources.getIdentifier("calendar_day_$gridPosition", "id", context.packageName)
                    if (resId != 0) {
                        var hasTask = false
                        // For current month (offset == 0), use Flutter data which includes task indicators
                        if (monthOffset == 0) {
                            val dayKey = "calendar_day_$gridPosition"
                            var dayText = widgetData.getString(dayKey, "") ?: ""
                            // Debug log for ALL days that have task indicator
                            if (dayText.contains("●")) {
                                android.util.Log.d("CalendarWidget", "HAS TASK: day=$day, key=$dayKey, rawValue='$dayText', resId=$resId")
                                hasTask = true
                            }
                            val isHoliday = dayText.contains("★")
                            dayText = dayText.replace("★", "")

                            // Get todo title for this day (NEW: show todo text below day number)
                            val dayTodosKey = "day_todos_${displayMonth + 1}_$day"
                            val dayTodosData = widgetData.getString(dayTodosKey, "") ?: ""
                            var todoText = ""
                            var todoCount = 0
                            if (dayTodosData.isNotEmpty()) {
                                val todoItems = dayTodosData.split(";;").filter { it.isNotEmpty() }
                                todoCount = todoItems.size
                                if (todoItems.isNotEmpty()) {
                                    val firstTodo = todoItems[0].split("|")[0]
                                    // Truncate to 4 chars for compact display
                                    todoText = if (firstTodo.length > 4) firstTodo.take(4) + ".." else firstTodo
                                }
                            }

                            // Get holiday name if this day is a holiday
                            val holidayName = if (isHoliday) getHolidayName(displayYear, displayMonth + 1, day) else null

                            // Build day cell text: day number + holiday/todo text on second line
                            // Use actual day number if dayText is empty (fallback)
                            val dayNumber = dayText.replace("●", "").ifEmpty { day.toString() }
                            val cellText = when {
                                // Priority: holiday name > todo text
                                holidayName != null -> {
                                    if (todoCount > 0) {
                                        "$dayNumber\n$holidayName\n+$todoCount"
                                    } else {
                                        "$dayNumber\n$holidayName"
                                    }
                                }
                                todoText.isNotEmpty() -> {
                                    if (todoCount > 1) {
                                        "$dayNumber\n$todoText\n+${todoCount - 1}"
                                    } else {
                                        "$dayNumber\n$todoText"
                                    }
                                }
                                hasTask -> "$dayNumber●"
                                else -> dayNumber
                            }

                            // Highlight selected day
                            val finalText = if (selectedDay == day) {
                                "[$cellText]"
                            } else {
                                cellText
                            }

                            android.util.Log.d("CalendarWidget", "setTextViewText: resId=$resId, text='$finalText'")
                            setTextViewText(resId, finalText)

                            if (isHoliday && finalText.isNotEmpty()) {
                                setTextColor(resId, holidayColor)
                            }
                        } else {
                            // For other months, just show the day number
                            // Check if it's a known holiday from pre-calculated data
                            val isHoliday = holidays.contains(day) || isKnownHoliday(displayYear, displayMonth + 1, day)
                            hasTask = tasksFromFlutter.contains(day)

                            // Get holiday name for display
                            val holidayName = getHolidayName(displayYear, displayMonth + 1, day)

                            // Build cell text with holiday name
                            val cellText = when {
                                holidayName != null -> {
                                    if (hasTask) "$day\n$holidayName\n●" else "$day\n$holidayName"
                                }
                                hasTask -> "$day●"
                                else -> "$day"
                            }

                            // Highlight selected day
                            val finalText = if (selectedDay == day) {
                                "[$cellText]"
                            } else {
                                cellText
                            }

                            setTextViewText(resId, finalText)

                            if (isHoliday) {
                                setTextColor(resId, holidayColor)
                            }
                        }

                        // Set click listener for each day cell
                        val dayClickIntent = Intent(context, TodoCalendarWidget::class.java).apply {
                            action = ACTION_SELECT_DAY
                            putExtra(EXTRA_SELECTED_DAY, day)
                        }
                        val dayPendingIntent = PendingIntent.getBroadcast(
                            context,
                            200 + day, // Unique request code for each day
                            dayClickIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        setOnClickPendingIntent(resId, dayPendingIntent)
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

                // Set click action for Add Todo button - opens app with add_todo action
                val addTodoIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    action = "kr.bluesky.dodo.ADD_TODO"
                    // Pass selected day if available
                    if (selectedDay > 0) {
                        putExtra("selected_day", selectedDay)
                        putExtra("selected_month", displayMonth + 1)
                        putExtra("selected_year", displayYear)
                    }
                }
                val addTodoPendingIntent = PendingIntent.getActivity(
                    context,
                    102,
                    addTodoIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.btn_add_todo, addTodoPendingIntent)

                // Update events section (show selected day's todos or upcoming events)
                updateEventsSection(context, this, widgetData, displayYear, displayMonth + 1, theme, locale.language == "ko", selectedDay)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    /**
     * Update the events section with selected day's todos or upcoming events
     */
    private fun updateEventsSection(
        context: Context,
        views: RemoteViews,
        widgetData: SharedPreferences,
        year: Int,
        month: Int,
        theme: String,
        isKorean: Boolean,
        selectedDay: Int
    ) {
        android.util.Log.d("CalendarWidget", "updateEventsSection: selectedDay=$selectedDay")

        // Event item IDs: container, date, title, time
        data class EventViewIds(val container: Int, val date: Int, val title: Int, val time: Int)
        val eventItemIds = listOf(
            EventViewIds(R.id.event_item_1, R.id.event_1_date, R.id.event_1_title, R.id.event_1_time),
            EventViewIds(R.id.event_item_2, R.id.event_2_date, R.id.event_2_title, R.id.event_2_time),
            EventViewIds(R.id.event_item_3, R.id.event_3_date, R.id.event_3_title, R.id.event_3_time)
        )

        data class EventItem(val month: Int, val day: Int, val time: String, val title: String)
        val events = mutableListOf<EventItem>()

        // Apply theme colors
        val (headerColor, dateColor, titleColor, emptyColor) = getEventColors(theme)
        val selectedDateColor = Color.parseColor("#7B61FF") // Purple accent for selected date

        views.setTextColor(R.id.events_header, headerColor)
        views.setTextColor(R.id.events_count, dateColor)
        views.setTextColor(R.id.events_empty, emptyColor)
        views.setTextColor(R.id.selected_date_label, selectedDateColor)

        // Check if a day is selected - show that day's todos
        if (selectedDay > 0) {
            android.util.Log.d("CalendarWidget", "Loading todos for day $selectedDay")

            // Update header to show selected date
            val headerText = if (isKorean) "${selectedDay}일 할 일" else "Tasks for Day $selectedDay"
            views.setTextViewText(R.id.events_header, headerText)

            // Show selected date label
            val selectedDateText = if (isKorean) "${month}월 ${selectedDay}일" else "$month/$selectedDay"
            views.setTextViewText(R.id.selected_date_label, selectedDateText)
            views.setViewVisibility(R.id.selected_date_label, android.view.View.VISIBLE)

            // Get todos for the selected day from SharedPreferences
            // Format: "day_todos_17" = "title1|time1;;title2|time2;;title3|time3"
            val dayTodosKey = "day_todos_${month}_$selectedDay"
            val dayTodosData = widgetData.getString(dayTodosKey, "") ?: ""
            android.util.Log.d("CalendarWidget", "Day todos key: $dayTodosKey, data: $dayTodosData")

            if (dayTodosData.isNotEmpty()) {
                val todoItems = dayTodosData.split(";;")
                for (item in todoItems) {
                    if (item.isNotEmpty()) {
                        val parts = item.split("|", limit = 2)
                        val title = parts.getOrNull(0) ?: ""
                        val time = parts.getOrNull(1) ?: ""
                        if (title.isNotEmpty()) {
                            events.add(EventItem(month, selectedDay, time, title))
                        }
                    }
                }
            }

            android.util.Log.d("CalendarWidget", "Found ${events.size} todos for day $selectedDay")
        } else {
            // No day selected - show upcoming events
            views.setViewVisibility(R.id.selected_date_label, android.view.View.GONE)

            // Update header text
            val headerText = if (isKorean) "다가오는 이벤트" else "Upcoming Events"
            views.setTextViewText(R.id.events_header, headerText)

            // Get upcoming events from SharedPreferences
            // Format: "upcoming_event_1" = "10|15|14:00|회의"
            val allKeys = widgetData.all.keys.filter { it.contains("upcoming") }
            android.util.Log.d("CalendarWidget", "Upcoming event keys in prefs: $allKeys")

            for (i in 1..5) {
                val eventKey = "upcoming_event_$i"
                val eventData = widgetData.getString(eventKey, null)
                if (!eventData.isNullOrEmpty() && eventData.contains("|")) {
                    val parts = eventData.split("|", limit = 4)
                    val eventMonth = parts[0].toIntOrNull()
                    val eventDay = parts.getOrNull(1)?.toIntOrNull()
                    val time = parts.getOrNull(2) ?: ""
                    val title = parts.getOrNull(3) ?: ""
                    if (eventMonth != null && eventDay != null && title.isNotEmpty()) {
                        events.add(EventItem(eventMonth, eventDay, time, title))
                    }
                }
            }
        }

        android.util.Log.d("CalendarWidget", "Total events to display: ${events.size}")

        if (events.isEmpty()) {
            // Show empty message
            views.setViewVisibility(R.id.events_empty, android.view.View.VISIBLE)
            val emptyText = if (selectedDay > 0) {
                if (isKorean) "할 일이 없습니다" else "No tasks"
            } else {
                if (isKorean) "일정이 없습니다" else "No events"
            }
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

                    // For selected day view, show simpler date or hide date box
                    if (selectedDay > 0) {
                        // Show just time or "·" as bullet
                        val dateText = if (event.time.isNotEmpty()) {
                            formatTimeString(event.time, isKorean)
                        } else {
                            "•"
                        }
                        views.setTextViewText(eventIds.date, dateText)
                    } else {
                        // Show date as "10월 15\n14:00" style (date on top, time below)
                        val monthStr = if (isKorean) "${event.month}월" else getMonthAbbr(event.month)
                        val timeStr = if (event.time.isNotEmpty()) {
                            "\n${formatTimeString(event.time, isKorean)}"
                        } else {
                            ""
                        }
                        val dateText = "$monthStr ${event.day}$timeStr"
                        views.setTextViewText(eventIds.date, dateText)
                    }

                    // Show title
                    views.setTextViewText(eventIds.title, event.title)

                    // Show time (hidden for upcoming events since it's now in date box)
                    val timeText = if (selectedDay > 0) {
                        // For selected day, time is already shown in date box
                        ""
                    } else {
                        // For upcoming events, time is now shown in date box
                        // Show "All day" only if no time specified
                        if (event.time.isEmpty()) {
                            if (isKorean) "하루 종일" else "All day"
                        } else {
                            ""
                        }
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
        return getHolidayName(year, month, day) != null
    }

    /**
     * Get Korean holiday name for a given date.
     * Returns short name (2-3 chars) for display in calendar cells.
     */
    private fun getHolidayName(year: Int, month: Int, day: Int): String? {
        // Fixed holidays (양력)
        val fixedHolidays = mapOf(
            Pair(1, 1) to "신정",
            Pair(3, 1) to "삼일절",
            Pair(5, 5) to "어린이",
            Pair(6, 6) to "현충일",
            Pair(8, 15) to "광복절",
            Pair(10, 3) to "개천절",
            Pair(10, 9) to "한글날",
            Pair(12, 25) to "성탄절"
        )

        fixedHolidays[Pair(month, day)]?.let { return it }

        // Lunar holidays for specific years (pre-calculated)
        val lunarHolidays2025 = mapOf(
            Pair(1, 28) to "설날",
            Pair(1, 29) to "설날",
            Pair(1, 30) to "설날",
            Pair(5, 5) to "석가탄",
            Pair(5, 6) to "대체",
            Pair(10, 5) to "추석",
            Pair(10, 6) to "추석",
            Pair(10, 7) to "추석",
            Pair(10, 8) to "대체"
        )

        val lunarHolidays2026 = mapOf(
            Pair(2, 16) to "설날",
            Pair(2, 17) to "설날",
            Pair(2, 18) to "설날",
            Pair(5, 24) to "석가탄",
            Pair(5, 25) to "대체",
            Pair(9, 24) to "추석",
            Pair(9, 25) to "추석",
            Pair(9, 26) to "추석"
        )

        return when (year) {
            2025 -> lunarHolidays2025[Pair(month, day)]
            2026 -> lunarHolidays2026[Pair(month, day)]
            else -> null
        }
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
