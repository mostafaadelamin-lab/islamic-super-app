package org.rattil.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject

/**
 * Prayer-time alarms that play the FULL adhan (guideline: Android AlarmManager exact alarms + a foreground
 * service). Each alarm is an exact, allow-while-idle AlarmManager alarm that wakes AdhanAlarmReceiver, which
 * starts AdhanService (a media-playback foreground service) to play the chosen adhan (res/raw/adhan_mulla.ogg, adhan_daghriri_fajr.ogg or a downloaded recording) to the end, with a Stop
 * button. Alarms are kept in SharedPreferences so they are set again after a reboot, an app update or a clock /
 * time-zone change (AlarmManager forgets them).
 */
object AdhanAlarms {
    /** [voice]: name of the res/raw recording of the muezzin the user chose ("adhan" = the first one). */
    data class Alarm(
        val id: Int,
        val atMillis: Long,
        val title: String,
        val body: String,
        val stopLabel: String,
        val voice: String = "adhan",
        /** Play the adhan even when the phone is on silent / vibrate (the user's choice, off by default). */
        val playOnSilent: Boolean = false,
    ) {
        fun toJson(): JSONObject = JSONObject()
            .put("id", id).put("at", atMillis).put("title", title).put("body", body).put("stop", stopLabel)
            .put("voice", voice).put("silent", playOnSilent)

        companion object {
            fun fromJson(o: JSONObject) = Alarm(
                o.getInt("id"), o.getLong("at"), o.optString("title"), o.optString("body"), o.optString("stop", "Stop"),
                o.optString("voice", "adhan"), o.optBoolean("silent", false),
            )
        }
    }

    const val ACTION_FIRE = "org.rattil.app.ADHAN_FIRE"
    const val EXTRA_ID = "id"
    private const val PREFS = "rattil_adhan_alarms"
    private const val KEY = "alarms"

    fun load(ctx: Context): List<Alarm> {
        val raw = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null) ?: return emptyList()
        val arr = JSONArray(raw)
        return (0 until arr.length()).map { Alarm.fromJson(arr.getJSONObject(it)) }
    }

    private fun save(ctx: Context, alarms: List<Alarm>) {
        val arr = JSONArray()
        alarms.forEach { arr.put(it.toJson()) }
        ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(KEY, arr.toString()).apply()
    }

    fun schedule(ctx: Context, alarm: Alarm) {
        save(ctx, load(ctx).filter { it.id != alarm.id } + alarm)
        set(ctx, alarm)
    }

    fun find(ctx: Context, id: Int): Alarm? = load(ctx).firstOrNull { it.id == id }

    fun remove(ctx: Context, id: Int) = save(ctx, load(ctx).filter { it.id != id })

    fun cancelAll(ctx: Context) {
        val am = ctx.getSystemService(AlarmManager::class.java)
        load(ctx).forEach { am.cancel(pending(ctx, it.id)) }
        save(ctx, emptyList())
    }

    /** After boot / update / clock change: drop past alarms and set the future ones again. */
    fun rescheduleAll(ctx: Context) {
        val now = System.currentTimeMillis()
        val future = load(ctx).filter { it.atMillis > now }
        save(ctx, future)
        future.forEach { set(ctx, it) }
    }

    fun canScheduleExact(ctx: Context): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            ctx.getSystemService(AlarmManager::class.java).canScheduleExactAlarms()

    private fun set(ctx: Context, alarm: Alarm) {
        val am = ctx.getSystemService(AlarmManager::class.java)
        val pi = pending(ctx, alarm.id)
        if (canScheduleExact(ctx)) {
            am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, alarm.atMillis, pi)
        } else {
            // Without the exact-alarm permission Android may deliver it some minutes late.
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, alarm.atMillis, pi)
        }
    }

    private fun pending(ctx: Context, id: Int): PendingIntent = PendingIntent.getBroadcast(
        ctx,
        id,
        Intent(ctx, AdhanAlarmReceiver::class.java).setAction(ACTION_FIRE).putExtra(EXTRA_ID, id),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
}
