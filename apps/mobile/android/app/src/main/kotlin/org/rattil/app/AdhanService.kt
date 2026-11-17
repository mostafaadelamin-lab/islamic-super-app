package org.rattil.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import androidx.core.app.NotificationCompat

/**
 * Foreground service that plays the whole adhan (res/raw/adhan_mulla.ogg or a downloaded recording, see assets/audio/ADHAN_AUDIO.md) at
 * prayer time, with a notification that has a Stop button. A notification sound alone can be cut short by the
 * system; a media-playback foreground service plays the recording to the end. It stops by itself when the adhan
 * ends, when the user taps Stop or swipes the notification, when another app takes the audio (e.g. a phone
 * call), and after a safety timeout. When the phone is on silent or vibrate it shows the notification only, unless
 * the user chose "adhan even when the phone is on silent": then it plays on the ALARM stream (alarm volume), which
 * Android lets ring in silent mode, like an alarm clock.
 */
class AdhanService : Service() {
    private var player: MediaPlayer? = null
    private var focus: AudioFocusRequest? = null
    private val handler = Handler(Looper.getMainLooper())

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }
        val title = intent?.getStringExtra(EXTRA_TITLE) ?: ""
        val body = intent?.getStringExtra(EXTRA_BODY) ?: ""
        val stop = intent?.getStringExtra(EXTRA_STOP) ?: "Stop"
        val voice = voiceUri(this, intent?.getStringExtra(EXTRA_VOICE))
        ensureChannels(this)
        val notification = buildNotification(title, body, stop)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        val audio = getSystemService(AudioManager::class.java)
        val playOnSilent = intent?.getBooleanExtra(EXTRA_SILENT, false) ?: false
        if (audio.ringerMode != AudioManager.RINGER_MODE_NORMAL && !playOnSilent) {
            // Silent / vibrate: keep the notification, no sound.
            stopForeground(STOP_FOREGROUND_DETACH)
            stopSelf()
            return START_NOT_STICKY
        }
        play(audio, voice)
        handler.postDelayed({ stopSelf() }, MAX_PLAY_MS)
        return START_NOT_STICKY
    }

    private fun play(audio: AudioManager, voice: Uri) {
        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val listener = AudioManager.OnAudioFocusChangeListener { change ->
            if (change == AudioManager.AUDIOFOCUS_LOSS || change == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT) stopSelf()
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val req = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                .setAudioAttributes(attrs)
                .setOnAudioFocusChangeListener(listener)
                .build()
            focus = req
            audio.requestAudioFocus(req)
        } else {
            @Suppress("DEPRECATION")
            audio.requestAudioFocus(listener, AudioManager.STREAM_ALARM, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
        }
        player = MediaPlayer().apply {
            setAudioAttributes(attrs)
            setDataSource(this@AdhanService, voice)
            setWakeMode(this@AdhanService, PowerManager.PARTIAL_WAKE_LOCK)
            setOnCompletionListener { stopSelf() }
            setOnErrorListener { _, _, _ -> stopSelf(); true }
            prepare()
            start()
        }
    }

    private fun buildNotification(title: String, body: String, stop: String): Notification {
        val stopIntent = PendingIntent.getService(
            this, 0, Intent(this, AdhanService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val open = packageManager.getLaunchIntentForPackage(packageName)?.let {
            PendingIntent.getActivity(this, 0, it, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        }
        return NotificationCompat.Builder(this, PLAYING_CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_rattil)
            .setContentTitle(title)
            .setContentText(body)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(open)
            .setDeleteIntent(stopIntent)
            .addAction(0, stop, stopIntent)
            .setAutoCancel(true)
            .build()
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        player?.run {
            try { stop() } catch (_: IllegalStateException) {}
            release()
        }
        player = null
        val audio = getSystemService(AudioManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focus?.let { audio.abandonAudioFocusRequest(it) }
        }
        super.onDestroy()
    }

    companion object {
        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"
        const val EXTRA_STOP = "stop"
        const val EXTRA_VOICE = "voice"
        const val EXTRA_SILENT = "playOnSilent"

        /**
         * The chosen muezzin: a recording the user downloaded (absolute path inside the app's own storage), or a
         * res/raw recording by name (adhan*). Anything else, or a file that is gone, falls back to the default
         * adhan (Sheikh Ali Mulla, Makkah Haram; the only bundled ones are adhan_mulla and adhan_daghriri_fajr).
         */
        fun voiceUri(ctx: Context, name: String?): Uri {
            if (name != null && name.startsWith("/")) {
                val f = java.io.File(name)
                val own = f.canonicalPath.startsWith(ctx.filesDir.parentFile!!.canonicalPath)
                if (own && f.isFile && f.length() > 0) return Uri.fromFile(f)
            }
            return Uri.parse("android.resource://${ctx.packageName}/${rawVoice(ctx, name)}")
        }

        /** The res/raw recording called [name] (only adhan* names), else the default adhan (adhan_mulla). */
        fun rawVoice(ctx: Context, name: String?): Int {
            if (name == null || !name.matches(Regex("adhan[a-z0-9_]*"))) return R.raw.adhan_mulla
            val id = ctx.resources.getIdentifier(name, "raw", ctx.packageName)
            return if (id != 0) id else R.raw.adhan_mulla
        }
        const val ACTION_STOP = "org.rattil.app.ADHAN_STOP"
        private const val NOTIFICATION_ID = 7_000_001
        private const val PLAYING_CHANNEL = "adhan_full"
        private const val FALLBACK_CHANNEL = "adhan_voice_adhan_mulla"
        private const val MAX_PLAY_MS = 6 * 60 * 1000L

        /** The playing notification's channel has no sound of its own: the service plays the adhan. */
        fun ensureChannels(ctx: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            val nm = ctx.getSystemService(NotificationManager::class.java)
            if (nm.getNotificationChannel(PLAYING_CHANNEL) == null) {
                nm.createNotificationChannel(
                    NotificationChannel(PLAYING_CHANNEL, "الأذان كاملًا · Full adhan", NotificationManager.IMPORTANCE_HIGH)
                        .apply {
                            description = "Plays the whole adhan at prayer time"
                            setSound(null, null)
                        },
                )
            }
        }

        /** Used when the service may not start: a plain notification on the adhan-sound channel. */
        fun postFallbackNotification(ctx: Context, title: String, body: String) {
            val nm = ctx.getSystemService(NotificationManager::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && nm.getNotificationChannel(FALLBACK_CHANNEL) == null) {
                val attrs = AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_NOTIFICATION).build()
                nm.createNotificationChannel(
                    NotificationChannel(FALLBACK_CHANNEL, "الأذان · Adhan", NotificationManager.IMPORTANCE_HIGH).apply {
                        setSound(Uri.parse("android.resource://${ctx.packageName}/${R.raw.adhan_mulla}"), attrs)
                    },
                )
            }
            val n = NotificationCompat.Builder(ctx, FALLBACK_CHANNEL)
                .setSmallIcon(R.drawable.ic_stat_rattil)
                .setContentTitle(title)
                .setContentText(body)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setAutoCancel(true)
                .build()
            try {
                nm.notify(NOTIFICATION_ID + 1, n)
            } catch (_: SecurityException) {
                // Notifications not allowed.
            }
        }
    }
}
