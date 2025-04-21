import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:gbpn_dealer/main.dart';
import 'package:gbpn_dealer/screens/incoming_screen/incoming_call_screen.dart';
import 'package:gbpn_dealer/screens/incoming_screen/ongoing_call_screen.dart';
import 'package:twilio_voice/twilio_voice.dart';

class TwilioService {
  static final TwilioService _instance = TwilioService._internal();
  late Uint8List bimData;

  final FlutterSoundPlayer _soundPlayer = FlutterSoundPlayer();
  final FlutterSoundPlayer _endCallSoundPlayer = FlutterSoundPlayer();
  bool _isPlaying = false;
  bool _isCallConnected = false;
  bool _isNavigating = false;
  bool get isCallConnected => _isCallConnected;

  factory TwilioService() {
    return _instance;
  }

  TwilioService._internal() {
    _initSoundPlayers();
  }

  Future<void> handleIncomingCallFromTerminated(
      Map<String, dynamic> callData) async {
    log("Handling call from terminated state: $callData");

    if (navigatorKey.currentContext != null) {
      showIncomingCallScreen(navigatorKey.currentContext!);
    } else {
      Timer.periodic(Duration(milliseconds: 100), (timer) {
        if (navigatorKey.currentContext != null) {
          showIncomingCallScreen(navigatorKey.currentContext!);
          timer.cancel();
        }
      });
    }
  }

  Future<void> _initSoundPlayers() async {
    await _soundPlayer.openPlayer();
    await _endCallSoundPlayer.openPlayer();
    bimData = await getAssetData('assets/sounds/phone-call.mp3');
  }

  Stream<CallEvent> get callEvents => TwilioVoice.instance.callEventsListener;

  Future<void> initialize(
      String accessToken, String deviceToken, BuildContext context) async {
    try {
      log("APNS Token: $deviceToken");
      await TwilioVoice.instance.setTokens(
        accessToken: accessToken,
        deviceToken: deviceToken,
      );

      await setupPushNotifications();

      TwilioVoice.instance.setOnDeviceTokenChanged((token) async {
        log("Device token changed: $token");
        await TwilioVoice.instance.setTokens(
          accessToken: accessToken,
          deviceToken: token,
        );
      });

      TwilioVoice.instance.setDefaultCallerName("Unknown");

      _isCallConnected = false;
      _isPlaying = false;
      _isNavigating = false;

      if (context.mounted) {
        _setupListeners(context);
      }
      log("Twilio Initialized Successfully");
    } catch (e) {
      log("Twilio Initialization Failed: $e");
    }
  }

  Future<Uint8List> getAssetData(String path) async {
    var asset = await rootBundle.load(path);
    return asset.buffer.asUint8List();
  }

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
          _isPlaying = true;
        },
      );

      log("Started playing ringtone");
    } catch (e) {
      log("Error playing ringtone: $e");
    }
  }

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

  Future<void> makeCall(String from, String toNumber) async {
    _isPlaying = false;
    _isCallConnected = false;
    try {
      await TwilioVoice.instance.call.place(
          from: from,
          to: toNumber.length != 10 ? toNumber : '+1$toNumber',
          extraOptions: {
            "fromNumber": from,
            "toNumber": toNumber.length != 10 ? toNumber : '+1$toNumber',
          });
      log("Calling $toNumber...");
    } catch (e) {
      log("Failed to make call: $e");
    }
  }

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

  void _setupListeners(BuildContext context) {
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
          _isCallConnected = true;
          _stopRingtone();

          if (context.mounted && !_isNavigating) {
            _isNavigating = true;

            Future.microtask(() {
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TwilioOngoingCallScreen()),
                ).then((_) {
                  _isNavigating = false;
                });
              } else {
                _isNavigating = false;
              }
            });
          }
          break;
        case CallEvent.callEnded:
          log("Call Ended!");
          _isCallConnected = false;
          _stopRingtone();
          _playEndCallSound();

          Navigator.of(navigatorKey.currentContext!)
              .pushNamedAndRemoveUntil('/main', (route) => false)
              .then((_) => _isNavigating = false)
              .catchError((error) {
            log("Navigation error: $error");
            _isNavigating = false;
          });
          break;
        case CallEvent.ringing:
          _isPlaying = true;
          log("Phone is Ringing!");
          _playRingtone();
          break;
        case CallEvent.reconnecting:
          log("Reconnecting Call...");
          break;
        case CallEvent.declined:
          log("Call Declined");
          _isCallConnected = false;
          _stopRingtone();
          _playEndCallSound();
          break;
        case CallEvent.speakerOn:
        case CallEvent.speakerOff:
          log("🔊 Speaker Event: $event");
          if (_isCallConnected) break;
          _playRingtone();
          break;
        default:
          log("Other Event: $event");
          _isPlaying = false;
      }
    });
  }

  Future<void> setupPushNotifications() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        log("App opened from terminated state due to push notification");

        _handlePushNotification(message.data);
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log("Push notification received while app is in foreground");
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log("App opened from background state due to push notification");

      _handlePushNotification(message.data);
    });

    final fcmToken = await messaging.getToken();
    log("FCM Token: $fcmToken");

    if (Platform.isAndroid) {}
  }

  void _handlePushNotification(Map<String, dynamic> data) {
    log("Handling push notification data: $data");

    if (data.containsKey('twi_message_type') &&
        data['twi_message_type'] == 'twilio.voice.call') {
      if (navigatorKey.currentContext != null) {
        showIncomingCallScreen(navigatorKey.currentContext!);
      } else {}
    }
  }

  void showIncomingCallScreen(BuildContext context) {
    if (context.mounted && !_isNavigating) {
      _isNavigating = true;

      Future.microtask(() {
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TwilioIncomingCallScreen(),
            ),
          ).then((_) {
            _isNavigating = false;
          });
        } else {
          _isNavigating = false;
        }
      });
    }
  }

  Future<void> answerCall() async {
    await TwilioVoice.instance.call.answer();
    _isCallConnected = true;
  }

  Future<void> hangUpCall() async {
    try {
      await TwilioVoice.instance.call.hangUp();
      _isCallConnected = false;
      await _stopRingtone();
    } catch (e) {
      log("Error hanging up call: $e");
    }
  }

  Future<void> toggleSpeaker(bool value) async {
    await TwilioVoice.instance.call.toggleSpeaker(value);
  }

  Future<void> toggleBluetooth(bool value) async {
    await TwilioVoice.instance.call.toggleBluetooth(bluetoothOn: value);
  }

  Future<void> muteCall(bool value) async {
    await TwilioVoice.instance.call.toggleMute(value);
  }

  Future<void> sendDigits(String value) async {
    await TwilioVoice.instance.call.sendDigits(value);
  }

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

  Future<void> dispose() async {
    await _stopRingtone();
    await _soundPlayer.closePlayer();
    await _endCallSoundPlayer.closePlayer();
  }
}
