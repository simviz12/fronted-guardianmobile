package com.guardian.mobile.guardian_mobile

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.util.Log
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.util.concurrent.TimeUnit

object DeviceCapabilityClient {
    private const val TAG = "DeviceCapabilityClient"
    private val JSON_MEDIA_TYPE = "application/json; charset=utf-8".toMediaType()

    private val httpClient = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(10, TimeUnit.SECONDS)
        .writeTimeout(10, TimeUnit.SECONDS)
        .build()

    fun reportCapabilities(
        context: Context,
        adminEnabled: Boolean? = null,
        notificationsGranted: Boolean? = null,
        locationForegroundGranted: Boolean? = null,
        locationBackgroundGranted: Boolean? = null,
        batteryOptimizationIgnored: Boolean? = null,
        fullScreenIntentGranted: Boolean? = null
    ) {
        val baseUrl = NativeSecurityStorage.getApiBaseUrl(context)
        val deviceId = NativeSecurityStorage.getDeviceId(context)
        val deviceToken = NativeSecurityStorage.getDeviceToken(context)

        if (baseUrl.isNullOrEmpty() || deviceId.isNullOrEmpty() || deviceToken.isNullOrEmpty()) {
            Log.w(TAG, "Cannot report capabilities: missing baseUrl, deviceId, or deviceToken")
            return
        }

        Thread {
            try {
                val url = "$baseUrl/devices/$deviceId/capabilities"

                // Battery status
                val batteryStatus: Intent? = context.registerReceiver(
                    null,
                    IntentFilter(Intent.ACTION_BATTERY_CHANGED)
                )
                val level = batteryStatus?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
                val scale = batteryStatus?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
                val batteryPct = if (level >= 0 && scale > 0) (level * 100 / scale) else null

                val status = batteryStatus?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
                val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                        status == BatteryManager.BATTERY_STATUS_FULL

                val permissionsJson = JSONObject().apply {
                    notificationsGranted?.let { put("notifications", it) }
                    locationForegroundGranted?.let { put("locationForeground", it) }
                    locationBackgroundGranted?.let { put("locationBackground", it) }
                    batteryOptimizationIgnored?.let { put("batteryOptimizationIgnored", it) }
                    adminEnabled?.let { put("deviceAdmin", it) }
                    fullScreenIntentGranted?.let { put("fullScreenIntent", it) }
                }

                val json = JSONObject().apply {
                    adminEnabled?.let { put("adminEnabled", it) }
                    batteryPct?.let { put("batteryLevel", it) }
                    put("isCharging", isCharging)
                    if (permissionsJson.length() > 0) {
                        put("permissions", permissionsJson)
                    }
                }

                val requestBody = json.toString().toRequestBody(JSON_MEDIA_TYPE)
                val request = Request.Builder()
                    .url(url)
                    .addHeader("Authorization", "Device $deviceToken")
                    .patch(requestBody)
                    .build()

                httpClient.newCall(request).execute().use { response ->
                    if (response.isSuccessful) {
                        Log.i(TAG, "Capabilities reported successfully to $url (code: ${response.code})")
                    } else {
                        Log.w(TAG, "Failed to report capabilities: HTTP ${response.code}")
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error reporting capabilities: ${e.message}")
            }
        }.start()
    }
}
