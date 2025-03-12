package com.example.gbpn_dealer

import android.os.Bundle
import android.util.Log
import com.twilio.voice.Call
import com.twilio.voice.Voice
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.twilio.voice.CallException

class MainActivity: FlutterActivity() {
    private val CHANNEL = "twilio_voice"
    private var activeCall: Call? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "makeCall") {
                val accessToken = call.argument<String>("token")
                val to = call.argument<String>("to")

                makeCall(accessToken!!, to!!, result)
            }
        }
    }

    private fun makeCall(token: String, to: String, result: MethodChannel.Result) {
        activeCall = Voice.connect(this, token, object : Call.Listener {
            override fun onConnected(call: Call) {
                Log.d("Twilio", "Call Connected")
                result.success("Connected")
            }

            override fun onDisconnected(call: Call, error: CallException?) {
                Log.d("Twilio", "Call Disconnected")
                result.success("Disconnected")
            }

            override fun onConnectFailure(call: Call, error: CallException) {
                Log.e("Twilio", "Call Failed: ${error.message}")
                result.error("ERROR", "Call Failed: ${error.message}", null)
            }

            override fun onRinging(call: Call) {
                Log.d("Twilio", "Ringing")
            }

            override fun onReconnecting(call: Call, error: CallException) {
                Log.d("Twilio", "Reconnecting due to: ${error.message}")
            }

            override fun onReconnected(call: Call) {
                Log.d("Twilio", "Reconnected")
            }
        })
    }
}
