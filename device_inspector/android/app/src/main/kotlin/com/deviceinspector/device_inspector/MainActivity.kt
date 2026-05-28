package com.deviceinspector.device_inspector

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.view.accessibility.AccessibilityEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.deviceinspector/android"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openSettings" -> {
                    val page = call.argument<String>("page") ?: "APPLICATION_SETTINGS"
                    val success = DeepLinkHandler.open(DeepLinkHandler.SettingsPage.fromString(page), this)
                    result.success(mapOf("success" to success))
                }
                "getDeviceInfo" -> {
                    val deviceInfo = AdbService.getDeviceInfo()
                    result.success(deviceInfo)
                }
                "checkActivationLock" -> {
                    val hasLock = AdbService.checkActivationLock()
                    result.success(mapOf("hasLock" to hasLock))
                }
                "isAdbAuthorized" -> {
                    val authorized = AdbService.isAdbAuthorized()
                    result.success(mapOf("authorized" to authorized))
                }
                else -> result.notImplemented()
            }
        }
    }
}

object DeepLinkHandler {
    enum class SettingsPage(val action: String) {
        APPLICATION_SETTINGS(Settings.ACTION_APPLICATION_SETTINGS),
        PRIVACY_SETTINGS(Settings.ACTION_PRIVACY_SETTINGS),
        SECURITY_SETTINGS(Settings.ACTION_SECURITY_SETTINGS),
        DEVICE_INFO(Settings.ACTION_DEVICE_INFO_SETTINGS),
        ACCOUNTS(Settings.ACTION_ACCOUNTS_SETTINGS),
        BATTERY(Settings.ACTION_BATTERY_SAVER_SETTINGS);

        companion object {
            fun fromString(value: String): SettingsPage {
                return entries.find { it.name.equals(value, ignoreCase = true) }
                    ?: APPLICATION_SETTINGS
            }
        }
    }

    fun open(page: SettingsPage, context: android.content.Context): Boolean {
        return try {
            val intent = Intent(page.action)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }
}

object AdbService {
    fun isAdbAuthorized(): Boolean {
        return try {
            val output = Runtime.getRuntime().exec("getprop persist.adb.secure").inputStream.bufferedReader().readText()
            output.trim() == "1"
        } catch (e: Exception) {
            false
        }
    }

    fun getDeviceInfo(): Map<String, Any?> {
        return try {
            val manufacturer = Build.MANUFACTURER
            val model = Build.MODEL
            val device = Build.DEVICE
            val version = Build.VERSION.RELEASE
            val sdk = Build.VERSION.SDK_INT

            mapOf(
                "manufacturer" to manufacturer,
                "model" to model,
                "device" to device,
                "androidVersion" to version,
                "sdkVersion" to sdk,
                "isAdbAuthorized" to isAdbAuthorized()
            )
        } catch (e: Exception) {
            mapOf("error" to e.message)
        }
    }

    fun getBatteryInfo(): Map<String, Any?> {
        return try {
            val intent = registerForActivityResult(android.app.Activity.ResultContracts.StartActivityForResult()) {
                // Battery info handled via system intent
            }
            val batteryManager = getSystemService(BATTERY_SERVICE) as android.os.BatteryManager
            val level = batteryManager.getIntProperty(android.os.BatteryManager.BATTERY_PROPERTY_CAPACITY)
            val isCharging = batteryManager.isCharging

            mapOf(
                "level" to level,
                "isCharging" to isCharging
            )
        } catch (e: Exception) {
            mapOf("error" to e.message)
        }
    }

    fun checkActivationLock(): Boolean {
        return try {
            // Check for Google account on device (FRP check)
            val output = Runtime.getRuntime().exec("getprop ro.frp.pst").inputStream.bufferedReader().readText()
            output.trim().isNotEmpty()
        } catch (e: Exception) {
            false
        }
    }
}

class DeviceInspectorAccessibility : AccessibilityService() {
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val content = event.text?.joinToString("") ?: ""
            // Detection logic for activation lock keywords
            if (content.contains("激活锁") || content.contains("FRP") ||
                content.contains("Google") || content.contains("factory reset")) {
                // Log detection for report
            }
        }
    }

    override fun onInterrupt() {
        // Service interrupted
    }

    override fun onServiceConnected() {
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
        }
        serviceInfo = info
    }
}