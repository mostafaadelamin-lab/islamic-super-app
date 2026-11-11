package org.rattil.app

import android.content.Intent
import android.net.Uri
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

// AudioServiceActivity (a FlutterActivity) lets the recitation keep playing with the screen off.
class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        // Qibla compass: the system heading (rotation-vector sensor), see HeadingStream.kt.
        EventChannel(messenger, "org.rattil.app/heading").setStreamHandler(HeadingStream(this))
        // Nearby mosques: let the user pick the maps app (Google Maps, Waze, ...) for directions.
        MethodChannel(messenger, "org.rattil.app/maps").setMethodCallHandler { call, result ->
            if (call.method != "choose") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            try {
                val lat = call.argument<Double>("lat")!!
                val lng = call.argument<Double>("lng")!!
                val label = Uri.encode(call.argument<String>("name") ?: "")
                val geo = Uri.parse("geo:$lat,$lng?q=$lat,$lng($label)")
                val chooser = Intent.createChooser(Intent(Intent.ACTION_VIEW, geo), call.argument<String>("title") ?: "")
                chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(chooser)
                result.success(true)
            } catch (e: Exception) {
                result.success(false)
            }
        }
        // Full adhan at prayer time: exact alarm + foreground service, see AdhanAlarms.kt.
        MethodChannel(messenger, "org.rattil.app/adhan").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "schedule" -> {
                        AdhanAlarms.schedule(
                            applicationContext,
                            AdhanAlarms.Alarm(
                                id = call.argument<Int>("id")!!,
                                atMillis = call.argument<Number>("atMillis")!!.toLong(),
                                title = call.argument<String>("title") ?: "",
                                body = call.argument<String>("body") ?: "",
                                stopLabel = call.argument<String>("stopLabel") ?: "Stop",
                                voice = call.argument<String>("voice") ?: "adhan",
                            ),
                        )
                        result.success(null)
                    }
                    "cancelAll" -> {
                        AdhanAlarms.cancelAll(applicationContext)
                        result.success(null)
                    }
                    "pending" -> result.success(AdhanAlarms.load(applicationContext).size)
                    "canScheduleExact" -> result.success(AdhanAlarms.canScheduleExact(applicationContext))
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("adhan", e.message, null)
            }
        }
    }
}
