import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gbpn_dealer/screens/incoming_screen/ongoing_call_screen.dart';
import 'package:gbpn_dealer/services/twilio_service.dart';
import 'package:twilio_voice/twilio_voice.dart';
import 'package:flutter/material.dart';
import 'package:twilio_voice/twilio_voice.dart';

// import 'twilio_service.dart'; // Assuming your TwilioService is in this file
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


class TwilioIncomingCallScreen extends StatefulWidget {
  final String? callerName;
  final String? callerNumber;
  final String? callerImageUrl;
  
  const TwilioIncomingCallScreen({
    Key? key,
    this.callerName,
    this.callerNumber,
    this.callerImageUrl,
  }) : super(key: key);

  @override
  State<TwilioIncomingCallScreen> createState() => _TwilioIncomingCallScreenState();
}

class _TwilioIncomingCallScreenState extends State<TwilioIncomingCallScreen> with TickerProviderStateMixin {
  final TwilioService _twilioService = TwilioService();
  late AnimationController _backgroundAnimationController;
  late AnimationController _bounceAnimationController;
  late Animation<double> _bounceAnimation;
  String _callerName = 'Unknown Caller';
  String _callerNumber = '';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _getCallDetails();
  }

  void _setupAnimations() {
    // Background wave animation
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Bounce animation for call buttons
    _bounceAnimationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _bounceAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _getCallDetails() {
    final activeCall = TwilioVoice.instance.call.activeCall;
    if (activeCall != null) {
      setState(() {
        if (widget.callerName != null && widget.callerName!.isNotEmpty) {
          _callerName = widget.callerName!;
        } else {
          _callerName = activeCall.customParams?['fromNumber'] ?? 'Unknown Caller';
        }
        _callerNumber = widget.callerNumber ?? activeCall.from ?? '';
      });
    }
  }

  Future<void> _answerCall() async {
    await _twilioService.answerCall();
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const TwilioOngoingCallScreen(),
        ),
      );
    }
  }

  Future<void> _declineCall() async {
    await _twilioService.hangUpCall();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _bounceAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent accidental back navigation
      child: Scaffold(
        body: Stack(
          children: [
            // Animated background
            AnimatedBuilder(
              animation: _backgroundAnimationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: BackgroundWavePainter(_backgroundAnimationController),
                  child: Container(),
                );
              },
            ),
            // Overlay gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0A1931).withOpacity(0.6),
                    const Color(0xFF185ADB),
                  ],
                ),
              ),
            ),
            // Content
            SafeArea(
              child: Column(
                children: [
                  // Incoming call text
                  Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: Text(
                      'INCOMING CALL',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 2,
                      ),
                    ),
                  ),

                  // Caller info
                  Expanded(
                    flex: 6,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Caller avatar
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF185ADB).withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: widget.callerImageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(60),
                                    child: Image.network(
                                      widget.callerImageUrl!,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: Text(
                                            _callerName.isNotEmpty ? _callerName[0].toUpperCase() : '?',
                                            style: const TextStyle(
                                              fontSize: 48,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF185ADB),
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Center(
                                          child: Text(
                                            _callerName.isNotEmpty ? _callerName[0].toUpperCase() : '?',
                                            style: const TextStyle(
                                              fontSize: 48,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF185ADB),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      _callerName.isNotEmpty ? _callerName[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF185ADB),
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 24),
                          // Caller name
                          Text(
                            _callerName,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Caller number
                          Text(
                            _callerNumber,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Calling via label
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Calling via VOIP',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Call actions
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Additional options text
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              'Swipe up for more options',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ),
                          // Call actions row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Decline call button
                              _buildCallActionButton(
                                icon: Icons.call_end,
                                label: 'Decline',
                                color: Colors.red,
                                onPressed: _declineCall,
                              ),
                              // Accept call button
                              _buildCallActionButton(
                                icon: Icons.call,
                                label: 'Accept',
                                color: Colors.green,
                                onPressed: _answerCall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _bounceAnimation.value,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: onPressed,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Animated wave background
class BackgroundWavePainter extends CustomPainter {
  final Animation<double> animation;

  BackgroundWavePainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF185ADB).withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final path = Path();
    final height = size.height;
    final width = size.width;
    
    // First wave
    path.moveTo(0, height * 0.8);
    
    for (var i = 0.0; i <= width; i++) {
      path.lineTo(
        i, 
        height * 0.8 + 
        sin((i / width * 2 * pi) + (animation.value * 2 * pi)) * 30
      );
    }
    
    path.lineTo(width, height);
    path.lineTo(0, height);
    path.close();
    
    canvas.drawPath(path, paint);
    
    // Second wave
    final secondPaint = Paint()
      ..color = const Color(0xFF185ADB).withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    final secondPath = Path();
    secondPath.moveTo(0, height * 0.85);
    
    for (var i = 0.0; i <= width; i++) {
      secondPath.lineTo(
        i, 
        height * 0.85 + 
        sin((i / width * 3 * pi) + (animation.value * 3 * pi)) * 20
      );
    }
    
    secondPath.lineTo(width, height);
    secondPath.lineTo(0, height);
    secondPath.close();
    
    canvas.drawPath(secondPath, secondPaint);
  }

  @override
  bool shouldRepaint(BackgroundWavePainter oldDelegate) => true;
}
