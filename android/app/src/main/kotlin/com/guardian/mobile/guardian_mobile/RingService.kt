package com.guardian.mobile.guardian_mobile

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat

class RingService : Service() {
    companion object {
        private const val TAG = "RingService"
        const val ACTION_START_RING = "com.guardian.mobile.ACTION_START_RING"
        const val ACTION_STOP_RING = "com.guardian.mobile.ACTION_STOP_RING"
        const val EXTRA_COMMAND_ID = "extra_command_id"
        const val EXTRA_DURATION_SECONDS = "extra_duration_seconds"

        private const val NOTIFICATION_CHANNEL_ID = "guardian_ring_channel"
        private const val NOTIFICATION_ID = 9001
    }

    private var mediaPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var stopHandler: Handler? = null
    private var stopRunnable: Runnable? = null
    private var currentCommandId: String? = null
    private var originalVolume: Int = -1

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        if (action == ACTION_STOP_RING) {
            Log.i(TAG, "Stopping ring service by action")
            stopAlarm()
            stopSelf()
            return START_NOT_STICKY
        }

        if (action == ACTION_START_RING) {
            val commandId = intent.getStringExtra(EXTRA_COMMAND_ID)
            val durationSeconds = intent.getIntExtra(EXTRA_DURATION_SECONDS, 60)
            currentCommandId = commandId

            startForeground(NOTIFICATION_ID, createNotification())
            startAlarm(commandId, durationSeconds)
        }

        return START_NOT_STICKY
    }

    private fun startAlarm(commandId: String?, durationSeconds: Int) {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager

        try {
            // 1. Acquire partial wake lock for the duration
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "GuardianMobile::RingWakeLock"
            ).apply {
                acquire((durationSeconds + 5) * 1000L)
            }

            // 2. Maximize Alarm stream volume
            originalVolume = audioManager.getStreamVolume(AudioManager.STREAM_ALARM)
            val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
            audioManager.setStreamVolume(AudioManager.STREAM_ALARM, maxVolume, 0)

            // 3. Setup and start MediaPlayer on STREAM_ALARM
            val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)

            mediaPlayer = MediaPlayer().apply {
                setDataSource(applicationContext, alarmUri)
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                isLooping = true
                prepare()
                start()
            }

            Log.i(TAG, "Alarm playing on max volume for $durationSeconds seconds")

            // 4. Send EXECUTED ack to backend
            if (commandId != null) {
                CommandAckClient.sendAck(applicationContext, commandId, "EXECUTED")
            }

            // 5. Schedule auto-stop after durationSeconds
            stopHandler = Handler(Looper.getMainLooper())
            stopRunnable = Runnable {
                Log.i(TAG, "Alarm duration completed, stopping")
                stopAlarm()
                stopSelf()
            }
            stopHandler?.postDelayed(stopRunnable!!, durationSeconds * 1000L)

        } catch (e: Exception) {
            Log.e(TAG, "Failed to play alarm: ${e.message}", e)
            if (commandId != null) {
                CommandAckClient.sendAck(
                    applicationContext,
                    commandId,
                    "FAILED",
                    e.message ?: "Failed to play alarm audio"
                )
            }
            stopAlarm()
            stopSelf()
        }
    }

    private fun stopAlarm() {
        stopRunnable?.let { stopHandler?.removeCallbacks(it) }

        try {
            mediaPlayer?.apply {
                if (isPlaying) {
                    stop()
                }
                release()
            }
        } catch (_: Exception) {}
        mediaPlayer = null

        // Restore original volume if desired
        if (originalVolume >= 0) {
            try {
                val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                audioManager.setStreamVolume(AudioManager.STREAM_ALARM, originalVolume, 0)
            } catch (_: Exception) {}
        }

        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
        } catch (_: Exception) {}
        wakeLock = null
    }

    override fun onDestroy() {
        stopAlarm()
        super.onDestroy()
    }

    private fun createNotification(): Notification {
        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Alarma de Guardian",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notificaciones durante la activación de la alarma remota"
                setSound(null, null)
            }
            notificationManager.createNotificationChannel(channel)
        }

        val stopIntent = Intent(this, RingService::class.java).apply {
            action = ACTION_STOP_RING
        }
        val stopPendingIntent = PendingIntent.getService(
            this,
            0,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("Alarma de Guardian activa")
            .setContentText("El dispositivo está sonando por orden remota.")
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Detener",
                stopPendingIntent
            )
            .build()
    }
}
