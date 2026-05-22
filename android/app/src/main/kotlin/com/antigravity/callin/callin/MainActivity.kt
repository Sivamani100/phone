package com.antigravity.callin.callin

import android.app.Activity
import android.app.role.RoleManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.telephony.SubscriptionManager
import android.telecom.CallAudioState
import android.telecom.TelecomManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val CHANNEL = "com.antigravity.callin/dialer"
	private var methodChannel: MethodChannel? = null

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		
		// Configure window to show over lock screen and turn screen on for incoming calls
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
			setShowWhenLocked(true)
			setTurnScreenOn(true)
		} else {
			@Suppress("DEPRECATION")
			window.addFlags(
				WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
				WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
				WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
				WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
			)
		}
	}

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

		// Handle platform method calls from Flutter
		methodChannel?.setMethodCallHandler { call, result ->
			when (call.method) {
				"requestDefaultDialer" -> {
					requestDefaultDialer()
					result.success(true)
				}
				"isDefaultDialer" -> {
					result.success(isDefaultDialer())
				}
				"getActiveSimCount" -> {
					result.success(getActiveSimCount())
				}
				"startCall" -> {
					val args = call.arguments as? Map<*, *>
					val number = args?.get("number") as? String
					if (number != null) {
						// Ask Flutter if this number is blocked (block outgoing too)
						methodChannel?.invokeMethod("isBlocked", mapOf("number" to number), object : MethodChannel.Result {
							override fun success(blockResult: Any?) {
								val blocked = blockResult as? Boolean ?: false
								if (blocked) {
									result.success(false)
								} else {
									try {
										CallConnectionService.registerPhoneAccount(this@MainActivity)
									} catch (e: Exception) {
										// ignore
									}
									try {
										val telecomManager = getSystemService(Context.TELECOM_SERVICE) as TelecomManager
										val uri = Uri.parse("tel:$number")
										val extras = Bundle()
										telecomManager.placeCall(uri, extras)
										result.success(true)
									} catch (e: SecurityException) {
										// Fallback to standard ACTION_CALL intent if permission is missing
										val intent = Intent(Intent.ACTION_CALL)
										intent.data = Uri.parse("tel:$number")
										intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
										startActivity(intent)
										result.success(true)
									} catch (e: Exception) {
										result.error("ERROR", "Failed to place call: ${e.message}", null)
									}
								}
							}

							override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
								result.error(errorCode, errorMessage, errorDetails)
							}

							override fun notImplemented() {
								result.notImplemented()
							}
						})
					} else {
						result.error("INVALID_ARGS", "Missing number", null)
					}
				}
				"answerCall" -> {
					try {
						CallManager.activeCall?.answer(0)
						result.success(true)
					} catch (e: Exception) {
						result.error("ERROR", "Failed to answer call: ${e.message}", null)
					}
				}
				"endCall" -> {
					try {
						CallManager.activeCall?.disconnect()
						result.success(true)
					} catch (e: Exception) {
						result.error("ERROR", "Failed to end call: ${e.message}", null)
					}
				}
				"setMute" -> {
					try {
						val muted = call.argument<Boolean>("muted") ?: false
						CallManager.activeService?.setMuted(muted)
						result.success(true)
					} catch (e: Exception) {
						result.error("ERROR", "Failed to mute call: ${e.message}", null)
					}
				}
				"setSpeaker" -> {
					try {
						val enabled = call.argument<Boolean>("enabled") ?: false
						val route = if (enabled) CallAudioState.ROUTE_SPEAKER else CallAudioState.ROUTE_EARPIECE
						CallManager.activeService?.setAudioRoute(route)
						result.success(true)
					} catch (e: Exception) {
						result.error("ERROR", "Failed to set speaker: ${e.message}", null)
					}
				}
				"setHold" -> {
					try {
						val hold = call.argument<Boolean>("hold") ?: false
						if (hold) {
							CallManager.activeCall?.hold()
						} else {
							CallManager.activeCall?.unhold()
						}
						result.success(true)
					} catch (e: Exception) {
						result.error("ERROR", "Failed to set hold: ${e.message}", null)
					}
				}
				"playDtmfTone" -> {
					try {
						val digit = call.argument<String>("digit") ?: ""
						if (digit.isNotEmpty()) {
							val dtmfChar = digit[0]
							CallManager.activeCall?.playDtmfTone(dtmfChar)
							CallManager.activeCall?.stopDtmfTone()
						}
						result.success(true)
					} catch (e: Exception) {
						result.error("ERROR", "Failed to play DTMF tone: ${e.message}", null)
					}
				}
				else -> result.notImplemented()
			}
		}

		// Register a receiver to get call state broadcasts from InCallService and ConnectionService
		val filter = IntentFilter("com.antigravity.callin.CALL_STATE")
		val receiver = object : BroadcastReceiver() {
			override fun onReceive(context: Context?, intent: Intent?) {
				val state = intent?.getStringExtra("state")
				val number = intent?.getStringExtra("number")
				if (state != null) {
					methodChannel?.invokeMethod("callState", mapOf("state" to state, "number" to number))
					// When ringing, ask Flutter if number should be blocked and disconnect if so
					if (state == "ringing" && number != null) {
						methodChannel?.invokeMethod("isBlocked", mapOf("number" to number), object : MethodChannel.Result {
							override fun success(result: Any?) {
								val blocked = result as? Boolean ?: false
								if (blocked) {
									val disco = Intent("com.antigravity.callin.DISCONNECT_NUMBER")
									disco.putExtra("number", number)
									sendBroadcast(disco)
								}
							}

							override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {}

							override fun notImplemented() {}
						})
					}
				}
			}
		}
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
			registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
		} else {
			registerReceiver(receiver, filter)
		}

		// If the activity was started with call extras, notify Flutter
		intent?.let { handleCallIntent(it) }
	}

	override fun onNewIntent(intent: Intent) {
		super.onNewIntent(intent)
		setIntent(intent)
		handleCallIntent(intent)
	}

	private fun handleCallIntent(intent: Intent) {
		val incoming = intent.getBooleanExtra("CALL_INCOMING", false)
		val number = intent.getStringExtra("CALL_NUMBER")
		val state = intent.getStringExtra("CALL_STATE")
		if (incoming && number != null) {
			methodChannel?.invokeMethod("incomingCall", mapOf("number" to number))
		} else if (state != null && number != null) {
			methodChannel?.invokeMethod("callState", mapOf("state" to state, "number" to number))
		}
	}

	// Request the user to set this app as default dialer
	fun requestDefaultDialer() {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
			val roleManager = getSystemService(RoleManager::class.java)
			if (roleManager != null && !roleManager.isRoleHeld(RoleManager.ROLE_DIALER)) {
				val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_DIALER)
				startActivityForResult(intent, 99)
			} else {
				// already default
				methodChannel?.invokeMethod("defaultDialerResult", true)
			}
		} else {
			val intent = Intent("android.provider.TelecomManager.ACTION_CHANGE_DEFAULT_DIALER")
			intent.putExtra("android.provider.extra.CHANGE_DEFAULT_DIALER_PACKAGE_NAME", packageName)
			startActivityForResult(intent, 99)
		}
	}

	override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
		super.onActivityResult(requestCode, resultCode, data)
		if (requestCode == 99) {
			val granted = resultCode == Activity.RESULT_OK
			methodChannel?.invokeMethod("defaultDialerResult", granted)
		}
	}

	private fun getActiveSimCount(): Int {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
			try {
				val subscriptionManager = getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as? SubscriptionManager
				if (subscriptionManager != null) {
					return subscriptionManager.activeSubscriptionInfoCount
				}
			} catch (e: SecurityException) {
				return 1
			} catch (e: Exception) {
				return 1
			}
		}
		return 1
	}

	private fun isDefaultDialer(): Boolean {
		return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
			val roleManager = getSystemService(RoleManager::class.java)
			roleManager?.isRoleHeld(RoleManager.ROLE_DIALER) == true
		} else {
			val telecomManager = getSystemService(Context.TELECOM_SERVICE) as TelecomManager
			val defaultDialer = telecomManager.defaultDialerPackage
			defaultDialer == packageName
		}
	}
}
