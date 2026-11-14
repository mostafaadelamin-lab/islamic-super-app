package org.rattil.app

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat

/**
 * What the first-run setup checks and the system screens it opens, so the adhan rings on time with the app closed.
 *
 * Store policy (Google Play): the app does NOT hold REQUEST_IGNORE_BATTERY_OPTIMIZATIONS and never shows the
 * one-tap "ignore battery optimizations" dialog; it opens the system list instead and the user picks the app.
 * It does not use "display over other apps" (SYSTEM_ALERT_WINDOW) or full-screen intents either: the adhan is an
 * exact alarm + a media-playback foreground service with a notification, which needs neither.
 */
object DeviceSetup {
    fun notificationsEnabled(a: Activity): Boolean = NotificationManagerCompat.from(a).areNotificationsEnabled()

    /** True when Android will not put the app to sleep (or on Android 5, which has no battery optimization). */
    fun ignoringBatteryOptimizations(a: Activity): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        return a.getSystemService(PowerManager::class.java).isIgnoringBatteryOptimizations(a.packageName)
    }

    /** The system "battery optimization" list (no special permission needed); falls back to the app's own page. */
    fun openBatterySettings(a: Activity): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            start(a, Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
        ) {
            return true
        }
        return openAppSettings(a)
    }

    /** Android 12+: the "Alarms & reminders" switch for this app. */
    fun openExactAlarmSettings(a: Activity): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return false
        val i = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, Uri.parse("package:${a.packageName}"))
        return start(a, i) || openAppSettings(a)
    }

    fun openNotificationSettings(a: Activity): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val i = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, a.packageName)
            if (start(a, i)) return true
        }
        return openAppSettings(a)
    }

    /** The app's page in system settings (some phones keep "auto-start" / "background activity" there). */
    fun openAppSettings(a: Activity): Boolean =
        start(a, Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${a.packageName}")))

    private fun start(a: Activity, i: Intent): Boolean = try {
        a.startActivity(i)
        true
    } catch (_: ActivityNotFoundException) {
        false
    } catch (_: SecurityException) {
        false
    }
}
