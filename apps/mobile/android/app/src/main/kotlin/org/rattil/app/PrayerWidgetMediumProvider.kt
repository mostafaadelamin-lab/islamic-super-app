package org.rattil.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

/**
 * Medium home-screen widget (owner 2026-11-20): the day name, the Hijri and Gregorian dates, a live
 * countdown to the next prayer, and the six times of the day (Fajr, sunrise, Dhuhr, Asr, Maghrib,
 * Isha) with the next prayer highlighted. Same data as [PrayerWidgetProvider]; the app schedules a
 * redraw at every prayer and after midnight.
 */
class PrayerWidgetMediumProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val now = System.currentTimeMillis()
        val day = MediumDay.from(widgetData.getString("rattil.widget", null), now)
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.prayer_widget_medium)
            if (day == null) {
                views.setTextViewText(R.id.widget_day, "رتّل وصلِّ")
                views.setTextViewText(R.id.widget_hijri, "افتح التطبيق · Open the app")
                views.setViewVisibility(R.id.widget_left, View.GONE)
            } else {
                val ar = day.arabic
                views.setTextViewText(R.id.widget_day, day.dayName)
                views.setTextViewText(R.id.widget_hijri, digits(day.hijri + if (ar) " هـ" else " AH", ar))
                views.setTextViewText(R.id.widget_greg, digits(day.gregorian, ar))
                val next = day.next
                if (next != null) {
                    views.setTextViewText(R.id.widget_prayer, if (ar) "${next.second} بعد" else "${next.second} in")
                    views.setViewVisibility(R.id.widget_left, View.VISIBLE)
                    val base = SystemClock.elapsedRealtime() + (next.third - now)
                    views.setChronometer(R.id.widget_left, base, null, true)
                    views.setChronometerCountDown(R.id.widget_left, true)
                } else {
                    views.setViewVisibility(R.id.widget_left, View.GONE)
                }
                for (i in 0 until 6) {
                    val t = day.times.getOrNull(i) ?: continue
                    val on = next != null && t.first == next.first && t.third == next.third
                    views.setTextViewText(NAME_IDS[i], t.second)
                    views.setTextViewText(TIME_IDS[i], digits(clock(t.third, day.clock12), ar))
                    views.setInt(CELL_IDS[i], "setBackgroundResource",
                        if (on) R.drawable.widget_cell_on else R.drawable.widget_cell_bg)
                    val ink = if (on) Color.parseColor("#1F2330") else Color.WHITE
                    views.setTextColor(NAME_IDS[i], ink)
                    views.setTextColor(TIME_IDS[i], ink)
                }
            }
            val open = context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?: Intent(context, MainActivity::class.java)
            views.setOnClickPendingIntent(
                R.id.widget_root,
                PendingIntent.getActivity(context, 1, open, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE),
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    companion object {
        private val CELL_IDS = intArrayOf(R.id.cell_0, R.id.cell_1, R.id.cell_2, R.id.cell_3, R.id.cell_4, R.id.cell_5)
        private val NAME_IDS = intArrayOf(R.id.name_0, R.id.name_1, R.id.name_2, R.id.name_3, R.id.name_4, R.id.name_5)
        private val TIME_IDS = intArrayOf(R.id.time_0, R.id.time_1, R.id.time_2, R.id.time_3, R.id.time_4, R.id.time_5)

        fun digits(s: String, ar: Boolean): String {
            if (!ar) return s
            val b = StringBuilder()
            for (c in s) b.append(if (c in '0'..'9') ('٠' + (c - '0')) else c)
            return b.toString()
        }

        /** "4:48" (12 h, no AM/PM: the cell is small) or "04:48" / "16:48" (24 h). */
        fun clock(ms: Long, h12: Boolean): String {
            val cal = Calendar.getInstance().apply { timeInMillis = ms }
            val m = cal.get(Calendar.MINUTE).toString().padStart(2, '0')
            if (!h12) return "${cal.get(Calendar.HOUR_OF_DAY).toString().padStart(2, '0')}:$m"
            val h = cal.get(Calendar.HOUR).let { if (it == 0) 12 else it }
            return "$h:$m"
        }
    }
}

/** Today's six times and the next prayer (which may be tomorrow's Fajr). */
data class MediumDay(
    val dayName: String,
    val hijri: String,
    val gregorian: String,
    /** (key, name, utc ms): fajr, sunrise, dhuhr, asr, maghrib, isha */
    val times: List<Triple<String, String, Long>>,
    val next: Triple<String, String, Long>?,
    val arabic: Boolean,
    val clock12: Boolean,
) {
    companion object {
        fun from(json: String?, now: Long): MediumDay? {
            if (json == null) return null
            return try {
                val root = JSONObject(json)
                val arabic = root.optString("lang", "ar") != "en"
                val clock12 = root.optBoolean("c12", true)
                val days = root.getJSONArray("days")
                val cal = Calendar.getInstance().apply { timeInMillis = now }
                val today = String.format(
                    Locale.US, "%04d-%02d-%02d",
                    cal.get(Calendar.YEAR), cal.get(Calendar.MONTH) + 1, cal.get(Calendar.DAY_OF_MONTH),
                )
                var todayJson: JSONObject? = null
                var next: Triple<String, String, Long>? = null
                for (i in 0 until days.length()) {
                    val d = days.getJSONObject(i)
                    if (d.getString("d") == today) todayJson = d
                    val p = d.getJSONArray("p")
                    for (j in 0 until p.length()) {
                        val e = p.getJSONArray(j)
                        if (next == null && e.getLong(2) > now) next = Triple(e.getString(0), e.getString(1), e.getLong(2))
                    }
                }
                val d = todayJson ?: return null
                val p = d.getJSONArray("p")
                val times = mutableListOf<Triple<String, String, Long>>()
                for (j in 0 until p.length()) {
                    val e = p.getJSONArray(j)
                    times.add(Triple(e.getString(0), e.getString(1), e.getLong(2)))
                    if (j == 0 && d.has("sr")) times.add(Triple("sunrise", if (arabic) "الشروق" else "Sunrise", d.getLong("sr")))
                }
                val locale = if (arabic) Locale("ar") else Locale.ENGLISH
                MediumDay(
                    dayName = SimpleDateFormat("EEEE", locale).format(cal.time),
                    hijri = d.getString("h"),
                    gregorian = SimpleDateFormat("d MMMM yyyy", locale).format(cal.time),
                    times = times,
                    next = next,
                    arabic = arabic,
                    clock12 = clock12,
                )
            } catch (e: Exception) {
                null
            }
        }
    }
}
