import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gbpn_dealer/screens/out_going_call/out_going_call.dart';
import 'package:gbpn_dealer/services/twilio_service.dart';
import 'package:twilio_voice/twilio_voice.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callerName;
  final TwilioService twilioService;
  const IncomingCallScreen(
      {super.key, required this.callerName, required this.twilioService});

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  StreamSubscription<CallEvent>? _callEventSubscription;
  @override
  void initState() {
    _setupCallListeners();
    super.initState();
  }

  @override
  void dispose() {
    _callEventSubscription?.cancel();

    super.dispose();
  }

  /// Setup call event listeners
  void _setupCallListeners() {
    _callEventSubscription = widget.twilioService.callEvents.listen((event) {
      if (!mounted) return;
      switch (event) {
        case CallEvent.callEnded:
          if (!mounted) return;
          if (Navigator.canPop(context)) {
            Navigator.pop(context); // Close Outgoing Call Screen when call ends
          }
          break;

        case CallEvent.connected:
          if (!mounted) return;
          if (Navigator.canPop(context)) {
            Navigator.pop(context); // Close Outgoing Call Screen when call ends
          }
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => CallScreen(
                        callerName: widget.callerName,
                        twilioService: widget.twilioService,
                        phoneNumber:
                            widget.twilioService.activeCall?.fromFormatted ??
                                '',
                      )));
          break;

        default:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("📞 Incoming Call",
              style: TextStyle(fontSize: 24, color: Colors.white)),
          SizedBox(height: 20),
          Text(widget.callerName,
              style: TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                backgroundColor: Colors.green,
                onPressed: () async {
                  await widget.twilioService.answerCall();
                },
                child: Icon(Icons.call, color: Colors.white),
              ),
              FloatingActionButton(
                backgroundColor: Colors.red,
                onPressed: () async {
                  await TwilioVoice.instance.call.hangUp();
                },
                child: Icon(Icons.call_end, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
