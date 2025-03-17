import 'package:flutter/material.dart';
import 'package:twilio_voice/twilio_voice.dart';

class IncomingCallScreen extends StatelessWidget {
  final String callerName;

  IncomingCallScreen({required this.callerName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("📞 Incoming Call", style: TextStyle(fontSize: 24, color: Colors.white)),
          SizedBox(height: 20),
          Text(callerName, style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
          SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                backgroundColor: Colors.green,
                onPressed: () async {
                  await TwilioVoice.instance.call.answer();
                  Navigator.pop(context); // Close incoming call screen
                },
                child: Icon(Icons.call, color: Colors.white),
              ),
              FloatingActionButton(
                backgroundColor: Colors.red,
                onPressed: () async {
                  await TwilioVoice.instance.call.hangUp();
                  Navigator.pop(context);
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