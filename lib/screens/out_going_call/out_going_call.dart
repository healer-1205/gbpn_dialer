import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gbpn_dealer/services/twilio_service.dart';
import 'package:twilio_voice/models/call_event.dart';

class CallScreen extends StatefulWidget {
  final String phoneNumber;
  final String callerName;
  final TwilioService twilioService;
  const CallScreen({
    super.key,
    required this.phoneNumber,
    required this.callerName,
    required this.twilioService,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen>
    with SingleTickerProviderStateMixin {
  late TwilioService _twilioService;
  bool _isSpeakerOn = false;
  bool _isMuted = false;
  bool _isKeypadVisible = false;
  bool _isConnected = false;
  Timer? _callTimer;
  Duration _callDuration = Duration.zero;
  String _callTime = "00:00";
  StreamSubscription<CallEvent>? _callEventSubscription;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final ValueNotifier<String> _dtmfInput = ValueNotifier<String>('');
  @override
  void initState() {
    super.initState();
    _twilioService = widget.twilioService;
    _setupCallListeners();
    // Set up call timer

    // Set up pulse animation for avatar
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _pulseController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _pulseController.forward();
        }
      });

    _pulseController.forward();
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _pulseController.dispose();
    _callEventSubscription?.cancel();
    _dtmfInput.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  void _endCall() async {
    await _twilioService.hangUpCall();
    Navigator.pop(context);
  }

  void _toggleSpeaker() async {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    await _twilioService.toggleSpeaker(_isSpeakerOn);
  }

  void _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });
    await _twilioService.muteCall(_isMuted);
  }

  void _toggleKeypad() async {
    setState(() {
      _isKeypadVisible = !_isKeypadVisible;
    });
  }

  /// Setup call event listeners
  void _setupCallListeners() {
    _callEventSubscription = _twilioService.callEvents.listen((event) {
      if (!mounted) return;
      switch (event) {
        case CallEvent.callEnded:
          _callTimer?.cancel();
          if (!mounted) return;
          if (Navigator.canPop(context)) {
            Navigator.pop(context); // Close Outgoing Call Screen when call ends
          }
          break;
        case CallEvent.connected:
          _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            setState(() {
              _callDuration += const Duration(seconds: 1);
              _callTime = _formatDuration(_callDuration);
            });
          });
          break;
        default:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isKeypadVisible ? _buildDialpad() : _buildCallerInfo(),
            ),
            _buildCallControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildCallerInfo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        Text(
          widget.callerName,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isConnected ? _callTime : 'Ringing...',
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 40),
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade800,
            ),
            child: Center(
              child: Text(
                widget.callerName.substring(0, 1),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildDialpad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // DTMF input display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            margin: const EdgeInsets.only(bottom: 24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ValueListenableBuilder(
                valueListenable: _dtmfInput,
                builder: (context, value, child) {
                  return Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  );
                }),
          ),

          // Dialpad grid
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              childAspectRatio: 1,
              mainAxisSpacing: 16,
              crossAxisSpacing: 20,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildDialpadButton("1"),
                _buildDialpadButton("2", subText: "ABC"),
                _buildDialpadButton("3", subText: "DEF"),
                _buildDialpadButton("4", subText: "GHI"),
                _buildDialpadButton("5", subText: "JKL"),
                _buildDialpadButton("6", subText: "MNO"),
                _buildDialpadButton("7", subText: "PQRS"),
                _buildDialpadButton("8", subText: "TUV"),
                _buildDialpadButton("9", subText: "WXYZ"),
                _buildDialpadButton("*"),
                _buildDialpadButton("0", subText: "+"),
                _buildDialpadButton("#"),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDialpadButton(String text, {String? subText}) {
    return InkWell(
      onTap: () async {
        // In a real app, would send DTMF tones
        HapticFeedback.mediumImpact();
        _dtmfInput.value += text;
        await _twilioService.sendDigits(text);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            if (subText != null)
              Text(
                subText,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                  letterSpacing: 1,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      color: Colors.black,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: Icons.mic_off,
                label: "mute",
                isActive: _isMuted,
                onTap: _toggleMute,
              ),
              _buildControlButton(
                icon: Icons.dialpad,
                label: "keypad",
                isActive: _isKeypadVisible,
                onTap: _toggleKeypad,
              ),
              _buildControlButton(
                icon: Icons.volume_up,
                label: "speaker",
                isActive: _isSpeakerOn,
                onTap: _toggleSpeaker,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildEndCallButton(),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.grey.shade800,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.black : Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndCallButton() {
    return GestureDetector(
      onTap: _endCall,
      child: Container(
        width: 70,
        height: 70,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.call_end,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}
