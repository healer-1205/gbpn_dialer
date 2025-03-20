import 'package:flutter/material.dart';

class OutgoingCallScreen extends StatelessWidget {
  final String toNumber;

  const OutgoingCallScreen({Key? key, required this.toNumber}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Calling...",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          SizedBox(height: 10),
          Text(
            toNumber,
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 40),
          Icon(
            Icons.phone_in_talk,
            size: 100,
            color: Colors.green,
          ),
          SizedBox(height: 50),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Go back when call is canceled
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text("Cancel Call"),
          ),
        ],
      ),
    );
  }
}