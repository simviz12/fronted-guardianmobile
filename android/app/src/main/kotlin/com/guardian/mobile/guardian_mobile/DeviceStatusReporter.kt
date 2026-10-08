package com.guardian.mobile.guardian_mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.util.concurrent.TimeUnit

object DeviceStatusReporter {
    private const val TAG = "DeviceStatusReporter"
    private val JSON_MEDIA_TYPE = "application/json; charset=utf-8".toMediaType()

    private val httpClient = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(15, TimeUnit.SECONDS)
        .writeTimeout(15, TimeUnit.SECONDS)
        .build()

    private var receiverRegistered = false
    private val mainHandler = Handler(Looper.getMainLooper())
    private var debounceRunnable: Runnable? = null
    private const val DEBOUNCE_DELAY_MS = 3000L

    private val statusChangeReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (context == null) return
            scheduleDebouncedReport(context.applicationContext)
        }
    }

    fun startListening(context: Context) {
        if (receiverRegistered) return
        val appContext = context.applicationContext
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_POWER_CONNECTED)
            addAction(Intent.ACTION_POWER_DISCONNECTED)
            addAction(ConnectivityManager.CONNECTIVITY_ACTION)
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                appContext.registerReceiver(statusChangeReceiver, filter, Context.RECEIVER_EXPORTED)
            } else {
                appContext.registerReceiver(statusChangeReceiver, filter)
            }
            receiverRegistered = true
            Log.i(TAG, "DeviceStatusReporter broadcast listener registered")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to register statusChangeReceiver: ${e.message}")
        }

        // Report immediately on start
        reportStatusNow(appContext)
    }

    fun stopListening(context: Context) {
        if (!receiverRegistered) return
        try {
            context.applicationContext.unregisterReceiver(statusChangeReceiver)
            receiverRegistered = false
            debounceRunnable?.let { mainHandler.removeCallbacks(it) }
            Log.i(TAG, "DeviceStatusReporter broadcast listener unregistered")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to unregister statusChangeReceiver: ${e.message}")
        }
    }

    fun scheduleDebouncedReport(context: Context) {
        debounceRunnable?.let { mainHandler.removeCallbacks(it) }
        debounceRunnable = Runnable {
            reportStatusNow(context)
        }
        mainHandler.postDelayed(debounceRunnable!!, DEBOUNCE_DELAY_MS)
    }

    fun reportStatusNow(context: Context) {
        Thread {
            try {
                val baseUrl = NativeSecurityStorage.getApiBaseUrl(context)
                val deviceId = NativeSecurityStorage.getDeviceId(context)
                val deviceToken = NativeSecurityStorage.getDeviceToken(context)

                if (baseUrl.isNullOrEmpty() || deviceId.isNullOrEmpty() || deviceToken.isNullOrEmpty()) {
                    Log.d(TAG, "Cannot report status: device not configured or missing token")
                    return@Thread
                }

                val batteryStatus = getBatteryStatus(context)
                val networkType = getNetworkType(context)
                val appVersion = getAppVersion(context)

                val json = JSONObject().apply {
                    batteryStatus.level?.let { put("batteryLevel", it) }
                    batteryStatus.isCharging?.let { put("isCharging", it) }
                    put("networkType", networkType)
                    if (appVersion.isNotEmpty()) {
                        put("appVersion", appVersion)
                    }
                }

                val url = "$baseUrl/devices/$deviceId/status"
                val requestBody = json.toString().toRequestBody(JSON_MEDIA_TYPE)
                val request = Request.Builder()
                    .url(url)
                    .addHeader("Authorization", "Device $deviceToken")
                    .post(requestBody)
                    .build()

                httpClient.newCall(request).execute().use { response ->
                    if (response.isSuccessful || response.code == 204) {
                        Log.i(TAG, "Device status reported successfully (battery=${batteryStatus.level}%, charging=${batteryStatus.isCharging}, net=$networkType)")
                    } else {
                        Log.w(TAG, "Failed to report device status: code=${response.code}")
                    }
                }
            } catch (e: Exception) {
                Log.w(TAG, "Error posting device status (will retry next heartbeat): ${e.message}")
            }
        }.start()
    }

    private data class BatteryInfo(val level: Int?, val isCharging: Boolean?)

    private fun getBatteryStatus(context: Context): BatteryInfo {
        return try {
            val batteryFilter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
            val batteryStatus = context.registerReceiver(null, batteryFilter)
            if (batteryStatus != null) {
                val level = batteryStatus.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                val scale = batteryStatus.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
                val pct = if (level >= 0 && scale > 0) (level * 100) / scale else null

                val status = batteryStatus.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
                val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                        status == BatteryManager.BATTERY_STATUS_FULL
                BatteryInfo(pct, isCharging)
            } else {
                BatteryInfo(null, null)
            }
        } catch (e: Exception) {
            BatteryInfo(null, null)
        }
    }

    private fun getNetworkType(context: Context): String {
        return try {
            val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
                ?: return "unknown"

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val network = cm.activeNetwork ?: return "none"
                val caps = cm.getNetworkCapabilities(network) ?: return "none"
                when {
                    caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
                    caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "mobile"
                    caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "wifi"
                    caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) -> "unknown"
                    else -> "none"
                }
            } else {
                @Suppress("DEPRECATION")
                val activeInfo = cm.activeNetworkInfo
                if (activeInfo == null || !activeInfo.isConnected) return "none"
                @Suppress("DEPRECATION")
                when (activeInfo.type) {
                    ConnectivityManager.TYPE_WIFI -> "wifi"
                    ConnectivityManager.TYPE_MOBILE -> "mobile"
                    else -> "unknown"
                }
            }
        } catch (e: Exception) {
            "unknown"
        }
    }

    private fun getAppVersion(context: Context): String {
        return try {
            val pInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.packageManager.getPackageInfo(context.packageName, PackageManager.PackageInfoFlags.of(0))
            } else {
                @Suppress("DEPRECATION")
                context.packageManager.getPackageInfo(context.packageName, 0)
            }
            pInfo.versionName ?: ""
        } catch (e: Exception) {
            ""
        }
    }
}
