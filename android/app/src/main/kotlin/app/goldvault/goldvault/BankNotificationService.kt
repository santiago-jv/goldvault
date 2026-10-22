package app.goldvault.goldvault

import android.app.Notification
import android.content.Context
import android.content.Intent
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import kotlin.concurrent.thread

class BankNotificationService : NotificationListenerService() {

    companion object {
        const val ACTION_BANK_EVENT = "app.goldvault.BANK_NOTIFICATION_CAPTURED"
        private const val SB_URL = "https://spjvxvmhosptezmteypm.supabase.co"
        private const val SB_KEY = "sb_publishable_uXP3oxhMoUXdsMDdIv71Cg_L1SA4C6B"

        private val WATCHED_PACKAGES = setOf(
            "com.nequi.mobileapp",
            "com.nu.production",
            "com.lulobank.app",
            "com.lulobank",
            "com.arq.app",
            "co.littio.app",
            "com.morse.app",
            "com.todo1.mobile",       // Bancolombia
            "com.daviplata.app"       // Daviplata
        )
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null || sbn.isOngoing) return
        val pkg = (sbn.packageName ?: "").lowercase()
        val extras = sbn.notification?.extras ?: return

        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()?.trim() ?: ""
        val text = (extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
            ?: extras.getCharSequence(Notification.EXTRA_TEXT))?.toString()?.trim() ?: ""

        if (text.isEmpty() && title.isEmpty()) return

        val combined = "$pkg $title $text".lowercase()
        val isTargetBank = WATCHED_PACKAGES.contains(pkg) ||
            combined.contains("nequi") ||
            combined.contains("nu bank") ||
            combined.contains("moradita") ||
            combined.contains("lulo") ||
            combined.contains("arq") ||
            combined.contains("littio") ||
            combined.contains("morse")

        if (!isTargetBank) return

        val prefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val enabled = prefs.getBoolean("flutter.gv_bank_listener_on", true)
        if (!enabled) return

        val token = prefs.getString("flutter.gv_webhook_token", null)

        // Notify the Flutter foreground UI if active
        val broadcast = Intent(ACTION_BANK_EVENT).apply {
            setPackage(applicationContext.packageName)
            putExtra("pkg", pkg)
            putExtra("title", title)
            putExtra("text", text)
        }
        sendBroadcast(broadcast)

        // If a webhook token is synced, persist directly to Supabase in the background
        if (!token.isNullOrBlank()) {
            thread {
                try {
                    val endpoint = URL("$SB_URL/rest/v1/rpc/ingest_bank_notification")
                    val conn = (endpoint.openConnection() as HttpURLConnection).apply {
                        requestMethod = "POST"
                        connectTimeout = 10000
                        readTimeout = 10000
                        doOutput = true
                        setRequestProperty("Content-Type", "application/json")
                        setRequestProperty("apikey", SB_KEY)
                        setRequestProperty("Authorization", "Bearer $SB_KEY")
                    }
                    val payload = JSONObject().apply {
                        put("p_token", token)
                        put("p_text", text)
                        put("p_title", title)
                        put("p_app", pkg)
                        put("p_fx", 4200)
                    }
                    OutputStreamWriter(conn.outputStream, Charsets.UTF_8).use { writer ->
                        writer.write(payload.toString())
                        writer.flush()
                    }
                    conn.responseCode
                    conn.disconnect()
                } catch (_: Exception) {
                }
            }
        }
    }
}
