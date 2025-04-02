import 'dart:developer';
import 'dart:typed_data';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:twilio_voice/twilio_voice.dart';

class TwilioService {
  static final TwilioService _instance = TwilioService._internal();
  late Uint8List bimData;

  // Sound players
  final FlutterSoundPlayer _soundPlayer = FlutterSoundPlayer();
  final FlutterSoundPlayer _endCallSoundPlayer = FlutterSoundPlayer();
  bool _isPlaying = false;

  factory TwilioService() {
    return _instance;
  }

  TwilioService._internal() {
    _initSoundPlayers();
  }

  /// Initialize the sound players
  Future<void> _initSoundPlayers() async {
    await _soundPlayer.openPlayer();
    await _endCallSoundPlayer.openPlayer();
    bimData = await getAssetData('assets/sounds/phone-call.mp3');
  }

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

  Future<Uint8List> getAssetData(String path) async {
    var asset = await rootBundle.load(path);
    return asset.buffer.asUint8List();
  }

  int _ringCount = 0;

  /// Play ringtone sound
  Future<void> _playRingtone() async {
    if (!_isPlaying) {
      return;
    }
    try {
      await _soundPlayer.startPlayer(
        fromDataBuffer: bimData,
        codec: Codec.mp3,
        whenFinished: () async {
          await Future.delayed(Duration(seconds: 2));
          _playRingtone();
          _isPlaying = true; // Restart the ringtone when it finishes
        },
      );

      log("Started playing ringtone");
    } catch (e) {
      log("Error playing ringtone: $e");
    }
  }

  /// Stop ringtone sound
  Future<void> _stopRingtone() async {
    if (_isPlaying) {
      try {
        _isPlaying = false;
        await _soundPlayer.stopPlayer();
        _isPlaying = false;
        log("Stopped playing ringtone");
      } catch (e) {
        log("Error stopping ringtone: $e");
        _isPlaying = false;
      }
    }
  }

  /// Make a call
  Future<void> makeCall(String from, String toNumber) async {
    _isPlaying = false;

    try {
      await TwilioVoice.instance.call.place(
        from: from, // Twilio Number 15093611979
        to: toNumber.length != 10 ? toNumber : '+1$toNumber', //18042221111
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
      switch (event) {
        case CallEvent.incoming:
          log("Incoming Call detected!");
          if (context.mounted) {
            showIncomingCallScreen(context);
          }
          break;
        case CallEvent.connected:
          log("Call Connected!");
          _stopRingtone(); // Stop ringtone when call is connected
          break;
        case CallEvent.callEnded:
          log("Call Ended!");
          _stopRingtone(); // Stop ringtone when call ends
          _playEndCallSound(); // Play end call sound
          break;
        case CallEvent.ringing:
          _isPlaying = true;
          log("Phone is Ringing!");
          _playRingtone(); // Play ringtone when phone is ringing
          break;
        case CallEvent.reconnecting:
          log("Reconnecting Call...");
          break;
        case CallEvent.declined:
          log("🚫 Call Declined");
          _stopRingtone(); // Stop ringtone when call is declined
          _playEndCallSound(); // Play end call sound when call is declined
          break;
        default:
          log("⚠️ Other Event: $event");
          _isPlaying = false;
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
    await _stopRingtone(); // Ensure ringtone is stopped when call is declined
  }

  /// Play end call sound
  Future<void> _playEndCallSound() async {
    try {
      var endCallData = await getAssetData('assets/sounds/end-call.mp3');
      await _endCallSoundPlayer.startPlayer(
        fromDataBuffer: endCallData,
        codec: Codec.mp3,
      );
      log("Playing end call sound");
    } catch (e) {
      log("Error playing end call sound: $e");
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _stopRingtone();
    await _soundPlayer.closePlayer();
    await _endCallSoundPlayer.closePlayer();
  }
}
