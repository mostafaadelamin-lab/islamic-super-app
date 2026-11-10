package org.rattil.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat

/** Starts the adhan at prayer time; sets the alarms again after reboot, app update or a clock change. */
class AdhanAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        when (intent.action) {
            AdhanAlarms.ACTION_FIRE -> {
                val id = intent.getIntExtra(AdhanAlarms.EXTRA_ID, -1)
                val alarm = AdhanAlarms.find(ctx, id) ?: return
                AdhanAlarms.remove(ctx, id)
                // A prayer alarm delivered very late (phone was off) is not worth an adhan any more.
                if (System.currentTimeMillis() - alarm.atMillis > STALE_MS) return
                val service = Intent(ctx, AdhanService::class.java)
                    .putExtra(AdhanService.EXTRA_TITLE, alarm.title)
                    .putExtra(AdhanService.EXTRA_BODY, alarm.body)
                    .putExtra(AdhanService.EXTRA_STOP, alarm.stopLabel)
                    .putExtra(AdhanService.EXTRA_VOICE, alarm.voice)
                try {
                    // Allowed from the background because an exact alarm just fired.
                    ContextCompat.startForegroundService(ctx, service)
                } catch (e: Exception) {
                    // e.g. ForegroundServiceStartNotAllowedException when the alarm was inexact: still tell the
                    // user, with the adhan notification sound (the opening of the adhan).
                    AdhanService.postFallbackNotification(ctx, alarm.title, alarm.body)
                }
            }
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            "android.intent.action.QUICKBOOT_POWERON",
            -> AdhanAlarms.rescheduleAll(ctx)
        }
    }

    companion object {
        private const val STALE_MS = 10 * 60 * 1000L
    }
}
