package com.habitudeplus.habit_tracker

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import java.util.Calendar
import java.util.Locale
import org.json.JSONArray
import org.json.JSONObject

/// Widget écran d'accueil : affiche jusqu'à 4 habitudes du jour et le
/// compteur "faites / prévues". Un tap sur une ligne coche/décoche
/// l'habitude sans ouvrir l'app ; un tap ailleurs ouvre l'app.
///
/// Le tap-pour-cocher écrit *directement* dans le fichier de préférences
/// utilisé par le plugin `shared_preferences` (nom de fichier et préfixe de
/// clé documentés et stables de ce plugin Flutter officiel -- pas un détail
/// interne non documenté), sous le même format JSON que `Habit.toJson()` /
/// `fromJson()` côté Dart. Uniquement le champ `completedDates` de
/// l'habitude ciblée est modifié, jamais le reste de l'objet, et toute
/// exception de parsing abandonne sans rien écrire (voir [toggleHabit]) --
/// pour ne jamais risquer de corrompre les données de l'utilisateur.
///
/// Limite connue : si l'app est déjà ouverte (au premier plan ou juste en
/// arrière-plan sans avoir été tuée) au moment du tap sur le widget, l'état
/// en mémoire de `HabitsProvider` ne voit pas ce changement tant que l'app
/// n'a pas rechargé depuis le stockage -- voir `HabitsProvider.reload()`,
/// appelé au retour au premier plan (`app.dart`).
class HabitWidgetProvider : AppWidgetProvider() {
    companion object {
        const val PREFS_NAME = "widget_data"
        const val PREFS_KEY = "habits_json"

        private const val FLUTTER_PREFS_NAME = "FlutterSharedPreferences"
        private const val HABITS_KEY = "flutter.habits_v1"
        private const val ACTION_TOGGLE = "com.habitudeplus.habit_tracker.TOGGLE_HABIT"
        private const val EXTRA_HABIT_ID = "habit_id"
        private const val TAG = "HabitWidgetProvider"

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

        private fun todayKey(): String {
            val cal = Calendar.getInstance()
            return String.format(
                Locale.US,
                "%04d-%02d-%02d",
                cal.get(Calendar.YEAR),
                cal.get(Calendar.MONTH) + 1,
                cal.get(Calendar.DAY_OF_MONTH),
            )
        }

        /// Bascule la complétion du jour pour [habitId] dans le stockage
        /// partagé avec l'app Flutter, puis met à jour le cache d'affichage
        /// du widget en conséquence. N'écrit rien si le JSON existant ne
        /// peut pas être analysé, ou si aucune habitude ne correspond.
        private fun toggleHabit(context: Context, habitId: String?) {
            if (habitId == null) return
            try {
                val flutterPrefs = context.getSharedPreferences(FLUTTER_PREFS_NAME, Context.MODE_PRIVATE)
                val raw = flutterPrefs.getString(HABITS_KEY, null) ?: return
                val habits = JSONArray(raw)
                val today = todayKey()
                var found = false
                var nowDone = false

                for (i in 0 until habits.length()) {
                    val habit = habits.getJSONObject(i)
                    if (habit.optString("id") != habitId) continue
                    found = true

                    val existing = habit.optJSONArray("completedDates") ?: JSONArray()
                    val updated = JSONArray()
                    var removed = false
                    for (j in 0 until existing.length()) {
                        val date = existing.getString(j)
                        if (date == today) {
                            removed = true
                        } else {
                            updated.put(date)
                        }
                    }
                    if (!removed) updated.put(today)
                    habit.put("completedDates", updated)
                    nowDone = !removed
                    break
                }

                if (!found) return
                flutterPrefs.edit().putString(HABITS_KEY, habits.toString()).apply()
                updateWidgetCache(context, habitId, nowDone)
            } catch (e: Exception) {
                // Ne jamais écrire de JSON partiel/corrompu : on abandonne
                // silencieusement, le prochain `updateHabits` depuis l'app
                // republiera un état cohérent.
                Log.w(TAG, "toggleHabit a échoué, abandon sans écriture", e)
            }
        }

        /// Reflète la bascule dans le cache d'affichage du widget
        /// (`PREFS_NAME`/`PREFS_KEY`) pour un retour visuel instantané,
        /// sans attendre que l'app rouvre et republie via `updateHabits`.
        private fun updateWidgetCache(context: Context, habitId: String, nowDone: Boolean) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val json = prefs.getString(PREFS_KEY, null) ?: return
            val data = JSONObject(json)
            val rows = data.optJSONArray("rows") ?: return
            var doneCount = data.optInt("doneCount", 0)

            for (i in 0 until rows.length()) {
                val row = rows.getJSONObject(i)
                if (row.optString("id") != habitId) continue
                val wasDone = row.optBoolean("done", false)
                if (wasDone != nowDone) {
                    row.put("done", nowDone)
                    doneCount += if (nowDone) 1 else -1
                }
                break
            }

            data.put("doneCount", doneCount.coerceAtLeast(0))
            prefs.edit().putString(PREFS_KEY, data.toString()).apply()
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_TOGGLE) {
            toggleHabit(context, intent.getStringExtra(EXTRA_HABIT_ID))
            updateAllWidgets(context)
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val json = prefs.getString(PREFS_KEY, null)

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.habit_widget)

            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?: Intent(context, HabitWidgetProvider::class.java)
            val openAppIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_root, openAppIntent)

            if (json == null) {
                views.setTextViewText(R.id.widget_header, "Habitudes+")
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
                        val id = row.optString("id", "")
                        val emoji = row.optString("emoji", "")
                        val name = row.optString("name", "")
                        val done = row.optBoolean("done", false)
                        val mark = if (done) "✓" else "○"
                        views.setTextViewText(rowId, "$mark $emoji $name")
                        views.setViewVisibility(rowId, View.VISIBLE)

                        if (id.isNotEmpty()) {
                            val toggleIntent = Intent(context, HabitWidgetProvider::class.java).apply {
                                action = ACTION_TOGGLE
                                putExtra(EXTRA_HABIT_ID, id)
                            }
                            val togglePendingIntent = PendingIntent.getBroadcast(
                                context,
                                id.hashCode(),
                                toggleIntent,
                                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                            )
                            views.setOnClickPendingIntent(rowId, togglePendingIntent)
                        }
                    } else {
                        views.setViewVisibility(rowId, View.GONE)
                    }
                }
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
