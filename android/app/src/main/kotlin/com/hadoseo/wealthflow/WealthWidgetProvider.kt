package com.hadoseo.wealthflow

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.res.Configuration
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class WealthWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = launchIntent?.let {
            PendingIntent.getActivity(
                context,
                0,
                it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        val isDark = if (widgetData.contains("is_dark_mode")) {
            widgetData.getBoolean("is_dark_mode", true)
        } else {
            val nightModeFlags = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
            nightModeFlags == Configuration.UI_MODE_NIGHT_YES
        }

        val layoutId = if (isDark) R.layout.wealth_widget else R.layout.wealth_widget_light

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, layoutId).apply {
                val totalWealth = widgetData.getString("total_wealth", "₩ 0")
                val percent = widgetData.getString("progress_percent", "은퇴 달성률 0.0%")
                setTextViewText(R.id.widget_total_wealth, totalWealth)
                setTextViewText(R.id.widget_percent, percent)

                if (pendingIntent != null) {
                    setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                }
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
