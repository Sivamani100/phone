package com.antigravity.callin.callin

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.database.sqlite.SQLiteDatabase
import android.os.Build
import android.os.IBinder
import android.telecom.Call
import android.telecom.InCallService
import android.util.Log
import androidx.core.app.NotificationCompat

object CallManager {
    var activeCall: Call? = null
    var activeService: CallInService? = null
    var wasCallAnswered = false
    var isIncomingCall = false
    var hasCheckedMissed = false
}

class CallInService : InCallService() {
    private val TAG = "CallInService"

    companion object {
        const val CHANNEL_INCOMING = "callin_incoming"
        const val CHANNEL_INCALL   = "callin_incall"
        const val CHANNEL_MISSED   = "callin_missed"
        const val NOTIF_INCOMING   = 1001
        const val NOTIF_INCALL     = 1002

        const val ACTION_ANSWER  = "com.antigravity.callin.ACTION_ANSWER"
        const val ACTION_DECLINE = "com.antigravity.callin.ACTION_DECLINE"
    }

    // ── Notification action receiver ────────────────────────────────────────
    private val actionReceiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context?, intent: Intent?) {
            when (intent?.action) {
                ACTION_ANSWER -> {
                    CallManager.activeCall?.answer(0)
                    // Bring app to foreground
                    val i = Intent(this@CallInService, MainActivity::class.java).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                    }
                    startActivity(i)
                    cancelNotification(NOTIF_INCOMING)
                }
                ACTION_DECLINE -> {
                    CallManager.activeCall?.disconnect()
                    cancelNotification(NOTIF_INCOMING)
                    cancelNotification(NOTIF_INCALL)
                }
                "com.antigravity.callin.DISCONNECT_NUMBER" -> {
                    val number = intent.getStringExtra("number")
                    Log.d(TAG, "Received DISCONNECT_NUMBER broadcast for: $number")
                    val activeCall = CallManager.activeCall
                    if (activeCall != null) {
                        val activeNumber = activeCall.details?.handle?.schemeSpecificPart ?: ""
                        if (number != null && activeNumber.isNotEmpty()) {
                            val cleanNumber = number.replace(Regex("\\D"), "")
                            val cleanActive = activeNumber.replace(Regex("\\D"), "")
                            if (cleanNumber.isNotEmpty() && cleanActive.isNotEmpty() && (cleanActive.endsWith(cleanNumber) || cleanNumber.endsWith(cleanActive))) {
                                Log.d(TAG, "Disconnecting active call from blocked number: $activeNumber")
                                activeCall.disconnect()
                                cancelNotification(NOTIF_INCOMING)
                                cancelNotification(NOTIF_INCALL)
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Call state callback ──────────────────────────────────────────────────
    private val callCallback = object : Call.Callback() {
        override fun onStateChanged(call: Call, state: Int) {
            super.onStateChanged(call, state)
            Log.d(TAG, "onStateChanged: state = $state")
            sendCallStateBroadcast(call, state)

            // Show ongoing in-call notification once connected; cancel incoming banner
            when (state) {
                Call.STATE_ACTIVE -> {
                    CallManager.wasCallAnswered = true
                    cancelNotification(NOTIF_INCOMING)
                    showInCallNotification(call.details?.handle?.schemeSpecificPart ?: "")
                }
                Call.STATE_DISCONNECTED, Call.STATE_DISCONNECTING -> {
                    cancelNotification(NOTIF_INCOMING)
                    cancelNotification(NOTIF_INCALL)
                    checkAndPostMissedCall(call)
                }
            }
        }
    }

    // ── Lifecycle ────────────────────────────────────────────────────────────
    override fun onBind(intent: Intent): IBinder? {
        Log.d(TAG, "onBind")
        CallManager.activeService = this
        createNotificationChannels()
        val filter = IntentFilter().apply {
            addAction(ACTION_ANSWER)
            addAction(ACTION_DECLINE)
            addAction("com.antigravity.callin.DISCONNECT_NUMBER")
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(actionReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(actionReceiver, filter)
        }
        return super.onBind(intent)
    }

    override fun onUnbind(intent: Intent): Boolean {
        Log.d(TAG, "onUnbind")
        CallManager.activeService = null
        try { unregisterReceiver(actionReceiver) } catch (_: Exception) {}
        cancelNotification(NOTIF_INCOMING)
        cancelNotification(NOTIF_INCALL)
        return super.onUnbind(intent)
    }

    private fun isNumberBlockedInDb(context: Context, number: String): Boolean {
        val dbFile = context.getDatabasePath("callin_phone.db")
        if (!dbFile.exists()) {
            Log.d(TAG, "isNumberBlockedInDb: DB file does not exist at ${dbFile.absolutePath}")
            return false
        }
        try {
            SQLiteDatabase.openDatabase(dbFile.absolutePath, null, SQLiteDatabase.OPEN_READONLY).use { db ->
                val cleanNumber = number.replace(Regex("\\D"), "")
                if (cleanNumber.isEmpty()) return false
                db.rawQuery("SELECT phone FROM blocked_numbers", null).use { cursor ->
                    if (cursor.moveToFirst()) {
                        do {
                            val blockedPhone = cursor.getString(0) ?: continue
                            val cleanBlocked = blockedPhone.replace(Regex("\\D"), "")
                            if (cleanBlocked.isNotEmpty()) {
                                if (cleanNumber.endsWith(cleanBlocked) || cleanBlocked.endsWith(cleanNumber)) {
                                    return true
                                }
                            }
                        } while (cursor.moveToNext())
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking blocked number in DB: ${e.message}", e)
        }
        return false
    }

    override fun onCallAdded(call: Call) {
        super.onCallAdded(call)
        Log.d(TAG, "onCallAdded: $call")

        val number = call.details?.handle?.schemeSpecificPart ?: ""
        if (isNumberBlockedInDb(this, number)) {
            Log.d(TAG, "onCallAdded: Blocked number $number detected. Rejecting call immediately.")
            call.disconnect()
            return
        }

        CallManager.activeCall = call
        CallManager.wasCallAnswered = false
        CallManager.isIncomingCall = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            call.details?.callDirection == Call.Details.DIRECTION_INCOMING
        } else {
            call.state == Call.STATE_RINGING
        }
        CallManager.hasCheckedMissed = false
        call.registerCallback(callCallback)
        
        val isIncoming = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            call.details?.callDirection == Call.Details.DIRECTION_INCOMING
        } else {
            call.state == Call.STATE_RINGING
        }

        val stateStr = when (call.state) {
            Call.STATE_RINGING              -> "ringing"
            Call.STATE_DIALING              -> "dialing"
            Call.STATE_ACTIVE               -> "connected"
            Call.STATE_HOLDING              -> "hold"
            Call.STATE_DISCONNECTED         -> "disconnected"
            Call.STATE_CONNECTING           -> "connecting"
            Call.STATE_SELECT_PHONE_ACCOUNT -> "connecting"
            else                            -> "unknown"
        }

        // Always bring app to foreground (handles lock screen / background)
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra("CALL_INCOMING", isIncoming)
            putExtra("CALL_NUMBER", number)
            putExtra("CALL_STATE", stateStr)
        }
        startActivity(launchIntent)

        // Show heads-up notification for incoming calls so user can answer
        // from notification shade without unlocking
        if (call.state == Call.STATE_RINGING) {
            showIncomingCallNotification(number)
        }

        sendCallStateBroadcast(call, call.state)
    }

    override fun onCallRemoved(call: Call) {
        super.onCallRemoved(call)
        Log.d(TAG, "onCallRemoved: $call")
        checkAndPostMissedCall(call)
        call.unregisterCallback(callCallback)
        if (CallManager.activeCall == call) CallManager.activeCall = null

        cancelNotification(NOTIF_INCOMING)
        cancelNotification(NOTIF_INCALL)

        val intent = Intent("com.antigravity.callin.CALL_STATE").apply {
            putExtra("state", "disconnected")
            putExtra("number", call.details?.handle?.schemeSpecificPart ?: "")
        }
        sendBroadcast(intent)
    }

    // ── Notification helpers ─────────────────────────────────────────────────
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(NotificationManager::class.java)

            // Incoming call channel — max importance for heads-up
            val incoming = NotificationChannel(
                CHANNEL_INCOMING,
                "Incoming Calls",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Shows incoming call alerts"
                setSound(null, null) // system already plays ringtone
                enableVibration(true)
            }

            // In-call channel — low importance, just a status bar chip
            val inCall = NotificationChannel(
                CHANNEL_INCALL,
                "Active Call",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows ongoing call status"
                setSound(null, null)
                enableVibration(false)
            }

            // Missed call channel — default/low importance, but makes a sound/vibrates once
            val missed = NotificationChannel(
                CHANNEL_MISSED,
                "Missed Calls",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Shows missed call notifications"
                enableVibration(true)
            }

            nm.createNotificationChannel(incoming)
            nm.createNotificationChannel(inCall)
            nm.createNotificationChannel(missed)
        }
    }

    private fun getContactName(context: Context, phoneNumber: String): String? {
        if (phoneNumber.isEmpty()) return null
        try {
            val uri = android.net.Uri.withAppendedPath(
                android.provider.ContactsContract.PhoneLookup.CONTENT_FILTER_URI,
                android.net.Uri.encode(phoneNumber)
            )
            val projection = arrayOf(android.provider.ContactsContract.PhoneLookup.DISPLAY_NAME)
            context.contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    return cursor.getString(cursor.getColumnIndexOrThrow(android.provider.ContactsContract.PhoneLookup.DISPLAY_NAME))
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error looking up contact name: ${e.message}")
        }
        return null
    }

    private fun checkAndPostMissedCall(call: Call) {
        if (CallManager.hasCheckedMissed) return
        CallManager.hasCheckedMissed = true

        val number = call.details?.handle?.schemeSpecificPart ?: ""
        val isIncoming = CallManager.isIncomingCall
        val answered = CallManager.wasCallAnswered

        Log.d(TAG, "checkAndPostMissedCall: number=$number, isIncoming=$isIncoming, answered=$answered")

        if (isIncoming && !answered) {
            val contactName = getContactName(this, number)
            showMissedCallNotification(number, contactName)
        }
    }

    private fun showMissedCallNotification(number: String, contactName: String?) {
        val displayName = contactName ?: if (number.isEmpty()) "Unknown Number" else number

        val notification = NotificationCompat.Builder(this, CHANNEL_MISSED)
            .setSmallIcon(android.R.drawable.stat_notify_missed_call)
            .setContentTitle("Missed Call")
            .setContentText(displayName)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setCategory(NotificationCompat.CATEGORY_MISSED_CALL)
            .setContentIntent(makeOpenAppPendingIntent())
            .setAutoCancel(true)
            .build()

        val nm = getSystemService(NotificationManager::class.java)
        val notifId = (System.currentTimeMillis() % 100000).toInt() + 2000
        nm.notify(notifId, notification)
    }

    private fun makePendingBroadcast(action: String, requestCode: Int): PendingIntent {
        val intent = Intent(action).setPackage(packageName)
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        else
            PendingIntent.FLAG_UPDATE_CURRENT
        return PendingIntent.getBroadcast(this, requestCode, intent, flags)
    }

    private fun makeOpenAppPendingIntent(): PendingIntent {
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        else
            PendingIntent.FLAG_UPDATE_CURRENT
        return PendingIntent.getActivity(this, 0, intent, flags)
    }

    private fun showIncomingCallNotification(number: String) {
        val displayNumber = if (number.isEmpty()) "Unknown" else number

        val notification = NotificationCompat.Builder(this, CHANNEL_INCOMING)
            .setSmallIcon(android.R.drawable.ic_menu_call)
            .setContentTitle("Incoming Call")
            .setContentText(displayNumber)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setFullScreenIntent(makeOpenAppPendingIntent(), true)
            .setContentIntent(makeOpenAppPendingIntent())
            .setOngoing(true)
            .setAutoCancel(false)
            .addAction(
                android.R.drawable.ic_menu_call,
                "Answer",
                makePendingBroadcast(ACTION_ANSWER, 1)
            )
            .addAction(
                android.R.drawable.ic_delete,
                "Decline",
                makePendingBroadcast(ACTION_DECLINE, 2)
            )
            .build()

        val nm = getSystemService(NotificationManager::class.java)
        nm.notify(NOTIF_INCOMING, notification)
    }

    private fun showInCallNotification(number: String) {
        val displayNumber = if (number.isEmpty()) "Active Call" else number

        val notification = NotificationCompat.Builder(this, CHANNEL_INCALL)
            .setSmallIcon(android.R.drawable.ic_menu_call)
            .setContentTitle("Call in progress")
            .setContentText(displayNumber)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setContentIntent(makeOpenAppPendingIntent())
            .setOngoing(true)
            .setAutoCancel(false)
            .addAction(
                android.R.drawable.ic_delete,
                "End Call",
                makePendingBroadcast(ACTION_DECLINE, 3)
            )
            .build()

        val nm = getSystemService(NotificationManager::class.java)
        nm.notify(NOTIF_INCALL, notification)
    }

    private fun cancelNotification(id: Int) {
        val nm = getSystemService(NotificationManager::class.java)
        nm.cancel(id)
    }

    // ── State broadcast ──────────────────────────────────────────────────────
    private fun sendCallStateBroadcast(call: Call, state: Int) {
        val stateStr = when (state) {
            Call.STATE_RINGING              -> "ringing"
            Call.STATE_DIALING              -> "dialing"
            Call.STATE_ACTIVE               -> "connected"
            Call.STATE_HOLDING              -> "hold"
            Call.STATE_DISCONNECTED         -> "disconnected"
            Call.STATE_CONNECTING           -> "connecting"
            Call.STATE_SELECT_PHONE_ACCOUNT -> "connecting"
            else                            -> "unknown"
        }
        val number = call.details?.handle?.schemeSpecificPart ?: ""
        sendBroadcast(Intent("com.antigravity.callin.CALL_STATE").apply {
            putExtra("state", stateStr)
            putExtra("number", number)
        })
    }
}
