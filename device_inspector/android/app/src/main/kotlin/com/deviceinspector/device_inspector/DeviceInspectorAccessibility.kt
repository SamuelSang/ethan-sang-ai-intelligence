package com.deviceinspector.device_inspector

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.util.Log
import android.view.accessibility.AccessibilityEvent

/**
 * An [AccessibilityService] that monitors window-state changes to detect
 * activation-lock / FRP-related keywords on-screen.
 *
 * Detected keywords are stored in [lastDetectedKeyword] so the Flutter side
 * can query them through the MethodChannel.
 *
 * **Note**: The service must be enabled manually by the user via
 * Settings → Accessibility.
 */
class DeviceInspectorAccessibility : AccessibilityService() {

    companion object {
        private const val TAG = "DIAccessibility"

        /** Keywords that indicate an activation lock / FRP screen. */
        private val ACTIVATION_LOCK_KEYWORDS = listOf(
            "激活锁",
            "FRP",
            "Factory Reset Protection",
            "factory reset",
            "Google 账号验证",
            "Google Account",
            "Verify your account",
            "验证您的帐号",
            "设备已锁定",
            "Device is locked"
        )

        /**
         * `true` while the service is connected and active.
         * Accessible from Flutter via MethodChannel.
         */
        @Volatile
        var isRunning: Boolean = false
            private set

        /**
         * The last keyword that was detected on screen, or `null` if none has
         * been seen since the service started.
         */
        @Volatile
        var lastDetectedKeyword: String? = null
            private set

        /**
         * Monotonically increasing counter of how many times an activation-lock
         * keyword has been detected.
         */
        @Volatile
        var detectionCount: Int = 0
            private set
    }

    // ──────────────────────────────────────────────
    //  Lifecycle
    // ──────────────────────────────────────────────

    override fun onServiceConnected() {
        super.onServiceConnected()

        serviceInfo = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                         AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                    AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
            notificationTimeout = 100
        }

        isRunning = true
        Log.i(TAG, "Accessibility service connected")
    }

    override fun onDestroy() {
        isRunning = false
        Log.i(TAG, "Accessibility service destroyed")
        super.onDestroy()
    }

    // ──────────────────────────────────────────────
    //  Event handling
    // ──────────────────────────────────────────────

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                processEvent(event)
            }
        }
    }

    override fun onInterrupt() {
        Log.w(TAG, "Accessibility service interrupted")
    }

    // ──────────────────────────────────────────────
    //  Detection logic
    // ──────────────────────────────────────────────

    private fun processEvent(event: AccessibilityEvent) {
        // Collect visible text from the event
        val textContent = buildString {
            event.text?.forEach { append(it) }
            event.contentDescription?.let { append(" ").append(it) }
        }

        if (textContent.isBlank()) return

        // Check for any activation-lock keyword
        for (keyword in ACTIVATION_LOCK_KEYWORDS) {
            if (textContent.contains(keyword, ignoreCase = true)) {
                lastDetectedKeyword = keyword
                detectionCount++
                Log.w(TAG, "Activation lock keyword detected: \"$keyword\" " +
                           "(count=$detectionCount, source=${event.packageName})")
                break
            }
        }
    }
}
