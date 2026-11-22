package org.rattil.app

import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject
import java.util.Calendar

/**
 * Colours and helpers shared by the home-screen widgets. The background follows the colour style
 * the user picked in the app ("pal" in the widget data: madinah, the default, or emerald); the
 * next prayer and the countdown are in that style's gold.
 */
object WidgetStyle {
    fun palette(json: String?): String = try {
        if (json == null) "madinah" else JSONObject(json).optString("pal", "madinah")
    } catch (e: Exception) {
        "madinah"
    }

    fun background(palette: String): Int =
        if (palette == "emerald") R.drawable.widget_bg_emerald else R.drawable.widget_bg_madinah

    fun gold(palette: String): Int = Color.parseColor(if (palette == "emerald") "#D4AF5A" else "#D9B25E")

    /** Right-to-left in Arabic whatever the phone's own language is. */
    fun direction(views: RemoteViews, id: Int, arabic: Boolean) {
        views.setInt(id, "setLayoutDirection", if (arabic) View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR)
    }

    fun digits(s: String, ar: Boolean): String {
        if (!ar) return s
        val b = StringBuilder()
        for (c in s) b.append(if (c in '0'..'9') ('٠' + (c - '0')) else c)
        return b.toString()
    }

    /** "5:22 ص" / "5:22 AM" (12 h) or "05:22" / "17:22" (24 h). */
    fun clock(ms: Long, h12: Boolean, ar: Boolean): String {
        val cal = Calendar.getInstance().apply { timeInMillis = ms }
        val m = cal.get(Calendar.MINUTE).toString().padStart(2, '0')
        if (!h12) return digits("${cal.get(Calendar.HOUR_OF_DAY).toString().padStart(2, '0')}:$m", ar)
        val h = cal.get(Calendar.HOUR).let { if (it == 0) 12 else it }
        val pm = cal.get(Calendar.AM_PM) == Calendar.PM
        val suffix = if (ar) (if (pm) "م" else "ص") else (if (pm) "PM" else "AM")
        return digits("$h:$m", ar) + " " + suffix
    }
}
