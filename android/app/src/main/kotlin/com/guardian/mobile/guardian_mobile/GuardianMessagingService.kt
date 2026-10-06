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

        // 3. Process commands
        when (type) {
            "RING" -> {
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
            "VIBRATE" -> {
                val durationSeconds = data["durationSeconds"]?.toIntOrNull() ?: 5
                val durationMs = (durationSeconds * 1000).toLong()

                try {
                    val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        val vibratorManager = getSystemService(android.content.Context.VIBRATOR_MANAGER_SERVICE) as? android.os.VibratorManager
                        vibratorManager?.defaultVibrator
                    } else {
                        @Suppress("DEPRECATION")
                        getSystemService(android.content.Context.VIBRATOR_SERVICE) as? android.os.Vibrator
                    }

                    if (vibrator != null && vibrator.hasVibrator()) {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val effect = android.os.VibrationEffect.createOneShot(
                                durationMs,
                                android.os.VibrationEffect.DEFAULT_AMPLITUDE
                            )
                            vibrator.vibrate(effect)
                        } else {
                            @Suppress("DEPRECATION")
                            vibrator.vibrate(durationMs)
                        }
                        CommandAckClient.sendAck(applicationContext, commandId, "EXECUTED")
                    } else {
                        CommandAckClient.sendAck(
                            applicationContext,
                            commandId,
                            "FAILED",
                            "Dispositivo sin hardware de vibración disponible"
                        )
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error executing VIBRATE: ${e.message}", e)
                    CommandAckClient.sendAck(
                        applicationContext,
                        commandId,
                        "FAILED",
                        e.message ?: "Error desconocido al vibrar"
                    )
                }
            }
            "MESSAGE" -> {
                val messageText = data["text"] ?: data["message"] ?: "Mensaje de seguridad"
                val contactPhone = data["contactPhone"] ?: data["phone"]

                try {
                    val messageIntent = Intent(applicationContext, MessageActivity::class.java).apply {
                        putExtra(MessageActivity.EXTRA_MESSAGE_TEXT, messageText)
                        putExtra(MessageActivity.EXTRA_CONTACT_PHONE, contactPhone)
                        putExtra(MessageActivity.EXTRA_COMMAND_ID, commandId)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    }

                    // On Android 10+ background activity start may be restricted, also prepare full-screen notification fallback
                    val notificationManager = getSystemService(android.content.Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
                    val channelId = "guardian_urgent_messages"
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val channel = android.app.NotificationChannel(
                            channelId,
                            "Mensajes Críticos de Guardian",
                            android.app.NotificationManager.IMPORTANCE_HIGH
                        ).apply {
                            setBypassDnd(true)
                            lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
                        }
                        notificationManager.createNotificationChannel(channel)
                    }

                    val pendingIntent = android.app.PendingIntent.getActivity(
                        applicationContext,
                        commandId.hashCode(),
                        messageIntent,
                        android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                    )

                    val notification = androidx.core.app.NotificationCompat.Builder(applicationContext, channelId)
                        .setSmallIcon(android.R.drawable.ic_dialog_alert)
                        .setContentTitle("Mensaje del propietario")
                        .setContentText(messageText)
                        .setPriority(androidx.core.app.NotificationCompat.PRIORITY_MAX)
                        .setCategory(androidx.core.app.NotificationCompat.CATEGORY_ALARM)
                        .setVisibility(androidx.core.app.NotificationCompat.VISIBILITY_PUBLIC)
                        .setFullScreenIntent(pendingIntent, true)
                        .setAutoCancel(true)
                        .build()

                    notificationManager.notify(commandId.hashCode(), notification)

                    // Also try directly starting the activity
                    startActivity(messageIntent)
                } catch (e: Exception) {
                    Log.e(TAG, "Error displaying MESSAGE: ${e.message}", e)
                    CommandAckClient.sendAck(
                        applicationContext,
                        commandId,
                        "FAILED",
                        e.message ?: "Error al mostrar mensaje"
                    )
                }
            }
            "LOCK" -> {
                try {
                    val dpm = getSystemService(android.content.Context.DEVICE_POLICY_SERVICE) as? android.app.admin.DevicePolicyManager
                    val adminComponent = android.content.ComponentName(applicationContext, GuardianDeviceAdminReceiver::class.java)

                    if (dpm != null && dpm.isAdminActive(adminComponent)) {
                        dpm.lockNow()
                        CommandAckClient.sendAck(applicationContext, commandId, "EXECUTED")
                    } else {
                        Log.w(TAG, "Cannot execute LOCK: Device Admin is not active")
                        CommandAckClient.sendAck(
                            applicationContext,
                            commandId,
                            "FAILED",
                            "ADMIN_NOT_ENABLED"
                        )
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error executing LOCK: ${e.message}", e)
                    CommandAckClient.sendAck(
                        applicationContext,
                        commandId,
                        "FAILED",
                        e.message ?: "ADMIN_NOT_ENABLED"
                    )
                }
            }
        }
    }
}
