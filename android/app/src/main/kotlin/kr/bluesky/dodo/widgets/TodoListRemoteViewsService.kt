package kr.bluesky.dodo.widgets

import android.content.Intent
import android.widget.RemoteViewsService

/**
 * RemoteViewsService for dynamic todo list widget
 * Provides data to the ListView in the widget
 */
class TodoListRemoteViewsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return TodoListRemoteViewsFactory(applicationContext, intent)
    }
}
