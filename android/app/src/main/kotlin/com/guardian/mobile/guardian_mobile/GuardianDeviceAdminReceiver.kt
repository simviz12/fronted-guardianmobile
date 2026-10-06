package com.guardian.mobile.guardian_mobile

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class GuardianDeviceAdminReceiver : DeviceAdminReceiver() {
    companion object {
        private const val TAG = "GuardianDeviceAdmin"
    }

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Log.i(TAG, "Guardian Device Admin ENABLED")
        DeviceCapabilityClient.reportCapabilities(context, adminEnabled = true)
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Log.i(TAG, "Guardian Device Admin DISABLED by user")
        DeviceCapabilityClient.reportCapabilities(context, adminEnabled = false)
    }
}
