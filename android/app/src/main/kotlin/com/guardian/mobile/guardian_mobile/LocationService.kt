package com.guardian.mobile.guardian_mobile

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*
import java.util.Date

class LocationService : Service() {
    companion object {
        private const val TAG = "LocationService"
        private const val NOTIFICATION_ID = 2001
        private const val CHANNEL_ID = "guardian_location_tracking_channel"

        const val ACTION_START = "ACTION_START_LOCATION_SERVICE"
        const val ACTION_STOP = "ACTION_STOP_LOCATION_SERVICE"

        fun start(context: Context) {
            val intent = Intent(context, LocationService::class.java).apply {
                action = ACTION_START
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, LocationService::class.java).apply {
                action = ACTION_STOP
            }
            context.stopService(intent)
        }
    }

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private var locationCallback: LocationCallback? = null

    private var heartbeatHandler = Handler(Looper.getMainLooper())
    private var heartbeatRunnable: Runnable? = null
    private val HEARTBEAT_INTERVAL_MS = 2 * 60 * 1000L // 2 minutes

    override fun onCreate() {
        super.onCreate()
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: ACTION_START
        if (action == ACTION_STOP) {
            stopLocationTracking()
            stopHeartbeat()
            DeviceStatusReporter.stopListening(this)
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }

        val notification = createNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        startLocationTracking()
        startHeartbeat()
        DeviceStatusReporter.startListening(this)
        return START_STICKY
    }

    override fun onDestroy() {
        stopLocationTracking()
        stopHeartbeat()
        DeviceStatusReporter.stopListening(this)
        super.onDestroy()
    }

    private fun startHeartbeat() {
        stopHeartbeat()
        heartbeatRunnable = object : Runnable {
            override fun run() {
                DeviceStatusReporter.reportStatusNow(applicationContext)
                heartbeatHandler.postDelayed(this, HEARTBEAT_INTERVAL_MS)
            }
        }
        heartbeatHandler.post(heartbeatRunnable!!)
    }

    private fun stopHeartbeat() {
        heartbeatRunnable?.let {
            heartbeatHandler.removeCallbacks(it)
            heartbeatRunnable = null
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Rastreo de Ubicación Guardian",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notificación obligatoria mientras el servicio de protección y ubicación esté activo"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = if (launchIntent != null) {
            PendingIntent.getActivity(
                this,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        } else null

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Guardian protege este teléfono")
            .setContentText("Rastreo y monitoreo de ubicación en segundo plano activo")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setContentIntent(pendingIntent)
            .build()
    }

    @SuppressLint("MissingPermission")
    private fun startLocationTracking() {
        if (!LocationHelper.hasLocationPermission(this)) {
            Log.w(TAG, "Cannot start location tracking: Location permission missing")
            return
        }

        val intervalMinutes = LocationPreferences.getIntervalMinutes(this)
        val intervalMillis = (intervalMinutes * 60 * 1000L).coerceAtLeast(300000L) // Min 5 min

        Log.i(TAG, "Starting periodic location tracking every $intervalMinutes minutes ($intervalMillis ms)")

        stopLocationTracking()

        val locationRequest = LocationRequest.Builder(
            Priority.PRIORITY_BALANCED_POWER_ACCURACY,
            intervalMillis
        )
            .setMinUpdateIntervalMillis(intervalMillis / 2)
            .build()

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                val loc = locationResult.lastLocation ?: return
                Log.i(TAG, "Periodic location update received: lat=${loc.latitude}, lon=${loc.longitude}")

                Thread {
                    // Try to flush offline queue first
                    OfflineLocationQueue.flushQueue(applicationContext)

                    val iso = LocationHelper.formatIsoTimestamp(Date(loc.time))
                    val success = LocationReporterClient.reportSingleLocation(
                        context = applicationContext,
                        latitude = loc.latitude,
                        longitude = loc.longitude,
                        accuracyMeters = if (loc.hasAccuracy()) loc.accuracy else null,
                        speedMps = if (loc.hasSpeed()) loc.speed else null,
                        recordedAtIso = iso,
                        source = "PERIODIC"
                    )

                    if (!success) {
                        OfflineLocationQueue.enqueue(
                            context = applicationContext,
                            latitude = loc.latitude,
                            longitude = loc.longitude,
                            accuracyMeters = if (loc.hasAccuracy()) loc.accuracy else null,
                            speedMps = if (loc.hasSpeed()) loc.speed else null,
                            recordedAtIso = iso,
                            source = "PERIODIC"
                        )
                    }
                }.start()
            }
        }

        try {
            fusedLocationClient.requestLocationUpdates(
                locationRequest,
                locationCallback as LocationCallback,
                Looper.getMainLooper()
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error requesting location updates: ${e.message}", e)
        }
    }

    private fun stopLocationTracking() {
        locationCallback?.let {
            fusedLocationClient.removeLocationUpdates(it)
            locationCallback = null
        }
    }
}
