package org.rattil.app

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
