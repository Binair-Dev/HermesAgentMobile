package com.nxg.hermesagentmobile

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.PowerManager

class SetupService : Service() {
    companion object {
        const val CHANNEL_ID = "hermes_setup"
        const val NOTIFICATION_ID = 4
        var isRunning = false
            private set
        private var instance: SetupService? = null

        fun start(context: Context) {
            val intent = Intent(context, SetupService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, SetupService::class.java)
            context.stopService(intent)
        }

        fun updateNotification(text: String, progress: Int = -1) {
            instance?.updateNotificationWith(text, progress)
        }
    }

    private var wakeLock: PowerManager.WakeLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIFICATION_ID, buildNotification("Setting up environment...", -1))
        if (isRunning) {
            return START_STICKY
        }
        isRunning = true
        instance = this
        acquireWakeLock()
        return START_STICKY
    }

    override fun onDestroy() {
        isRunning = false
        instance = null
        releaseWakeLock()
        super.onDestroy()
    }

    private fun acquireWakeLock() {
        releaseWakeLock()
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "Hermes Agent::SetupWakeLock"
        )
        wakeLock?.acquire(60 * 60 * 1000L) // 1 hour max
    }

    private fun releaseWakeLock() {
        wakeLock?.let {
            if (it.isHeld) it.release()
        }
        wakeLock = null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Hermes Agent Setup",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows progress during Hermes Agent environment setup"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    /**
     * Build notification with optional progress bar.
     * @param progress 0-100 for determinate bar, -1 for indeterminate spinner
     */
    private fun buildNotification(text: String, progress: Int): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        builder.setContentTitle("Hermes Agent Setup")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setContentIntent(pendingIntent)
            .setOngoing(true)

        if (progress in 0..100) {
            builder.setProgress(100, progress, false)
        } else {
            builder.setProgress(0, 0, true)
        }

        return builder.build()
    }

    fun updateNotificationWith(text: String, progress: Int) {
        try {
            val manager = getSystemService(NotificationManager::class.java)
            manager.notify(NOTIFICATION_ID, buildNotification(text, progress))
        } catch (_: Exception) {}
    }
}
