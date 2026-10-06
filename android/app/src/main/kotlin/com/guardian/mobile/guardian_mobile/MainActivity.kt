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
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
