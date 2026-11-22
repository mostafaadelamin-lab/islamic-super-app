package org.rattil.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.util.Calendar

/**
 * Small home-screen widget (owner 2026-11-22: no circle, like the iPhone lock-screen widget): the
 * next prayer's name, its time and a live countdown, on the user's colour style. Data: seven days
 * written by lib/data/home_widget_sync.dart; the app schedules a redraw at every prayer.
 */
class PrayerWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val json = widgetData.getString("rattil.widget", null)
        val info = NextPrayer.from(json, System.currentTimeMillis())
        val pal = WidgetStyle.palette(json)
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.prayer_widget)
            views.setInt(R.id.widget_root, "setBackgroundResource", WidgetStyle.background(pal))
            views.setTextColor(R.id.widget_left, WidgetStyle.gold(pal))
            if (info == null) {
                views.setTextViewText(R.id.widget_prayer, "رتّل وصلِّ")
                views.setTextViewText(R.id.widget_time, "افتح التطبيق")
                views.setViewVisibility(R.id.widget_left, View.GONE)
            } else {
                views.setTextViewText(R.id.widget_prayer, info.name)
                views.setTextViewText(R.id.widget_time, WidgetStyle.clock(info.at, info.clock12, info.arabic))
                views.setViewVisibility(R.id.widget_left, View.VISIBLE)
                // Counts down live without waking the app.
                val base = SystemClock.elapsedRealtime() + (info.at - System.currentTimeMillis())
                views.setChronometer(R.id.widget_left, base, null, true)
                views.setChronometerCountDown(R.id.widget_left, true)
            }
            val open = context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?: Intent(context, MainActivity::class.java)
            views.setOnClickPendingIntent(
                R.id.widget_root,
                PendingIntent.getActivity(
                    context, 0, open,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                ),
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}

/** The next prayer from the stored days (previous prayer may be yesterday's Isha). */
data class NextPrayer(
    val name: String,
    val at: Long,
    val fraction: Float,
    val hijri: String,
    val arabic: Boolean,
    val clock12: Boolean = true,
) {
    companion object {
        fun from(json: String?, now: Long): NextPrayer? {
            if (json == null) return null
            return try {
                val root = JSONObject(json)
                val arabic = root.optString("lang", "ar") != "en"
                val clock12 = root.optBoolean("c12", true)
                val days = root.getJSONArray("days")
                var prev: Long? = null
                var hijriToday = ""
                val cal = Calendar.getInstance().apply { timeInMillis = now }
                val today = String.format(
                    "%04d-%02d-%02d", cal.get(Calendar.YEAR), cal.get(Calendar.MONTH) + 1, cal.get(Calendar.DAY_OF_MONTH),
                )
                for (i in 0 until days.length()) {
                    val d = days.getJSONObject(i)
                    if (d.getString("d") == today) hijriToday = d.getString("h")
                }
                // Between an adhan and its iqama (owner 2026-11-22): count down to the iqama.
                iqamaWait(days, now)?.let { (name, adhan, iq) ->
                    val frac = ((now - adhan).toFloat() / (iq - adhan).toFloat())
                    return NextPrayer((if (arabic) "إقامة " else "Iqama ") + name, iq, frac, hijriToday, arabic, clock12)
                }
                for (i in 0 until days.length()) {
                    val d = days.getJSONObject(i)
                    val p = d.getJSONArray("p")
                    for (j in 0 until p.length()) {
                        val e = p.getJSONArray(j)
                        val at = e.getLong(2)
                        if (at > now) {
                            val start = prev ?: (at - 6 * 3600 * 1000L)
                            val frac = ((now - start).toFloat() / (at - start).toFloat())
                            return NextPrayer(e.getString(1), at, frac, hijriToday.ifEmpty { d.getString("h") }, arabic, clock12)
                        }
                        prev = at
                    }
                }
                null
            } catch (e: Exception) {
                null
            }
        }
    }
}

/** (prayer name, adhan ms, iqama ms) when [now] is between an adhan and its iqama ("iq" of each day). */
fun iqamaWait(days: org.json.JSONArray, now: Long): Triple<String, Long, Long>? {
    for (i in 0 until days.length()) {
        val d = days.getJSONObject(i)
        val iq = d.optJSONArray("iq") ?: continue
        val p = d.getJSONArray("p")
        for (j in 0 until minOf(p.length(), iq.length())) {
            val e = p.getJSONArray(j)
            val adhan = e.getLong(2)
            val at = iq.getLong(j)
            if (now in adhan until at) return Triple(e.getString(1), adhan, at)
        }
    }
    return null
}
