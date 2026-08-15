package com.habitudeplus.habit_tracker

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Relaie les données d'habitudes du jour vers le widget écran d'accueil.
/// Canal maison plutôt qu'un package tiers, pour ne dépendre que d'APIs
/// Android standard (SharedPreferences + broadcast ACTION_APPWIDGET_UPDATE)
/// faciles à vérifier sans dépendre de détails internes non documentés.
class MainActivity : FlutterActivity() {
    private val channelName = "com.habitudeplus.habit_tracker/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            if (call.method == "updateHabits") {
                val json = call.arguments as? String
                if (json != null) {
                    getSharedPreferences(HabitWidgetProvider.PREFS_NAME, Context.MODE_PRIVATE)
                        .edit()
                        .putString(HabitWidgetProvider.PREFS_KEY, json)
                        .apply()
                    HabitWidgetProvider.updateAllWidgets(applicationContext)
                }
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }
}
