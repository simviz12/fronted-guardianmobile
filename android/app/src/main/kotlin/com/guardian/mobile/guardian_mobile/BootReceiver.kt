package com.guardian.mobile.guardian_mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.i(TAG, "Received broadcast action: $action")

        if (Intent.ACTION_BOOT_COMPLETED == action || Intent.ACTION_MY_PACKAGE_REPLACED == action) {
            val enabled = LocationPreferences.isPeriodicEnabled(context)
            val isTheft = NativeSecurityStorage.isTheftModeActive(context)
            val hasPermission = LocationHelper.hasLocationPermission(context)
            Log.i(TAG, "Device rebooted. Periodic enabled=$enabled, isTheft=$isTheft, hasPermission=$hasPermission")

            if ((enabled || isTheft) && hasPermission) {
                try {
                    LocationService.start(context)
                    Log.i(TAG, "Successfully resumed LocationService after boot (isTheft=$isTheft)")
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to start LocationService after boot: ${e.message}", e)
                }
            }
        }
    }
}
