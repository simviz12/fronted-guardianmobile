package com.guardian.mobile.guardian_mobile

import android.content.Context
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

object OfflineLocationQueue {
    private const val TAG = "OfflineLocationQueue"
    private const val FILE_NAME = "guardian_offline_locations.json"
    private const val MAX_ITEMS = 50

    private val lock = Any()

    private fun getFile(context: Context): File {
        return File(context.filesDir, FILE_NAME)
    }

    fun enqueue(
        context: Context,
        latitude: Double,
        longitude: Double,
        accuracyMeters: Float?,
        speedMps: Float?,
        recordedAtIso: String,
        source: String
    ) {
        synchronized(lock) {
            try {
                val list = readAll(context).toMutableList()
                val json = JSONObject().apply {
                    put("latitude", latitude)
                    put("longitude", longitude)
                    if (accuracyMeters != null) put("accuracyMeters", accuracyMeters.toDouble())
                    if (speedMps != null) put("speedMps", speedMps.toDouble())
                    put("recordedAt", recordedAtIso)
                    put("source", source)
                }

                // Append
                list.add(json)

                // If exceeds MAX_ITEMS, keep only the newest 50
                val trimmed = if (list.size > MAX_ITEMS) {
                    list.subList(list.size - MAX_ITEMS, list.size)
                } else {
                    list
                }

                saveAll(context, trimmed)
                Log.i(TAG, "Enqueued location offline. Current queue size: ${trimmed.size}")
            } catch (e: Exception) {
                Log.e(TAG, "Error enqueuing offline location: ${e.message}", e)
            }
        }
    }

    fun flushQueue(context: Context) {
        synchronized(lock) {
            val list = readAll(context)
            if (list.isEmpty()) return

            Log.i(TAG, "Attempting to flush ${list.size} offline locations...")
            val success = LocationReporterClient.reportBatchLocations(context, list)
            if (success) {
                clear(context)
                Log.i(TAG, "Successfully flushed and cleared offline queue")
            } else {
                Log.w(TAG, "Failed to flush offline queue; will retry on next cycle")
            }
        }
    }

    private fun readAll(context: Context): List<JSONObject> {
        val file = getFile(context)
        if (!file.exists()) return emptyList()

        return try {
            val content = file.readText()
            if (content.isBlank()) return emptyList()

            val array = JSONArray(content)
            val result = mutableListOf<JSONObject>()
            for (i in 0 until array.length()) {
                result.add(array.getJSONObject(i))
            }
            result
        } catch (e: Exception) {
            Log.e(TAG, "Error reading offline file: ${e.message}")
            emptyList()
        }
    }

    private fun saveAll(context: Context, items: List<JSONObject>) {
        val file = getFile(context)
        try {
            val array = JSONArray()
            for (item in items) {
                array.put(item)
            }
            file.writeText(array.toString())
        } catch (e: Exception) {
            Log.e(TAG, "Error saving offline locations: ${e.message}")
        }
    }

    private fun clear(context: Context) {
        val file = getFile(context)
        if (file.exists()) {
            file.delete()
        }
    }
}
