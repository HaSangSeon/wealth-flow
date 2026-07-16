package com.hadoseo.wealthflow

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class WealthWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.wealth_widget).apply {
                val totalWealth = widgetData.getString("total_wealth", "₩ 0")
                val percent = widgetData.getString("progress_percent", "은퇴 달성률 0.0%")
                setTextViewText(R.id.widget_total_wealth, totalWealth)
                setTextViewText(R.id.widget_percent, percent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
