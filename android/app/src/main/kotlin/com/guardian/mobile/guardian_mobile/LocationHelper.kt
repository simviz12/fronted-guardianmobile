package com.guardian.mobile.guardian_mobile

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.os.Build
import android.os.Looper
import android.util.Log
import androidx.core.content.ContextCompat
import com.google.android.gms.location.*
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withTimeoutOrNull
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import kotlin.coroutines.resume

object LocationHelper {
    private const val TAG = "LocationHelper"

    fun hasLocationPermission(context: Context): Boolean {
        val fine = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        val coarse = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        return fine || coarse
    }

    fun hasBackgroundLocationPermission(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_BACKGROUND_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    fun formatIsoTimestamp(date: Date = Date()): String {
        val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
        sdf.timeZone = TimeZone.getTimeZone("UTC")
        return sdf.format(date)
    }

    @SuppressLint("MissingPermission")
    suspend fun getSingleHighAccuracyLocation(
        context: Context,
        timeoutMs: Long = 30000L
    ): Location? {
        if (!hasLocationPermission(context)) {
            Log.w(TAG, "Cannot get high accuracy fix: Location permissions not granted")
            return null
        }

        val fusedClient = LocationServices.getFusedLocationProviderClient(context)

        return withTimeoutOrNull(timeoutMs) {
            suspendCancellableCoroutine<Location?> { cont ->
                try {
                    val locationRequest = LocationRequest.Builder(
                        Priority.PRIORITY_HIGH_ACCURACY,
                        1000L
                    ).setMaxUpdates(1).build()

                    val callback = object : LocationCallback() {
                        override fun onLocationResult(result: LocationResult) {
                            fusedClient.removeLocationUpdates(this)
                            val loc = result.lastLocation
                            Log.i(TAG, "High accuracy location received: lat=${loc?.latitude}, lon=${loc?.longitude}")
                            if (cont.isActive) {
                                cont.resume(loc)
                            }
                        }

                        override fun onLocationAvailability(avail: LocationAvailability) {
                            if (!avail.isLocationAvailable) {
                                Log.w(TAG, "Location not available")
                            }
                        }
                    }

                    fusedClient.requestLocationUpdates(
                        locationRequest,
                        callback,
                        Looper.getMainLooper()
                    ).addOnFailureListener { e ->
                        Log.e(TAG, "Failed requesting location updates: ${e.message}")
                        if (cont.isActive) {
                            cont.resume(null)
                        }
                    }

                    cont.invokeOnCancellation {
                        fusedClient.removeLocationUpdates(callback)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error in getSingleHighAccuracyLocation: ${e.message}")
                    if (cont.isActive) {
                        cont.resume(null)
                    }
                }
            }
        }
    }
}
