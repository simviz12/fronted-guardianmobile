package com.guardian.mobile.guardian_mobile

import android.content.Context
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

    fun reportCapabilities(context: Context, adminEnabled: Boolean) {
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
                val json = JSONObject().apply {
                    put("adminEnabled", adminEnabled)
                }

                val requestBody = json.toString().toRequestBody(JSON_MEDIA_TYPE)
                val request = Request.Builder()
                    .url(url)
                    .addHeader("Authorization", "Device $deviceToken")
                    .patch(requestBody)
                    .build()

                httpClient.newCall(request).execute().use { response ->
                    if (response.isSuccessful) {
                        Log.i(TAG, "Capabilities reported successfully: adminEnabled=$adminEnabled (code: ${response.code})")
                    } else {
                        Log.w(TAG, "Failed to report capabilities (code: ${response.code})")
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error reporting capabilities: ${e.message}")
            }
        }.start()
    }
}
