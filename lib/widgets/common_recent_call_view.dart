import 'package:flutter/material.dart';

import '../dummy_data/recent_calls_dummies.dart';
import '../utils/common.dart';

class CommonRecentCallView extends StatefulWidget {
  const CommonRecentCallView({
    super.key,
    required this.recentCall,
  });

  final DummyCallModel recentCall;

  @override
  State<CommonRecentCallView> createState() => _CommonRecentCallViewState();
}

class _CommonRecentCallViewState extends State<CommonRecentCallView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              height: 50,
              width: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.recentCall.callType == 0
                    ? Colors.green.withAlpha((0.1 * 255).toInt())
                    : widget.recentCall.callType == 1
                        ? Colors.grey.withAlpha((0.1 * 255).toInt())
                        : Colors.red.withAlpha((0.1 * 255).toInt()),
                borderRadius: BorderRadius.circular(2),
              ),
              child: widget.recentCall.callType == 0
                  ? Icon(Icons.call_made, color: Colors.green)
                  : widget.recentCall.callType == 1
                      ? Icon(Icons.call_received, color: Colors.grey)
                      : Icon(Icons.call_missed, color: Colors.red),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recentCall.name == 'Unknown Number' ||
                            widget.recentCall.name == 'Emergency Services'
                        ? widget.recentCall.phoneNumber
                        : widget.recentCall.name,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    Common.convertIntoDayTime(widget.recentCall.dateTime),
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 20),
            SizedBox(
              width: 50,
              height: 50,
              child: IconButton(
                onPressed: () {},
                icon: Icon(Icons.call),
              ),
            ),
          ],
        ),
        Visibility(
          visible: widget.recentCall.isSelected,
          child: SizedBox(height: 25),
        ),
        Visibility(
          visible: widget.recentCall.isSelected,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _showIconButton(
                icon: Icons.video_call,
                onPress: () {},
                label: 'Video call',
              ),
              _showIconButton(
                icon: Icons.message,
                onPress: () {},
                label: 'Message',
              ),
              _showIconButton(
                icon: Icons.history,
                onPress: () {},
                label: 'History',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _showIconButton({
    required IconData icon,
    required Function() onPress,
    required String label,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            onPress();
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha((0.1 * 255).toInt()),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey,
              ),
            ),
            child: Icon(icon),
          ),
        ),
        SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
