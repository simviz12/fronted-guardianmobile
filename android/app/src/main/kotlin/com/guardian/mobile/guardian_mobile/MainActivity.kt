package com.guardian.mobile.guardian_mobile

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

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
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
