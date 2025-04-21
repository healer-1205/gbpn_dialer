import 'dart:developer';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:gbpn_dealer/services/twilio_service.dart';
import 'package:twilio_voice/models/call_event.dart';

class CallManager {
  static final CallManager _instance = CallManager._internal();
  factory CallManager() => _instance;
  CallManager._internal();

  bool _isCallOverlayVisible = false;
  OverlayEntry? _callOverlayEntry;
  final TwilioService _twilioService = TwilioService();
  StreamSubscription? _callEventsSubscription;

  Timer? _callTimer;
  int _callDuration = 0;
  final _callDurationController = StreamController<int>.broadcast();
  Stream<int> get callDurationStream => _callDurationController.stream;

  void initialize(BuildContext context) {
    _registerCallEventListener(context);
  }

  void _registerCallEventListener(BuildContext context) {
    try {
      _callEventsSubscription?.cancel();
      log("Registering call event listener");
      _callEventsSubscription = _twilioService.callEvents.listen((event) {
        log("Call event received: $event");
        _handleCallEvent(event, context);
      });
    } catch (e) {
      log("Error registering call event listener: $e");
    }
  }

  void _handleCallEvent(CallEvent event, BuildContext context) {
    switch (event) {
      case CallEvent.ringing:
        _showIncomingCallUI(context);
        break;
      case CallEvent.connected:
        _handleCallConnected(context);
        break;
      case CallEvent.callEnded:
      case CallEvent.declined:
        _handleCallEnded();
        break;
      default:
        break;
    }
  }

  void _showIncomingCallUI(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {

        if (_isCallOverlayVisible) {
          log("Call overlay is already visible. Ignoring new call event.");
          return;
        }

        final overlay = Overlay.of(context);
        if (overlay == null) {
          throw Exception("Overlay is null");
        }
        log("Overlay retrieved: $overlay");

        try {
          _callOverlayEntry = OverlayEntry(
            builder: (context) {
              log("Building IncomingCallOverlay widget.");
              return IncomingCallOverlay(
                callerName: "GBPN Dialer",
                onAccept: () {
                  log("Call accepted by user.");
                  _acceptCall(context);
                },
                onDecline: () {
                  log("Call declined by user.");
                  _declineCall();
                },
              );
            },
          );

          log("Inserting call overlay into overlay stack.");
          overlay.insert(_callOverlayEntry!);
          _isCallOverlayVisible = true;
          log("Call overlay is now visible.");
        } catch (e) {
          log("Error creating or inserting overlay entry: $e");
          _isCallOverlayVisible = false;
          _callOverlayEntry = null;
        }
      } catch (e) {
        log("Error showing incoming call UI: $e");
      }
    });
  }

  void _handleCallConnected(BuildContext context) {
    _removeCurrentOverlay();

    final overlay = Overlay.of(context);
    _callOverlayEntry = OverlayEntry(
      builder: (context) => ActiveCallOverlay(
        callerName: "GBPN Dialer",
        onHangUp: _endCall,
        callDurationStream: callDurationStream,
      ),
    );

    overlay.insert(_callOverlayEntry!);
    _isCallOverlayVisible = true;

    _startCallTimer();
  }

  void _handleCallEnded() {
    _stopCallTimer();
    _removeCurrentOverlay();
  }

  Future<void> _acceptCall(BuildContext context) async {
    await _twilioService.answerCall();
  }

  Future<void> _declineCall() async {
    await _twilioService.hangUpCall();
  }

  Future<void> _endCall() async {
    await _twilioService.hangUpCall();
  }

  void _removeCurrentOverlay() {
    if (_isCallOverlayVisible && _callOverlayEntry != null) {
      _callOverlayEntry!.remove();
      _callOverlayEntry = null;
      _isCallOverlayVisible = false;
    }
  }

  void _startCallTimer() {
    _callDuration = 0;
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _callDuration++;
      _callDurationController.add(_callDuration);
    });
  }

  void _stopCallTimer() {
    _callTimer?.cancel();
    _callTimer = null;
    _callDuration = 0;
  }

  void dispose() {
    _callEventsSubscription?.cancel();
    _callTimer?.cancel();
    _callDurationController.close();
    _removeCurrentOverlay();
  }
}

class IncomingCallOverlay extends StatelessWidget {
  final String callerName;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const IncomingCallOverlay({
    Key? key,
    required this.callerName,
    required this.onAccept,
    required this.onDecline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black.withOpacity(0.85),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, size: 80, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text(
                callerName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                "Incoming Call",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              const Spacer(flex: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CallActionButton(
                    icon: Icons.call_end,
                    backgroundColor: Colors.red,
                    onPressed: onDecline,
                  ),
                  CallActionButton(
                    icon: Icons.call,
                    backgroundColor: Colors.green,
                    onPressed: onAccept,
                  ),
                ],
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}

class ActiveCallOverlay extends StatefulWidget {
  final String callerName;
  final VoidCallback onHangUp;
  final Stream<int> callDurationStream;

  const ActiveCallOverlay({
    Key? key,
    required this.callerName,
    required this.onHangUp,
    required this.callDurationStream,
  }) : super(key: key);

  @override
  State<ActiveCallOverlay> createState() => _ActiveCallOverlayState();
}

class _ActiveCallOverlayState extends State<ActiveCallOverlay> {
  final TwilioService _twilioService = TwilioService();
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isBluetoothOn = false;
  bool _isMinimized = false;
  String _dtmfInput = "";

  @override
  Widget build(BuildContext context) {
    if (_isMinimized) {
      return _buildMinimizedView();
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black.withOpacity(0.85),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildCallerInfo(),
              _buildCallTimer(),
              if (_dtmfInput.isNotEmpty) _buildDtmfDisplay(),
              Expanded(
                child: _buildDialpad(),
              ),
              _buildCallControls(),
              _buildEndCallButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Active Call",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.white),
            onPressed: () {
              setState(() {
                _isMinimized = true;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCallerInfo() {
    return Column(
      children: [
        const CircleAvatar(
          radius: 40,
          backgroundColor: Colors.white24,
          child: Icon(Icons.person, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          widget.callerName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildCallTimer() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: StreamBuilder<int>(
        stream: widget.callDurationStream,
        builder: (context, snapshot) {
          final duration = snapshot.data ?? 0;
          final minutes = (duration ~/ 60).toString().padLeft(2, '0');
          final seconds = (duration % 60).toString().padLeft(2, '0');
          return Text(
            '$minutes:$seconds',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          );
        },
      ),
    );
  }

  Widget _buildDtmfDisplay() {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _dtmfInput,
        style: const TextStyle(fontSize: 24, color: Colors.white),
      ),
    );
  }

  Widget _buildDialpad() {
    return GridView.count(
      crossAxisCount: 3,
      childAspectRatio: 1.5,
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: [
        for (var i = 1; i <= 9; i++) _buildDialButton(i.toString()),
        _buildDialButton("*"),
        _buildDialButton("0"),
        _buildDialButton("#"),
      ],
    );
  }

  Widget _buildDialButton(String digit) {
    return InkWell(
      onTap: () {
        setState(() {
          _dtmfInput += digit;
        });
        _twilioService.sendDigits(digit);
      },
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(fontSize: 24, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildCallControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CallControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            label: "Mute",
            isActive: _isMuted,
            onPressed: () {
              setState(() {
                _isMuted = !_isMuted;
                _twilioService.muteCall(_isMuted);
              });
            },
          ),
          CallControlButton(
            icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
            label: "Speaker",
            isActive: _isSpeakerOn,
            onPressed: () {
              setState(() {
                _isSpeakerOn = !_isSpeakerOn;
                _twilioService.toggleSpeaker(_isSpeakerOn);
              });
            },
          ),
          CallControlButton(
            icon: Icons.bluetooth,
            label: "Bluetooth",
            isActive: _isBluetoothOn,
            onPressed: () {
              setState(() {
                _isBluetoothOn = !_isBluetoothOn;
                _twilioService.toggleBluetooth(_isBluetoothOn);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEndCallButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: CallActionButton(
        icon: Icons.call_end,
        backgroundColor: Colors.red,
        onPressed: widget.onHangUp,
      ),
    );
  }

  Widget _buildMinimizedView() {
    return Positioned(
      right: 16,
      top: 100,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isMinimized = false;
          });
        },
        child: Container(
          width: 180,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.green, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.green,
                child: Icon(Icons.phone, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.callerName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    StreamBuilder<int>(
                      stream: widget.callDurationStream,
                      builder: (context, snapshot) {
                        final duration = snapshot.data ?? 0;
                        final minutes =
                            (duration ~/ 60).toString().padLeft(2, '0');
                        final seconds =
                            (duration % 60).toString().padLeft(2, '0');
                        return Text(
                          '$minutes:$seconds',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: widget.onHangUp,
                child: const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.call_end, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CallActionButton extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const CallActionButton({
    Key? key,
    required this.icon,
    required this.backgroundColor,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: FloatingActionButton(
        backgroundColor: backgroundColor,
        child: Icon(icon, size: 28),
        onPressed: onPressed,
      ),
    );
  }
}

class CallControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  const CallControlButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.white12,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon),
            color: isActive ? Colors.white : Colors.white70,
            onPressed: onPressed,
            iconSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.blue : Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
