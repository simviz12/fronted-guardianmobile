package com.guardian.mobile.guardian_mobile

import android.content.Context
import android.util.Log
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.util.concurrent.TimeUnit

object CommandAckClient {
    private const val TAG = "CommandAckClient"
    private val JSON_MEDIA_TYPE = "application/json; charset=utf-8".toMediaType()

    private val httpClient = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(10, TimeUnit.SECONDS)
        .writeTimeout(10, TimeUnit.SECONDS)
        .build()

    fun sendAck(
        context: Context,
        commandId: String,
        status: String,
        failureReason: String? = null
    ) {
        val baseUrl = NativeSecurityStorage.getApiBaseUrl(context)
        val deviceToken = NativeSecurityStorage.getDeviceToken(context)

        if (baseUrl.isNullOrEmpty() || deviceToken.isNullOrEmpty()) {
            Log.w(TAG, "Cannot send ACK: apiBaseUrl or deviceToken missing")
            return
        }

        Thread {
            var attempt = 0
            val maxRetries = 3
            var success = false

            while (attempt < maxRetries && !success) {
                attempt++
                try {
                    val url = "$baseUrl/commands/$commandId/ack"
                    val json = JSONObject().apply {
                        put("status", status)
                        if (failureReason != null) {
                            put("failureReason", failureReason)
                        }
                    }

                    val requestBody = json.toString().toRequestBody(JSON_MEDIA_TYPE)
                    val request = Request.Builder()
                        .url(url)
                        .addHeader("Authorization", "Device $deviceToken")
                        .post(requestBody)
                        .build()

                    httpClient.newCall(request).execute().use { response ->
                        if (response.isSuccessful) {
                            Log.i(TAG, "ACK $status sent for command $commandId (code: ${response.code})")
                            success = true
                        } else {
                            Log.w(TAG, "ACK $status failed for command $commandId (code: ${response.code})")
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "ACK error on attempt $attempt: ${e.message}")
                    if (attempt < maxRetries) {
                        try {
                            Thread.sleep(1000L * attempt)
                        } catch (_: InterruptedException) {}
                    }
                }
            }
        }.start()
    }
}
