package com.levelup.levelup

import android.appwidget.AppWidgetManager
import android.content.Context
import es.antonborri.home_widget.HomeWidgetProvider
import android.content.SharedPreferences

class HunterStatusWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        // No-op: HomeWidget updates are triggered from Flutter via saveWidgetData/updateWidget.
        // Keeping an override is required for newer home_widget versions.
    }
}

