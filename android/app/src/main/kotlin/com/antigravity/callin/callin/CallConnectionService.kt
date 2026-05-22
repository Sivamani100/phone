package com.antigravity.callin.callin

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.BroadcastReceiver
import android.os.Build
import android.os.Bundle
import android.telecom.Connection
import android.telecom.DisconnectCause
import android.telecom.ConnectionRequest
import android.telecom.ConnectionService
import android.telecom.PhoneAccount
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager
import android.net.Uri

class CallConnectionService : ConnectionService() {

    private val connectionsByNumber: MutableMap<String, Connection> = mutableMapOf()
    private var disconnectReceiver: BroadcastReceiver? = null

    override fun onCreate() {
        super.onCreate()
        // Listen for explicit disconnect requests from MainActivity
        val filter = IntentFilter("com.antigravity.callin.DISCONNECT_NUMBER")
        disconnectReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                val number = intent?.getStringExtra("number")
                if (number != null) {
                    connectionsByNumber[number]?.let { conn ->
                        conn.setDisconnected(DisconnectCause(DisconnectCause.LOCAL))
                        conn.destroy()
                        connectionsByNumber.remove(number)
                    }
                }
            }
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(disconnectReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(disconnectReceiver, filter)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        disconnectReceiver?.let { unregisterReceiver(it) }
    }

    override fun onCreateOutgoingConnection(connManagerPhoneAccount: PhoneAccountHandle?, request: ConnectionRequest?): Connection {
        val number = request?.address?.schemeSpecificPart ?: ""
        val connection = object : Connection() {
            override fun onAnswer() {
                setActive()
                sendStateBroadcast("answered", number)
            }

            override fun onDisconnect() {
                setDisconnected(DisconnectCause(DisconnectCause.LOCAL))
                destroy()
                sendStateBroadcast("disconnected", number)
                connectionsByNumber.remove(number)
            }

            override fun onHold() {
                setOnHold()
                sendStateBroadcast("hold", number)
            }

            override fun onUnhold() {
                setActive()
                sendStateBroadcast("unhold", number)
            }
        }
        connection.setDialing()
        connectionsByNumber[number] = connection
        sendStateBroadcast("dialing", number)
        return connection
    }

    override fun onCreateIncomingConnection(connManagerPhoneAccount: PhoneAccountHandle?, request: ConnectionRequest?): Connection {
        val number = request?.address?.schemeSpecificPart ?: ""
        val connection = object : Connection() {
            override fun onAnswer() {
                setActive()
                sendStateBroadcast("answered", number)
            }

            override fun onDisconnect() {
                setDisconnected(DisconnectCause(DisconnectCause.LOCAL))
                destroy()
                sendStateBroadcast("disconnected", number)
                connectionsByNumber.remove(number)
            }
        }
        connection.setRinging()
        connectionsByNumber[number] = connection
        sendStateBroadcast("ringing", number)
        return connection
    }

    private fun sendStateBroadcast(state: String, number: String?) {
        val intent = Intent("com.antigravity.callin.CALL_STATE")
        intent.putExtra("state", state)
        intent.putExtra("number", number)
        sendBroadcast(intent)
    }

    companion object {
        fun registerPhoneAccount(context: Context) {
            val telecomManager = context.getSystemService(Context.TELECOM_SERVICE) as TelecomManager
            val component = ComponentName(context, CallConnectionService::class.java)
            val handle = PhoneAccountHandle(component, "CallinAccount")
            val phoneAccount = PhoneAccount.builder(handle, "Callin")
                .setCapabilities(PhoneAccount.CAPABILITY_CALL_PROVIDER)
                .build()
            try {
                telecomManager.registerPhoneAccount(phoneAccount)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
