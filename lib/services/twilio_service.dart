import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
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
  Future<void> initialize(String accessToken, String deviceToken) async {
    try {
      await TwilioVoice.instance.setTokens(
        accessToken: accessToken,
        deviceToken: deviceToken,
      );

      bool hasAccount = await TwilioVoice.instance.hasRegisteredPhoneAccount();
      if (!hasAccount) {
        print("⚠️ No Phone Account Registered! Registering now...");
        await _registerPhoneAccount();
      }
      // 🔹 Add delay to ensure registration completes
      await Future.delayed(Duration(seconds: 2));

      _setupListeners();
      print("Twilio Initialized Successfully");
    } catch (e) {
      print("Twilio Initialization Failed: $e");
    }
  }

  Future<void> _registerPhoneAccount() async {
    try {
      bool? isRegistered = await TwilioVoice.instance.registerPhoneAccount();
      if (isRegistered!) {
        print("✅ Phone Account Registered Successfully");
        // ⏳ Delay before making a call (Allow time for registration)
        await Future.delayed(Duration(seconds: 2));
      } else {
        print("⚠️ Failed to Register Phone Account");
      }
    } catch (e) {
      print("❌ Error Registering Phone Account: $e");
    }
  }

  /// Make a call
  Future<void> makeCall(String toNumber) async {
    try {
      await TwilioVoice.instance.call.place(
        from: '+15093611979', // Twilio Number
        to: '+18042221111',
      );
      print("Calling $toNumber...");
    } catch (e) {
      print("Failed to make call: $e");
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
  void _setupListeners() {
    // Listen for Twilio Call Events
    TwilioVoice.instance.callEventsListener.listen((event) {
      print("Call Event: $event");

      switch (event) {
        case CallEvent.incoming:
          print("Incoming Call detected!");
          break;
        case CallEvent.connected:
          print("Call Connected!");
          break;
        case CallEvent.callEnded:
          print("Call Ended!");
          break;
        case CallEvent.ringing:
          print("Phone is Ringing!");
          break;
        case CallEvent.reconnecting:
          print("Reconnecting Call...");
          break;
        default:
          print("Other Event: $event");
      }
    });
  }
}
