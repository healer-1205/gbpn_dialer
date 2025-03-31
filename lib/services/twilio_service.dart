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
      await _requestPermissions();

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

      bool hasAccount = await TwilioVoice.instance.hasRegisteredPhoneAccount();
      if (!hasAccount) {
        log("⚠️ No Phone Account Registered! Registering now...");
        await _registerPhoneAccount();
      }
      TwilioVoice.instance.setDefaultCallerName("Unknown");
      // 🔹 Add delay to ensure registration completes
      await Future.delayed(Duration(seconds: 2));

      _setupListeners(context);
      log("Twilio Initialized Successfully");
    } catch (e) {
      log("Twilio Initialization Failed: $e");
    }
  }

  Future<void> _requestPermissions() async {
    if (!Platform.isAndroid) return;
    var result = await TwilioVoice.instance
        .requestCallPhonePermission(); // Gives Android permissions to place outgoing calls
    result = await TwilioVoice.instance
        .requestReadPhoneStatePermission(); // Gives Android permissions to read Phone State including receiving calls
    result = await TwilioVoice.instance
        .requestReadPhoneNumbersPermission(); // Gives Android permissions to read Phone Accounts
    result = await TwilioVoice.instance
        .requestManageOwnCallsPermission(); // Gives Android permissions to manage calls, this isn't necessary to request as the permission is simply required in the Manifest, but added nontheless.
    result = await TwilioVoice.instance.isRejectingCallOnNoPermissions();
    log('result $result');
  }

  /// Register Phone Account
  Future<void> _registerPhoneAccount() async {
    try {
      bool? isRegistered = await TwilioVoice.instance.registerPhoneAccount();
      if (isRegistered!) {
        log("✅ Phone Account Registered Successfully");
        // ⏳ Delay before making a call (Allow time for registration)
        await Future.delayed(Duration(seconds: 2));
      } else {
        log("⚠️ Failed to Register Phone Account");
      }
    } catch (e) {
      log("❌ Error Registering Phone Account: $e");
    }
  }

  /// Make a call
  Future<void> makeCall(String toNumber) async {
    try {
      if (!await (TwilioVoice.instance.hasRegisteredPhoneAccount())) {
        printDebug("request phone account");
        TwilioVoice.instance.registerPhoneAccount();
        return;
      }
      if (!await (TwilioVoice.instance.hasMicAccess())) {
        printDebug("request mic access");
        TwilioVoice.instance.requestMicAccess();
        return;
      }
      if (!await (TwilioVoice.instance.hasCallPhonePermission())) {
        printDebug("request call phone permission");
        TwilioVoice.instance.requestCallPhonePermission();
        return;
      }

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
