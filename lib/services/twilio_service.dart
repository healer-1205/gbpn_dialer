import 'dart:developer';
import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/material.dart';
import 'package:twilio_voice/_internal/utils.dart';
import 'package:twilio_voice/twilio_voice.dart';

class TwilioService {
  static final TwilioService _instance = TwilioService._internal();

  factory TwilioService() {
    return _instance;
  }
  TwilioService._internal();

  /// Stream for call events
  Stream<CallEvent> get callEvents => TwilioVoice.instance.callEventsListener;

  /// Initialize Twilio with tokens
  Future<void> initialize(
      String accessToken, String deviceToken, BuildContext context) async {
    try {
      await TwilioVoice.instance.setTokens(
        accessToken: accessToken,
        deviceToken: deviceToken,
      );
      TwilioVoice.instance.setOnDeviceTokenChanged((token) async {
        await TwilioVoice.instance.setTokens(
          accessToken: accessToken,
          deviceToken: token,
        );
      });

      TwilioVoice.instance.setDefaultCallerName("Unknown");

      _setupListeners(context);
      log("Twilio Initialized Successfully");
    } catch (e) {
      log("Twilio Initialization Failed: $e");
    }
  }

  /// Make a call
  Future<void> makeCall(String toNumber) async {
    try {
      await TwilioVoice.instance.call.place(
        from: 'alice', // Twilio Number 15093611979
        to: 'john', //18042221111
      );
      log("Calling $toNumber...");
    } catch (e) {
      log("Failed to make call: $e");
    }
  }

  /// Check if token is expired
  bool isTokenExpired(String token) {
    try {
      final jwt = JWT.decode(token);
      final expiry = jwt.payload['exp'];
      return DateTime.fromMillisecondsSinceEpoch(expiry * 1000)
          .isBefore(DateTime.now().toUtc());
    } catch (e) {
      return true;
    }
  }

  /// Setup listeners for Twilio events
  void _setupListeners(BuildContext context) {
    // Listen for Twilio Call Events
    TwilioVoice.instance.callEventsListener.listen((event) {
      log("Call Event: $event");

      switch (event) {
        case CallEvent.incoming:
          log("Incoming Call detected!");
          if (context.mounted) {
            showIncomingCallScreen(context);
          }
          // showIncomingCallScreen(context);
          break;
        case CallEvent.connected:
          log("Call Connected!");
          break;
        case CallEvent.callEnded:
          log("Call Ended!");
          break;
        case CallEvent.ringing:
          log("Phone is Ringing!");
          break;
        case CallEvent.reconnecting:
          log("Reconnecting Call...");
          break;
        case CallEvent.declined:
          log("🚫 Call Declined");
          break;
        default:
          log("⚠️ Other Event: $event");
      }
    });
  }

  /// Show Incoming Call Screen
  void showIncomingCallScreen(BuildContext context) {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) =>
    //         IncomingCallScreen(callerName: "GBPN Dialer Testing"),
    //   ),
    // );
  }

  /// Answer the Call
  Future<void> answerCall() async {
    await TwilioVoice.instance.call.answer();
  }

  /// Decline the Call
  Future<void> declineCall() async {
    await TwilioVoice.instance.call.hangUp();
  }
}
