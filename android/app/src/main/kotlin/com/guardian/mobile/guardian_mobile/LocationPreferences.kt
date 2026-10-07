package com.guardian.mobile.guardian_mobile

import android.content.Context
import android.content.SharedPreferences

object LocationPreferences {
    private const val PREFS_NAME = "guardian_location_prefs"
    private const val KEY_PERIODIC_ENABLED = "periodic_location_enabled"
    private const val KEY_INTERVAL_MINUTES = "location_interval_minutes"

    private fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    fun isPeriodicEnabled(context: Context): Boolean {
        return getPrefs(context).getBoolean(KEY_PERIODIC_ENABLED, false)
    }

    fun setPeriodicEnabled(context: Context, enabled: Boolean) {
        getPrefs(context).edit().putBoolean(KEY_PERIODIC_ENABLED, enabled).apply()
    }

    fun getIntervalMinutes(context: Context): Int {
        val interval = getPrefs(context).getInt(KEY_INTERVAL_MINUTES, 15)
        return interval.coerceIn(5, 60)
    }

    fun setIntervalMinutes(context: Context, minutes: Int) {
        val valid = minutes.coerceIn(5, 60)
        getPrefs(context).edit().putInt(KEY_INTERVAL_MINUTES, valid).apply()
    }
}
