package com.guardian.mobile.guardian_mobile

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

object NativeSecurityStorage {
    private const val PREFS_FILE = "guardian_secure_native_prefs"
    private const val KEY_API_BASE_URL = "api_base_url"
    private const val KEY_DEVICE_ID = "device_id"
    private const val KEY_DEVICE_TOKEN = "device_token"

    private fun getPrefs(context: Context): SharedPreferences {
        val masterKey = MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()

        return EncryptedSharedPreferences.create(
            context,
            PREFS_FILE,
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )
    }

    fun saveDeviceCredentials(
        context: Context,
        apiBaseUrl: String,
        deviceId: String,
        deviceToken: String
    ) {
        getPrefs(context).edit().apply {
            putString(KEY_API_BASE_URL, apiBaseUrl)
            putString(KEY_DEVICE_ID, deviceId)
            putString(KEY_DEVICE_TOKEN, deviceToken)
            apply()
        }
    }

    fun clearDeviceCredentials(context: Context) {
        getPrefs(context).edit().apply {
            remove(KEY_API_BASE_URL)
            remove(KEY_DEVICE_ID)
            remove(KEY_DEVICE_TOKEN)
            apply()
        }
    }

    fun getApiBaseUrl(context: Context): String? =
        getPrefs(context).getString(KEY_API_BASE_URL, null)

    fun getDeviceId(context: Context): String? =
        getPrefs(context).getString(KEY_DEVICE_ID, null)

    fun getDeviceToken(context: Context): String? =
        getPrefs(context).getString(KEY_DEVICE_TOKEN, null)

    // Theft Mode Storage
    private const val KEY_THEFT_MODE_ACTIVE = "theft_mode_active"
    private const val KEY_THEFT_MESSAGE = "theft_mode_message"
    private const val KEY_THEFT_CONTACT_PHONE = "theft_mode_contact_phone"
    private const val KEY_THEFT_INTERVAL_SEC = "theft_mode_interval_sec"

    fun saveTheftModeConfig(
        context: Context,
        message: String,
        contactPhone: String?,
        intervalSeconds: Int
    ) {
        getPrefs(context).edit().apply {
            putBoolean(KEY_THEFT_MODE_ACTIVE, true)
            putString(KEY_THEFT_MESSAGE, message)
            putString(KEY_THEFT_CONTACT_PHONE, contactPhone)
            putInt(KEY_THEFT_INTERVAL_SEC, intervalSeconds)
            apply()
        }
    }

    fun clearTheftModeConfig(context: Context) {
        getPrefs(context).edit().apply {
            remove(KEY_THEFT_MODE_ACTIVE)
            remove(KEY_THEFT_MESSAGE)
            remove(KEY_THEFT_CONTACT_PHONE)
            remove(KEY_THEFT_INTERVAL_SEC)
            apply()
        }
    }

    fun isTheftModeActive(context: Context): Boolean =
        getPrefs(context).getBoolean(KEY_THEFT_MODE_ACTIVE, false)

    fun getTheftMessage(context: Context): String? =
        getPrefs(context).getString(KEY_THEFT_MESSAGE, null)

    fun getTheftContactPhone(context: Context): String? =
        getPrefs(context).getString(KEY_THEFT_CONTACT_PHONE, null)

    fun getTheftIntervalSeconds(context: Context): Int =
        getPrefs(context).getInt(KEY_THEFT_INTERVAL_SEC, 60)
}
