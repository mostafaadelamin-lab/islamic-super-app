package org.rattil.app

import android.app.Activity
import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.view.Surface
import io.flutter.plugin.common.EventChannel

/**
 * Streams the device heading in degrees clockwise from MAGNETIC north (the top of the screen), from Android's
 * fused rotation-vector sensor (accelerometer + magnetometer + gyroscope, calibrated by the system). Falls back
 * to the geomagnetic rotation vector. Emits an error when the phone has neither, and the Dart side then uses the
 * raw accelerometer + magnetometer. The Dart side adds the magnetic declination to get true north.
 */
class HeadingStream(private val activity: Activity) : EventChannel.StreamHandler, SensorEventListener {
    private val sensors = activity.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private var sink: EventChannel.EventSink? = null
    private val rotation = FloatArray(9)
    private val remapped = FloatArray(9)
    private var lastAccuracyDeg = -100.0

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        val sensor = sensors.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
            ?: sensors.getDefaultSensor(Sensor.TYPE_GEOMAGNETIC_ROTATION_VECTOR)
        if (sensor == null) {
            events.error("no_sensor", "No rotation-vector sensor", null)
            return
        }
        sink = events
        sensors.registerListener(this, sensor, SensorManager.SENSOR_DELAY_UI)
        // Only for its calibration status (onAccuracyChanged): tells the user to calibrate.
        sensors.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)?.let {
            sensors.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL)
        }
    }

    override fun onCancel(arguments: Any?) {
        sensors.unregisterListener(this)
        sink = null
    }

    override fun onSensorChanged(event: SensorEvent) {
        if (event.sensor.type == Sensor.TYPE_MAGNETIC_FIELD) return
        // values[4]: the sensor's own estimate of the heading error, in radians (-1 when unknown).
        if (event.values.size > 4 && event.values[4] >= 0f) {
            val acc = Math.toDegrees(event.values[4].toDouble())
            if (Math.abs(acc - lastAccuracyDeg) >= 2.0) {
                lastAccuracyDeg = acc
                sink?.success(mapOf("acc" to acc))
            }
        }
        SensorManager.getRotationMatrixFromVector(rotation, event.values)
        // Keep "up" = the top of the screen in every display rotation.
        val (x, y) = when (displayRotation()) {
            Surface.ROTATION_90 -> SensorManager.AXIS_Y to SensorManager.AXIS_MINUS_X
            Surface.ROTATION_180 -> SensorManager.AXIS_MINUS_X to SensorManager.AXIS_MINUS_Y
            Surface.ROTATION_270 -> SensorManager.AXIS_MINUS_Y to SensorManager.AXIS_X
            else -> SensorManager.AXIS_X to SensorManager.AXIS_Y
        }
        SensorManager.remapCoordinateSystem(rotation, x, y, remapped)
        // Heading of (screen-top minus screen-normal) projected on the ground: the same as getOrientation's
        // azimuth when the phone lies flat, and still steady when it is held upright (where the plain azimuth
        // swings wildly because the screen-top points at the sky).
        val east = (remapped[1] - remapped[2]).toDouble()
        val north = (remapped[4] - remapped[5]).toDouble()
        if (east * east + north * north < 1e-6) return
        val deg = (Math.toDegrees(Math.atan2(east, north)) + 360.0) % 360.0
        sink?.success(deg)
    }

    /** SENSOR_STATUS_UNRELIABLE (0) / ACCURACY_LOW (1) on the magnetometer = the compass needs calibrating. */
    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        if (sensor?.type == Sensor.TYPE_MAGNETIC_FIELD) sink?.success(mapOf("cal" to accuracy))
    }

    @Suppress("DEPRECATION")
    private fun displayRotation(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) activity.display?.rotation ?: Surface.ROTATION_0
        else activity.windowManager.defaultDisplay.rotation
}
