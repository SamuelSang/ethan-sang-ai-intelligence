package com.deviceinspector.device_inspector

import android.content.Context
import android.content.Intent
import android.provider.Settings

/**
 * Handles deep-link navigation to various Android system settings pages.
 *
 * Usage:
 *   DeepLinkHandler.open(DeepLinkHandler.SettingsPage.DEVICE_INFO, context)
 */
object DeepLinkHandler {

    /**
     * Enumeration of supported system settings pages.
     * Each entry maps to a standard [Settings] action string.
     */
    enum class SettingsPage(val action: String) {
        APPLICATION_SETTINGS(Settings.ACTION_APPLICATION_SETTINGS),
        PRIVACY_SETTINGS(Settings.ACTION_PRIVACY_SETTINGS),
        SECURITY_SETTINGS(Settings.ACTION_SECURITY_SETTINGS),
        DEVICE_INFO(Settings.ACTION_DEVICE_INFO_SETTINGS),
        ACCOUNTS(Settings.ACTION_SYNC_SETTINGS),
        BATTERY(Settings.ACTION_BATTERY_SAVER_SETTINGS),
        WIFI(Settings.ACTION_WIFI_SETTINGS),
        BLUETOOTH(Settings.ACTION_BLUETOOTH_SETTINGS),
        DISPLAY(Settings.ACTION_DISPLAY_SETTINGS),
        ACCESSIBILITY(Settings.ACTION_ACCESSIBILITY_SETTINGS);

        companion object {
            /**
             * Resolve a [SettingsPage] from its name string (case-insensitive).
             * Falls back to [APPLICATION_SETTINGS] when no match is found.
             */
            fun fromString(value: String): SettingsPage {
                return entries.find { it.name.equals(value, ignoreCase = true) }
                    ?: APPLICATION_SETTINGS
            }
        }
    }

    /**
     * Open the specified system settings [page].
     *
     * @param page    The target settings page.
     * @param context An Android [Context] used to launch the activity.
     * @return `true` if the intent was launched successfully, `false` otherwise.
     */
    fun open(page: SettingsPage, context: Context): Boolean {
        return try {
            val intent = Intent(page.action).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            android.util.Log.e("DeepLinkHandler", "Failed to open ${page.name}: ${e.message}")
            false
        }
    }
}
