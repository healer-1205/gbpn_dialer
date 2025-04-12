import 'package:flutter/material.dart';
import 'package:gbpn_dealer/screens/out_going_call/out_going_call.dart';
import 'package:gbpn_dealer/services/twilio_service.dart';
import 'package:twilio_voice/twilio_voice.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callerName;
  final TwilioService twilioService;
  IncomingCallScreen({required this.callerName, required this.twilioService});

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
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
                  if (!mounted) return;
                  Navigator.pop(context); // Close incoming call screen
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CallScreen(
                                callerName: widget.callerName,
                                twilioService: widget.twilioService,
                                phoneNumber: widget.twilioService.activeCall
                                        ?.fromFormatted ??
                                    '',
                              )));
                },
                child: Icon(Icons.call, color: Colors.white),
              ),
              FloatingActionButton(
                backgroundColor: Colors.red,
                onPressed: () async {
                  Navigator.pop(context);
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
