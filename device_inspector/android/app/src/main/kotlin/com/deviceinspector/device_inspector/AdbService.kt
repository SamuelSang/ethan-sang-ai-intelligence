package com.deviceinspector.device_inspector

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.util.Log

/**
 * Provides device inspection utilities:
 * - ADB authorization check
 * - Device hardware / OS information
 * - Battery status
 * - Factory Reset Protection (FRP / activation lock) detection
 */
object AdbService {

    private const val TAG = "AdbService"

    // ──────────────────────────────────────────────
    //  ADB authorization
    // ──────────────────────────────────────────────

    /**
     * Checks whether ADB debugging is enabled on this device by reading
     * the system property `persist.sys.usb.config`.
     *
     * Note: Running `adb devices` from on-device is not meaningful because the
     * adb *server* runs on the host machine. Instead we inspect system properties
     * to determine whether USB debugging is configured.
     *
     * @return `true` when USB debugging appears to be active.
     */
    fun isAdbAuthorized(): Boolean {
        return try {
            // Check ADB debugging enabled via system property
            val adbEnabled = getSystemProperty("persist.sys.usb.config")
            val adbDebugging = adbEnabled.contains("adb", ignoreCase = true)

            // Also check if ADB over network is enabled
            val adbPort = getSystemProperty("service.adb.tcp.port")
            val adbNetwork = adbPort.isNotBlank() && adbPort != "-1" && adbPort != "0"

            adbDebugging || adbNetwork
        } catch (e: Exception) {
            Log.e(TAG, "isAdbAuthorized failed: ${e.message}")
            false
        }
    }

    // ──────────────────────────────────────────────
    //  Device information
    // ──────────────────────────────────────────────

    /**
     * Gathers a comprehensive map of device information sourced from [Build]
     * constants and system properties.
     *
     * All values are nullable so the caller can safely forward the map over a
     * MethodChannel without worrying about missing keys.
     */
    fun getDeviceInfo(): Map<String, Any?> {
        return try {
            mapOf(
                "manufacturer"   to Build.MANUFACTURER,
                "brand"          to Build.BRAND,
                "model"          to Build.MODEL,
                "device"         to Build.DEVICE,
                "product"        to Build.PRODUCT,
                "hardware"       to Build.HARDWARE,
                "androidVersion" to Build.VERSION.RELEASE,
                "sdkVersion"     to Build.VERSION.SDK_INT,
                "buildId"        to Build.ID,
                "fingerprint"    to Build.FINGERPRINT,
                "serial"         to getSerialNumber(),
                "isAdbAuthorized" to isAdbAuthorized()
            )
        } catch (e: Exception) {
            Log.e(TAG, "getDeviceInfo failed: ${e.message}")
            mapOf("error" to e.message)
        }
    }

    // ──────────────────────────────────────────────
    //  Battery information
    // ──────────────────────────────────────────────

    /**
     * Reads battery status via a sticky broadcast [Intent].
     *
     * Unlike the old implementation this does **not** require an Activity context;
     * a plain [Context] is sufficient because we use [Context.registerReceiver]
     * with a `null` receiver to obtain the sticky [Intent.ACTION_BATTERY_CHANGED]
     * broadcast.
     *
     * @param context Any valid Android [Context].
     */
    fun getBatteryInfo(context: Context): Map<String, Any?> {
        return try {
            val batteryIntent: Intent? = IntentFilter(Intent.ACTION_BATTERY_CHANGED).let {
                context.registerReceiver(null, it)
            }

            if (batteryIntent == null) {
                return mapOf("error" to "Battery info unavailable")
            }

            val level = batteryIntent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
            val scale = batteryIntent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
            val status = batteryIntent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
            val health = batteryIntent.getIntExtra(BatteryManager.EXTRA_HEALTH, -1)
            val temperature = batteryIntent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1)
            val voltage = batteryIntent.getIntExtra(BatteryManager.EXTRA_VOLTAGE, -1)
            val plugged = batteryIntent.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1)
            val technology = batteryIntent.getStringExtra(BatteryManager.EXTRA_TECHNOLOGY)

            val percentage = if (level >= 0 && scale > 0) (level * 100 / scale) else -1
            val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                             status == BatteryManager.BATTERY_STATUS_FULL

            mapOf(
                "level"        to percentage,
                "isCharging"   to isCharging,
                "status"       to batteryStatusToString(status),
                "health"       to batteryHealthToString(health),
                "temperature"  to (temperature / 10.0),   // tenths-of-°C → °C
                "voltage"      to voltage,                 // mV
                "plugged"      to pluggedToString(plugged),
                "technology"   to technology
            )
        } catch (e: Exception) {
            Log.e(TAG, "getBatteryInfo failed: ${e.message}")
            mapOf("error" to e.message)
        }
    }

    // ──────────────────────────────────────────────
    //  Activation lock / FRP
    // ──────────────────────────────────────────────

    /**
     * Attempts to detect whether Factory Reset Protection (FRP) is active by
     * checking the `ro.frp.pst` system property. A non-empty value indicates
     * that FRP data exists on the device.
     */
    fun checkActivationLock(): Boolean {
        return try {
            val frpPartition = getSystemProperty("ro.frp.pst")
            val hasFrp = frpPartition.isNotBlank()

            // Additional check: persistent FRP state
            val frpState = getSystemProperty("ro.boot.verifiedbootstate")
            Log.d(TAG, "FRP partition=$frpPartition, bootState=$frpState")

            hasFrp
        } catch (e: Exception) {
            Log.e(TAG, "checkActivationLock failed: ${e.message}")
            false
        }
    }

    // ──────────────────────────────────────────────
    //  Private helpers
    // ──────────────────────────────────────────────

    /** Read a system property via `getprop`. */
    private fun getSystemProperty(key: String): String {
        return try {
            val process = Runtime.getRuntime().exec(arrayOf("getprop", key))
            val result = process.inputStream.bufferedReader().use { it.readText().trim() }
            process.waitFor()
            result
        } catch (e: Exception) {
            ""
        }
    }

    /** Best-effort serial number retrieval (restricted on API 29+). */
    @Suppress("DEPRECATION")
    private fun getSerialNumber(): String? {
        return try {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                Build.SERIAL
            } else {
                // Requires READ_PHONE_STATE on API 29+ – return null when unavailable
                null
            }
        } catch (e: SecurityException) {
            null
        }
    }

    private fun batteryStatusToString(status: Int): String = when (status) {
        BatteryManager.BATTERY_STATUS_CHARGING    -> "charging"
        BatteryManager.BATTERY_STATUS_DISCHARGING -> "discharging"
        BatteryManager.BATTERY_STATUS_FULL        -> "full"
        BatteryManager.BATTERY_STATUS_NOT_CHARGING -> "not_charging"
        else -> "unknown"
    }

    private fun batteryHealthToString(health: Int): String = when (health) {
        BatteryManager.BATTERY_HEALTH_GOOD           -> "good"
        BatteryManager.BATTERY_HEALTH_OVERHEAT       -> "overheat"
        BatteryManager.BATTERY_HEALTH_DEAD           -> "dead"
        BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE   -> "over_voltage"
        BatteryManager.BATTERY_HEALTH_COLD           -> "cold"
        BatteryManager.BATTERY_HEALTH_UNSPECIFIED_FAILURE -> "failure"
        else -> "unknown"
    }

    private fun pluggedToString(plugged: Int): String = when (plugged) {
        BatteryManager.BATTERY_PLUGGED_AC       -> "ac"
        BatteryManager.BATTERY_PLUGGED_USB      -> "usb"
        BatteryManager.BATTERY_PLUGGED_WIRELESS -> "wireless"
        else -> "none"
    }
}
