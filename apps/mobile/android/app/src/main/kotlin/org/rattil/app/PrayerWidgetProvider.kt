package org.rattil.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.os.SystemClock
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.util.Calendar

/**
 * Home-screen widget: Hijri date, the current time, the next prayer and the
 * time left to it, inside a ring that fills from the previous prayer to the
 * next one. Data: seven days written by lib/data/home_widget_sync.dart; the app
 * schedules a redraw at every prayer and every 10 minutes.
 */
class PrayerWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val info = NextPrayer.from(widgetData.getString("rattil.widget", null), System.currentTimeMillis())
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.prayer_widget)
            val ar = info?.arabic ?: true
            views.setImageViewBitmap(R.id.widget_ring, ring(info?.fraction ?: 0f))
            if (info == null) {
                views.setTextViewText(R.id.widget_hijri, "")
                views.setTextViewText(R.id.widget_prayer, if (ar) "افتح التطبيق" else "Open the app")
                views.setViewVisibility(R.id.widget_left, android.view.View.GONE)
            } else {
                views.setTextViewText(R.id.widget_hijri, digits(info.hijri, ar))
                views.setTextViewText(R.id.widget_prayer, info.name)
                views.setViewVisibility(R.id.widget_left, android.view.View.VISIBLE)
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

    private fun digits(s: String, ar: Boolean): String {
        if (!ar) return s
        val b = StringBuilder()
        for (c in s) b.append(if (c in '0'..'9') ('٠' + (c - '0')) else c)
        return b.toString()
    }

    /** Dark disc, a thin track and the amber arc of the time already passed. */
    private fun ring(fraction: Float): Bitmap {
        val size = 360
        val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        val stroke = 14f
        val inset = stroke / 2 + 2
        val oval = RectF(inset, inset, size - inset, size - inset)
        val disc = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.parseColor("#E61F2430") }
        c.drawOval(oval, disc)
        val track = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE; strokeWidth = stroke; color = Color.parseColor("#33FFFFFF")
        }
        c.drawOval(oval, track)
        val arc = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE; strokeWidth = stroke; strokeCap = Paint.Cap.ROUND
            color = Color.parseColor("#F2B33D")
        }
        c.drawArc(oval, -90f, 360f * fraction.coerceIn(0f, 1f), false, arc)
        val line = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.parseColor("#55FFFFFF"); strokeWidth = 2f }
        c.drawLine(size * 0.12f, size * 0.56f, size * 0.88f, size * 0.56f, line)
        return bmp
    }
}

/** The next prayer from the stored days (previous prayer may be yesterday's Isha). */
data class NextPrayer(
    val name: String,
    val at: Long,
    val fraction: Float,
    val hijri: String,
    val arabic: Boolean,
) {
    companion object {
        fun from(json: String?, now: Long): NextPrayer? {
            if (json == null) return null
            return try {
                val root = JSONObject(json)
                val arabic = root.optString("lang", "ar") != "en"
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
                for (i in 0 until days.length()) {
                    val d = days.getJSONObject(i)
                    val p = d.getJSONArray("p")
                    for (j in 0 until p.length()) {
                        val e = p.getJSONArray(j)
                        val at = e.getLong(2)
                        if (at > now) {
                            val start = prev ?: (at - 6 * 3600 * 1000L)
                            val frac = ((now - start).toFloat() / (at - start).toFloat())
                            return NextPrayer(e.getString(1), at, frac, hijriToday.ifEmpty { d.getString("h") }, arabic)
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
