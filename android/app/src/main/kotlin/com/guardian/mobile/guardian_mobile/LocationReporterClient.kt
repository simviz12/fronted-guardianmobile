package com.guardian.mobile.guardian_mobile

import android.content.Context
import android.util.Log
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.TimeUnit

object LocationReporterClient {
    private const val TAG = "LocationReporterClient"
    private val JSON_MEDIA_TYPE = "application/json; charset=utf-8".toMediaType()

    private val httpClient = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(15, TimeUnit.SECONDS)
        .writeTimeout(15, TimeUnit.SECONDS)
        .build()

    fun reportSingleLocation(
        context: Context,
        latitude: Double,
        longitude: Double,
        accuracyMeters: Float?,
        speedMps: Float?,
        recordedAtIso: String,
        source: String = "PERIODIC"
    ): Boolean {
        val baseUrl = NativeSecurityStorage.getApiBaseUrl(context)
        val deviceId = NativeSecurityStorage.getDeviceId(context)
        val deviceToken = NativeSecurityStorage.getDeviceToken(context)

        if (baseUrl.isNullOrEmpty() || deviceId.isNullOrEmpty() || deviceToken.isNullOrEmpty()) {
            Log.w(TAG, "Cannot report location: missing baseUrl, deviceId, or deviceToken")
            return false
        }

        return try {
            val url = "$baseUrl/devices/$deviceId/locations"
            val json = JSONObject().apply {
                put("latitude", latitude)
                put("longitude", longitude)
                if (accuracyMeters != null) put("accuracyMeters", accuracyMeters.toDouble())
                if (speedMps != null) put("speedMps", speedMps.toDouble())
                put("recordedAt", recordedAtIso)
                put("source", source)
            }

            val requestBody = json.toString().toRequestBody(JSON_MEDIA_TYPE)
            val request = Request.Builder()
                .url(url)
                .addHeader("Authorization", "Device $deviceToken")
                .post(requestBody)
                .build()

            httpClient.newCall(request).execute().use { response ->
                if (response.isSuccessful) {
                    Log.i(TAG, "Location reported successfully (source=$source, code=${response.code})")
                    true
                } else {
                    Log.w(TAG, "Failed to report location: code=${response.code}, body=${response.body?.string()}")
                    false
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error posting single location: ${e.message}", e)
            false
        }
    }

    fun reportBatchLocations(
        context: Context,
        items: List<JSONObject>
    ): Boolean {
        if (items.isEmpty()) return true

        val baseUrl = NativeSecurityStorage.getApiBaseUrl(context)
        val deviceId = NativeSecurityStorage.getDeviceId(context)
        val deviceToken = NativeSecurityStorage.getDeviceToken(context)

        if (baseUrl.isNullOrEmpty() || deviceId.isNullOrEmpty() || deviceToken.isNullOrEmpty()) {
            Log.w(TAG, "Cannot report batch: missing baseUrl, deviceId, or deviceToken")
            return false
        }

        return try {
            val url = "$baseUrl/devices/$deviceId/locations"
            val jsonArray = JSONArray()
            for (item in items) {
                jsonArray.put(item)
            }
            val root = JSONObject().apply {
                put("locations", jsonArray)
            }

            val requestBody = root.toString().toRequestBody(JSON_MEDIA_TYPE)
            val request = Request.Builder()
                .url(url)
                .addHeader("Authorization", "Device $deviceToken")
                .post(requestBody)
                .build()

            httpClient.newCall(request).execute().use { response ->
                if (response.isSuccessful) {
                    Log.i(TAG, "Batch locations reported successfully (${items.size} items)")
                    true
                } else {
                    Log.w(TAG, "Failed to report batch locations: code=${response.code}")
                    false
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error posting batch locations: ${e.message}", e)
            false
        }
    }
}
