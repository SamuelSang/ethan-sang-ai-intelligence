package com.deviceinspector.device_inspector

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.deviceinspector/android"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "openSettings" -> {
                        val page = call.argument<String>("page") ?: "APPLICATION_SETTINGS"
                        val settingsPage = DeepLinkHandler.SettingsPage.fromString(page)
                        val success = DeepLinkHandler.open(settingsPage, this)
                        result.success(mapOf("success" to success, "page" to page))
                    }
                    "getDeviceInfo" -> {
                        val deviceInfo = AdbService.getDeviceInfo()
                        result.success(deviceInfo)
                    }
                    "getBatteryInfo" -> {
                        val batteryInfo = AdbService.getBatteryInfo(this)
                        result.success(batteryInfo)
                    }
                    "checkActivationLock" -> {
                        val hasLock = AdbService.checkActivationLock()
                        val accessibilityDetected = DeviceInspectorAccessibility.lastDetectedKeyword
                        result.success(mapOf(
                            "hasLock" to hasLock,
                            "frpEnabled" to hasLock,
                            "accessibilityKeyword" to accessibilityDetected
                        ))
                    }
                    "isAdbAuthorized" -> {
                        val authorized = AdbService.isAdbAuthorized()
                        result.success(mapOf("authorized" to authorized))
                    }
                    "isAccessibilityEnabled" -> {
                        val enabled = DeviceInspectorAccessibility.isRunning
                        result.success(mapOf("enabled" to enabled))
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("NATIVE_ERROR", e.message, e.stackTraceToString())
            }
        }
    }
}