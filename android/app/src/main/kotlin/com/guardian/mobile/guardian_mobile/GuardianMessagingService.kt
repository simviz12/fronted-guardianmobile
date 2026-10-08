package com.guardian.mobile.guardian_mobile

import android.content.Intent
import android.os.Build
import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import kotlinx.coroutines.launch
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

        // Parse nested JSON payload if present (sent by backend as data["payload"])
        val payloadJsonStr = data["payload"]
        val payloadObj: org.json.JSONObject? = if (!payloadJsonStr.isNullOrEmpty() && payloadJsonStr != "null") {
            try {
                org.json.JSONObject(payloadJsonStr)
            } catch (e: Exception) {
                null
            }
        } else {
            null
        }

        // 3. Process commands
        when (type) {
            "RING" -> {
                val durationSeconds = payloadObj?.optInt("durationSeconds", 0)?.takeIf { it > 0 }
                    ?: data["durationSeconds"]?.toIntOrNull()
                    ?: 60

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
                val durationSeconds = payloadObj?.optInt("durationSeconds", 0)?.takeIf { it > 0 }
                    ?: data["durationSeconds"]?.toIntOrNull()
                    ?: 5
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
                        val audioAttributes = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                            android.media.AudioAttributes.Builder()
                                .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SONIFICATION)
                                .setUsage(android.media.AudioAttributes.USAGE_ALARM)
                                .build()
                        } else null

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            // Split into repeating pattern pulses (e.g. 800ms vibrate, 200ms pause) so long vibrations don't get truncated by OS
                            val pattern = LongArray(((durationSeconds * 2)).toInt()) { index ->
                                if (index % 2 == 0) 800L else 200L
                            }
                            val effect = android.os.VibrationEffect.createWaveform(pattern, -1)
                            if (audioAttributes != null) {
                                vibrator.vibrate(effect, audioAttributes)
                            } else {
                                vibrator.vibrate(effect)
                            }
                        } else {
                            @Suppress("DEPRECATION")
                            val pattern = LongArray(((durationSeconds * 2)).toInt()) { index ->
                                if (index % 2 == 0) 800L else 200L
                            }
                            @Suppress("DEPRECATION")
                            vibrator.vibrate(pattern, -1)
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
                val messageText = payloadObj?.optString("text", "")?.takeIf { it.isNotEmpty() }
                    ?: payloadObj?.optString("message", "")?.takeIf { it.isNotEmpty() }
                    ?: data["text"]
                    ?: data["message"]
                    ?: "Mensaje de seguridad"
                val contactPhone = payloadObj?.optString("contactPhone", "")?.takeIf { it.isNotEmpty() }
                    ?: payloadObj?.optString("phone", "")?.takeIf { it.isNotEmpty() }
                    ?: data["contactPhone"]
                    ?: data["phone"]

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
            "LOCATE" -> {
                kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.IO).launch {
                    try {
                        if (!LocationHelper.hasLocationPermission(applicationContext)) {
                            Log.w(TAG, "Cannot execute LOCATE: LOCATION_PERMISSION_DENIED")
                            CommandAckClient.sendAck(
                                applicationContext,
                                commandId,
                                "FAILED",
                                "LOCATION_PERMISSION_DENIED"
                            )
                            return@launch
                        }

                        // Try to get a high-accuracy fix with 30s timeout
                        val location = LocationHelper.getSingleHighAccuracyLocation(
                            applicationContext,
                            timeoutMs = 30000L
                        )

                        if (location != null) {
                            val iso = LocationHelper.formatIsoTimestamp(java.util.Date(location.time))
                            val posted = LocationReporterClient.reportSingleLocation(
                                context = applicationContext,
                                latitude = location.latitude,
                                longitude = location.longitude,
                                accuracyMeters = if (location.hasAccuracy()) location.accuracy else null,
                                speedMps = if (location.hasSpeed()) location.speed else null,
                                recordedAtIso = iso,
                                source = "LOCATE_COMMAND"
                            )

                            if (posted) {
                                CommandAckClient.sendAck(applicationContext, commandId, "EXECUTED")
                            } else {
                                // Enqueue offline as fallback
                                OfflineLocationQueue.enqueue(
                                    context = applicationContext,
                                    latitude = location.latitude,
                                    longitude = location.longitude,
                                    accuracyMeters = if (location.hasAccuracy()) location.accuracy else null,
                                    speedMps = if (location.hasSpeed()) location.speed else null,
                                    recordedAtIso = iso,
                                    source = "LOCATE_COMMAND"
                                )
                                CommandAckClient.sendAck(
                                    applicationContext,
                                    commandId,
                                    "FAILED",
                                    "NETWORK_ERROR"
                                )
                            }
                        } else {
                            Log.w(TAG, "LOCATE fix timed out or unavailable")
                            CommandAckClient.sendAck(
                                applicationContext,
                                commandId,
                                "FAILED",
                                "LOCATION_UNAVAILABLE"
                            )
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error executing LOCATE: ${e.message}", e)
                        CommandAckClient.sendAck(
                            applicationContext,
                            commandId,
                            "FAILED",
                            e.message ?: "LOCATION_ERROR"
                        )
                    }
                }
            }
            "THEFT_MODE_ON" -> {
                try {
                    val message = payloadObj?.optString("message", "")?.takeIf { it.isNotEmpty() }
                        ?: data["message"]
                        ?: "Este teléfono está perdido. Por favor contacta a su dueño."
                    val contactPhone = payloadObj?.optString("contactPhone", "")?.takeIf { it.isNotEmpty() }
                        ?: data["contactPhone"]
                    val intervalSeconds = payloadObj?.optInt("locationIntervalSeconds", 60)
                        ?: data["locationIntervalSeconds"]?.toIntOrNull()
                        ?: 60
                    val alarm = payloadObj?.optBoolean("alarm", false)
                        ?: (data["alarm"] == "true")
                    val lock = payloadObj?.optBoolean("lock", false)
                        ?: (data["lock"] == "true")

                    // 1. Persist config in EncryptedSharedPreferences
                    NativeSecurityStorage.saveTheftModeConfig(
                        context = applicationContext,
                        message = message,
                        contactPhone = contactPhone,
                        intervalSeconds = intervalSeconds
                    )

                    // 2. Lock if configured
                    if (lock) {
                        val dpm = getSystemService(android.content.Context.DEVICE_POLICY_SERVICE) as? android.app.admin.DevicePolicyManager
                        val adminComponent = android.content.ComponentName(applicationContext, GuardianDeviceAdminReceiver::class.java)
                        if (dpm != null && dpm.isAdminActive(adminComponent)) {
                            dpm.lockNow()
                        }
                    }

                    // 3. Show Message Activity
                    val messageIntent = Intent(applicationContext, MessageActivity::class.java).apply {
                        putExtra(MessageActivity.EXTRA_MESSAGE_TEXT, message)
                        putExtra(MessageActivity.EXTRA_CONTACT_PHONE, contactPhone)
                        putExtra(MessageActivity.EXTRA_COMMAND_ID, commandId)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    }
                    startActivity(messageIntent)

                    // 4. Ring if configured
                    if (alarm) {
                        val ringIntent = Intent(applicationContext, RingService::class.java).apply {
                            action = RingService.ACTION_START_RING
                            putExtra(RingService.EXTRA_DURATION_SECONDS, 60)
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(ringIntent)
                        } else {
                            startService(ringIntent)
                        }
                    }

                    // 5. Restart location service with THEFT_MODE interval
                    LocationService.start(applicationContext)

                    // 6. Ack EXECUTED
                    CommandAckClient.sendAck(applicationContext, commandId, "EXECUTED")
                } catch (e: Exception) {
                    Log.e(TAG, "Error executing THEFT_MODE_ON: ${e.message}", e)
                    CommandAckClient.sendAck(
                        applicationContext,
                        commandId,
                        "FAILED",
                        e.message ?: "THEFT_MODE_ERROR"
                    )
                }
            }
            "THEFT_MODE_OFF" -> {
                try {
                    // 1. Clear theft mode config
                    NativeSecurityStorage.clearTheftModeConfig(applicationContext)

                    // 2. Stop ring service if active
                    val stopRingIntent = Intent(applicationContext, RingService::class.java).apply {
                        action = RingService.ACTION_STOP_RING
                    }
                    startService(stopRingIntent)

                    // 3. Restart location service to revert to normal periodic interval & notification
                    if (LocationPreferences.isPeriodicEnabled(applicationContext)) {
                        LocationService.start(applicationContext)
                    } else {
                        LocationService.stop(applicationContext)
                    }

                    // 4. Ack EXECUTED
                    CommandAckClient.sendAck(applicationContext, commandId, "EXECUTED")
                } catch (e: Exception) {
                    Log.e(TAG, "Error executing THEFT_MODE_OFF: ${e.message}", e)
                    CommandAckClient.sendAck(
                        applicationContext,
                        commandId,
                        "FAILED",
                        e.message ?: "THEFT_MODE_OFF_ERROR"
                    )
                }
            }
            "WIPE" -> {
                Log.w(TAG, "Received critical command: WIPE for commandId: $commandId")
                try {
                    val dpm = getSystemService(android.content.Context.DEVICE_POLICY_SERVICE) as? android.app.admin.DevicePolicyManager
                    val adminComponent = android.content.ComponentName(applicationContext, GuardianDeviceAdminReceiver::class.java)

                    if (dpm == null || !dpm.isAdminActive(adminComponent)) {
                        Log.e(TAG, "Cannot execute WIPE: Device Admin is not active")
                        CommandAckClient.sendAck(
                            applicationContext,
                            commandId,
                            "FAILED",
                            "ADMIN_NOT_ENABLED"
                        )
                        return
                    }

                    // Acknowledge EXECUTING before triggering wipe (with retry handled by CommandAckClient)
                    CommandAckClient.sendAck(applicationContext, commandId, "EXECUTING")

                    // Small grace period to allow network packet transmission
                    try {
                        Thread.sleep(1500)
                    } catch (_: InterruptedException) {}

                    // Trigger factory reset. 0 = do NOT wipe external storage unless explicitly requested.
                    // This protects SD cards and preserves safe destruction semantics.
                    dpm.wipeData(0)
                } catch (e: Exception) {
                    Log.e(TAG, "Error executing WIPE: ${e.message}", e)
                    CommandAckClient.sendAck(
                        applicationContext,
                        commandId,
                        "FAILED",
                        e.message ?: "WIPE_ERROR"
                    )
                }
            }
        }
    }
}
