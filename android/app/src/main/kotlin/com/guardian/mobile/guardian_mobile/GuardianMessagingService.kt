package com.guardian.mobile.guardian_mobile

import android.content.Intent
import android.os.Build
import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import java.time.Instant

class GuardianMessagingService : FirebaseMessagingService() {
    companion object {
        private const val TAG = "GuardianMessaging"

        fun isCommandExpired(issuedAtStr: String?, ttlSeconds: Int): Boolean {
            if (issuedAtStr == null) return false
            return try {
                val issuedAtEpoch = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    Instant.parse(issuedAtStr).epochSecond
                } else {
                    System.currentTimeMillis() / 1000
                }
                val nowEpoch = System.currentTimeMillis() / 1000
                (nowEpoch - issuedAtEpoch) > ttlSeconds
            } catch (e: Exception) {
                false
            }
        }
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.i(TAG, "New FCM Token received")
        // Token will also be synced when app opens or from Flutter listener
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        Log.i(TAG, "FCM Message received from: ${remoteMessage.from}")

        val data = remoteMessage.data
        if (data.isEmpty()) {
            Log.w(TAG, "FCM Message contains no data payload")
            return
        }

        val type = data["type"]
        val commandId = data["commandId"]
        val ttlStr = data["ttl"] ?: data["ttlSeconds"]
        val ttlSeconds = ttlStr?.toIntOrNull() ?: 120
        val issuedAtStr = data["issuedAt"]

        Log.i(TAG, "Received command: type=$type, id=$commandId, ttl=$ttlSeconds")

        if (commandId.isNullOrEmpty()) {
            Log.w(TAG, "commandId is missing in data payload")
            return
        }

        // 1. Send DELIVERED ack immediately
        CommandAckClient.sendAck(applicationContext, commandId, "DELIVERED")

        // 2. Check TTL expiration
        if (isCommandExpired(issuedAtStr, ttlSeconds)) {
            Log.w(TAG, "Command $commandId has expired (TTL exceeded). Ignoring execution.")
            CommandAckClient.sendAck(
                applicationContext,
                commandId,
                "FAILED",
                "Command expired before execution"
            )
            return
        }

        // 3. Process RING command
        if (type == "RING") {
            val durationSeconds = data["durationSeconds"]?.toIntOrNull() ?: 60

            val ringIntent = Intent(applicationContext, RingService::class.java).apply {
                action = RingService.ACTION_START_RING
                putExtra(RingService.EXTRA_COMMAND_ID, commandId)
                putExtra(RingService.EXTRA_DURATION_SECONDS, durationSeconds)
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(ringIntent)
            } else {
                startService(ringIntent)
            }
        }
    }
}
