package com.guardian.mobile.guardian_mobile

import android.content.Context
import android.content.Intent
import android.content.ComponentName
import android.app.admin.DevicePolicyManager
import android.os.Build
import android.os.PowerManager
import android.os.Vibrator
import android.os.VibratorManager
import android.os.VibrationEffect
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.guardian.mobile/native_bridge"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveDeviceCredentials" -> {
                    val apiBaseUrl = call.argument<String>("apiBaseUrl")
                    val deviceId = call.argument<String>("deviceId")
                    val deviceToken = call.argument<String>("deviceToken")

                    if (apiBaseUrl != null && deviceId != null && deviceToken != null) {
                        NativeSecurityStorage.saveDeviceCredentials(
                            context = applicationContext,
                            apiBaseUrl = apiBaseUrl,
                            deviceId = deviceId,
                            deviceToken = deviceToken
                        )
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Missing credentials arguments", null)
                    }
                }
                "clearDeviceCredentials" -> {
                    NativeSecurityStorage.clearDeviceCredentials(applicationContext)
                    result.success(true)
                }
                "executeLocalCommand" -> {
                    val type = call.argument<String>("type") ?: ""
                    val commandId = call.argument<String>("commandId") ?: ""
                    when (type.uppercase()) {
                        "LOCK" -> {
                            try {
                                val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as? DevicePolicyManager
                                val comp = ComponentName(applicationContext, GuardianDeviceAdminReceiver::class.java)
                                if (dpm != null && dpm.isAdminActive(comp)) {
                                    dpm.lockNow()
                                    result.success(true)
                                } else {
                                    result.error("ADMIN_NOT_ACTIVE", "Permiso de Administrador no activo para bloquear", null)
                                }
                            } catch (e: Exception) {
                                result.error("LOCK_ERROR", e.message, null)
                            }
                        }
                        "VIBRATE" -> {
                            try {
                                val durationSeconds = call.argument<Int>("durationSeconds") ?: 5
                                val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                    (getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager)?.defaultVibrator
                                } else {
                                    @Suppress("DEPRECATION")
                                    getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
                                }
                                if (vibrator != null && vibrator.hasVibrator()) {
                                    val pattern = LongArray(durationSeconds * 2) { index ->
                                        if (index % 2 == 0) 800L else 200L
                                    }
                                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                        vibrator.vibrate(VibrationEffect.createWaveform(pattern, -1))
                                    } else {
                                        @Suppress("DEPRECATION")
                                        vibrator.vibrate(pattern, -1)
                                    }
                                    result.success(true)
                                } else {
                                    result.error("NO_VIBRATOR", "Hardware de vibración no disponible", null)
                                }
                            } catch (e: Exception) {
                                result.error("VIBRATE_ERROR", e.message, null)
                            }
                        }
                        "RING" -> {
                            try {
                                val durationSeconds = call.argument<Int>("durationSeconds") ?: 8
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
                                result.success(true)
                            } catch (e: Exception) {
                                result.error("RING_ERROR", e.message, null)
                            }
                        }
                        "MESSAGE" -> {
                            try {
                                val text = call.argument<String>("text") ?: "Mensaje de seguridad"
                                val phone = call.argument<String>("contactPhone")
                                val messageIntent = Intent(applicationContext, MessageActivity::class.java).apply {
                                    putExtra(MessageActivity.EXTRA_MESSAGE_TEXT, text)
                                    putExtra(MessageActivity.EXTRA_CONTACT_PHONE, phone)
                                    putExtra(MessageActivity.EXTRA_COMMAND_ID, commandId)
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                                }
                                startActivity(messageIntent)
                                result.success(true)
                            } catch (e: Exception) {
                                result.error("MESSAGE_ERROR", e.message, null)
                            }
                        }
                        else -> {
                            result.error("UNKNOWN_TYPE", "Tipo de comando no soportado: $type", null)
                        }
                    }
                }
                "isBatteryOptimizationIgnored" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                        val isIgnored = pm.isIgnoringBatteryOptimizations(packageName)
                        result.success(isIgnored)
                    } else {
                        result.success(true)
                    }
                }
                "requestIgnoreBatteryOptimization" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        try {
                            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                data = Uri.parse("package:$packageName")
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            try {
                                val fallbackIntent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                                startActivity(fallbackIntent)
                                result.success(true)
                            } catch (e2: Exception) {
                                result.error("INTENT_ERROR", e2.message, null)
                            }
                        }
                    } else {
                        result.success(true)
                    }
                }
                "isDeviceAdminActive" -> {
                    val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as? android.app.admin.DevicePolicyManager
                    val comp = android.content.ComponentName(applicationContext, GuardianDeviceAdminReceiver::class.java)
                    val active = dpm?.isAdminActive(comp) ?: false
                    result.success(active)
                }
                "requestEnableDeviceAdmin" -> {
                    try {
                        val comp = android.content.ComponentName(applicationContext, GuardianDeviceAdminReceiver::class.java)
                        val intent = Intent(android.app.admin.DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                            putExtra(android.app.admin.DevicePolicyManager.EXTRA_DEVICE_ADMIN, comp)
                            putExtra(
                                android.app.admin.DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                                "Requerido para bloquear la pantalla y permitir el restablecimiento de fábrica (borrado remoto de seguridad) ante pérdida o robo."
                            )
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ADMIN_INTENT_ERROR", e.message, null)
                    }
                }
                "syncDeviceCapabilities" -> {
                    val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as? android.app.admin.DevicePolicyManager
                    val comp = android.content.ComponentName(applicationContext, GuardianDeviceAdminReceiver::class.java)
                    val adminActive = dpm?.isAdminActive(comp) ?: false

                    val pm = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        getSystemService(Context.POWER_SERVICE) as PowerManager
                    } else null
                    val batteryIgnored = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && pm != null) {
                        pm.isIgnoringBatteryOptimizations(packageName)
                    } else true

                    val hasNotifications = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) == android.content.pm.PackageManager.PERMISSION_GRANTED
                    } else true

                    val hasFgLocation = LocationHelper.hasLocationPermission(applicationContext)
                    val hasBgLocation = LocationHelper.hasBackgroundLocationPermission(applicationContext)

                    DeviceCapabilityClient.reportCapabilities(
                        context = applicationContext,
                        adminEnabled = adminActive,
                        notificationsGranted = hasNotifications,
                        locationForegroundGranted = hasFgLocation,
                        locationBackgroundGranted = hasBgLocation,
                        batteryOptimizationIgnored = batteryIgnored,
                        fullScreenIntentGranted = true
                    )
                    result.success(adminActive)
                }
                "hasLocationPermission" -> {
                    result.success(LocationHelper.hasLocationPermission(applicationContext))
                }
                "hasBackgroundLocationPermission" -> {
                    result.success(LocationHelper.hasBackgroundLocationPermission(applicationContext))
                }
                "requestForegroundLocationPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        requestPermissions(
                            arrayOf(
                                android.Manifest.permission.ACCESS_FINE_LOCATION,
                                android.Manifest.permission.ACCESS_COARSE_LOCATION
                            ),
                            1001
                        )
                    }
                    result.success(true)
                }
                "requestBackgroundLocationPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        requestPermissions(
                            arrayOf(android.Manifest.permission.ACCESS_BACKGROUND_LOCATION),
                            1002
                        )
                    }
                    result.success(true)
                }
                "openAppSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.fromParts("package", packageName, null)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("APP_SETTINGS_ERROR", e.message, null)
                    }
                }
                "isPeriodicLocationEnabled" -> {
                    result.success(LocationPreferences.isPeriodicEnabled(applicationContext))
                }
                "setPeriodicLocationEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    LocationPreferences.setPeriodicEnabled(applicationContext, enabled)
                    if (enabled) {
                        LocationService.start(applicationContext)
                    } else {
                        LocationService.stop(applicationContext)
                    }
                    result.success(true)
                }
                "getLocationIntervalMinutes" -> {
                    result.success(LocationPreferences.getIntervalMinutes(applicationContext))
                }
                "setLocationIntervalMinutes" -> {
                    val minutes = call.argument<Int>("minutes") ?: 15
                    LocationPreferences.setIntervalMinutes(applicationContext, minutes)
                    if (LocationPreferences.isPeriodicEnabled(applicationContext)) {
                        LocationService.start(applicationContext) // Restarts with new interval
                    }
                    result.success(true)
                }
                "flushOfflineLocations" -> {
                    Thread {
                        OfflineLocationQueue.flushQueue(applicationContext)
                    }.start()
                    result.success(true)
                }
                "getCurrentLocation" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val loc = LocationHelper.getSingleHighAccuracyLocation(applicationContext, timeoutMs = 15000L)
                            if (loc != null) {
                                val iso = LocationHelper.formatIsoTimestamp(java.util.Date(loc.time))
                                val success = LocationReporterClient.reportSingleLocation(
                                    context = applicationContext,
                                    latitude = loc.latitude,
                                    longitude = loc.longitude,
                                    accuracyMeters = loc.accuracy,
                                    speedMps = if (loc.hasSpeed()) loc.speed else null,
                                    recordedAtIso = iso,
                                    source = "MANUAL"
                                )
                                withContext(Dispatchers.Main) {
                                    result.success(
                                        mapOf(
                                            "latitude" to loc.latitude,
                                            "longitude" to loc.longitude,
                                            "accuracy" to loc.accuracy.toDouble(),
                                            "reported" to success
                                        )
                                    )
                                }
                            } else {
                                withContext(Dispatchers.Main) {
                                    result.error("LOCATION_UNAVAILABLE", "No se pudo obtener la posición GPS", null)
                                }
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("LOCATION_ERROR", e.message, null)
                            }
                        }
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
