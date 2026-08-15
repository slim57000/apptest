package com.habitudeplus.habit_tracker

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject

/// Widget écran d'accueil en lecture seule (v1) : affiche jusqu'à 4
/// habitudes du jour et le compteur "faites / prévues". Un tap ouvre
/// l'app -- pas de coche directement depuis le widget pour l'instant.
class HabitWidgetProvider : AppWidgetProvider() {
    companion object {
        const val PREFS_NAME = "widget_data"
        const val PREFS_KEY = "habits_json"
        private val ROW_IDS = intArrayOf(
            R.id.widget_row_1,
            R.id.widget_row_2,
            R.id.widget_row_3,
            R.id.widget_row_4,
        )

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, HabitWidgetProvider::class.java))
            if (ids.isNotEmpty()) {
                val intent = Intent(context, HabitWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                }
                context.sendBroadcast(intent)
            }
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val json = prefs.getString(PREFS_KEY, null)

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.habit_widget)

            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?: Intent(context, HabitWidgetProvider::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            if (json == null) {
                views.setTextViewText(R.id.widget_header, "Habitude+")
                for (rowId in ROW_IDS) {
                    views.setViewVisibility(rowId, View.GONE)
                }
            } else {
                val data = JSONObject(json)
                val doneCount = data.optInt("doneCount", 0)
                val activeCount = data.optInt("activeCount", 0)
                views.setTextViewText(R.id.widget_header, "$doneCount/$activeCount aujourd'hui")

                val rows = data.optJSONArray("rows")
                for ((index, rowId) in ROW_IDS.withIndex()) {
                    if (rows != null && index < rows.length()) {
                        val row = rows.getJSONObject(index)
                        val emoji = row.optString("emoji", "")
                        val name = row.optString("name", "")
                        val done = row.optBoolean("done", false)
                        val mark = if (done) "✓" else "○"
                        views.setTextViewText(rowId, "$mark $emoji $name")
                        views.setViewVisibility(rowId, View.VISIBLE)
                    } else {
                        views.setViewVisibility(rowId, View.GONE)
                    }
                }
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
