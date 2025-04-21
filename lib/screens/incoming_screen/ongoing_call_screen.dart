import 'dart:async';
import 'package:flutter/material.dart';

import 'package:twilio_voice/twilio_voice.dart';
import 'package:gbpn_dealer/services/twilio_service.dart';

class TwilioOngoingCallScreen extends StatefulWidget {
  const TwilioOngoingCallScreen({Key? key}) : super(key: key);

  @override
  State<TwilioOngoingCallScreen> createState() =>
      _TwilioOngoingCallScreenState();
}

class _TwilioOngoingCallScreenState extends State<TwilioOngoingCallScreen>
    with SingleTickerProviderStateMixin {
  final TwilioService _twilioService = TwilioService();
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isBluetoothOn = false;
  bool _isDialpadVisible = false;
  String _dialpadInput = '';
  String _callerName = '';
  String _callerNumber = '';
  String _callDuration = '00:00';
  late Timer _callTimer;
  int _callDurationInSeconds = 0;
  AudioDevice _selectedAudioDevice = AudioDevice.earpiece;
  List<AudioDevice> _availableAudioDevices = [];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _getCallDetails();
    _startCallTimer();
    _updateAvailableAudioDevices();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  void _getCallDetails() {
    final activeCall = TwilioVoice.instance.call.activeCall;
    if (activeCall != null) {
      setState(() {
        _callerName =
            activeCall.customParams?['fromNumber'] ?? 'Unknown Caller';
        _callerNumber = activeCall.from ?? '';
      });
    }
  }

  Future<void> _updateAvailableAudioDevices() async {
    try {
      setState(() {
        _availableAudioDevices = [
          AudioDevice.earpiece,
          AudioDevice.speaker,
          AudioDevice.bluetooth,
        ];
      });
    } catch (e) {
      debugPrint('Error getting audio devices: $e');
    }
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDurationInSeconds++;
          final minutes =
              (_callDurationInSeconds ~/ 60).toString().padLeft(2, '0');
          final seconds =
              (_callDurationInSeconds % 60).toString().padLeft(2, '0');
          _callDuration = '$minutes:$seconds';
        });
      }
    });
  }

  void _toggleMute() async {
    setState(() => _isMuted = !_isMuted);
    await _twilioService.muteCall(_isMuted);
  }

  void _toggleSpeaker() async {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
      _selectedAudioDevice =
          _isSpeakerOn ? AudioDevice.speaker : AudioDevice.earpiece;
      _isBluetoothOn = false;
    });
    await _twilioService.toggleSpeaker(_isSpeakerOn);
  }

  void _toggleBluetooth() async {
    _showAudioDeviceSelectionDialog();
  }

  void _showAudioDeviceSelectionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1931),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Audio Device',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _buildAudioDeviceOption(
                icon: Icons.phone_in_talk,
                label: 'Phone',
                isSelected: _selectedAudioDevice == AudioDevice.earpiece,
                onTap: () async {
                  setState(() {
                    _selectedAudioDevice = AudioDevice.earpiece;
                    _isSpeakerOn = false;
                    _isBluetoothOn = false;
                  });
                  await _twilioService.toggleSpeaker(false);
                  await _twilioService.toggleBluetooth(false);
                  Navigator.pop(context);
                },
              ),
              _buildAudioDeviceOption(
                icon: Icons.volume_up,
                label: 'Speaker',
                isSelected: _selectedAudioDevice == AudioDevice.speaker,
                onTap: () async {
                  setState(() {
                    _selectedAudioDevice = AudioDevice.speaker;
                    _isSpeakerOn = true;
                    _isBluetoothOn = false;
                  });
                  await _twilioService.toggleSpeaker(true);
                  await _twilioService.toggleBluetooth(false);
                  Navigator.pop(context);
                },
              ),
              _buildAudioDeviceOption(
                icon: Icons.bluetooth,
                label: 'Bluetooth',
                isSelected: _selectedAudioDevice == AudioDevice.bluetooth,
                onTap: () async {
                  setState(() {
                    _selectedAudioDevice = AudioDevice.bluetooth;
                    _isSpeakerOn = false;
                    _isBluetoothOn = true;
                  });
                  await _twilioService.toggleSpeaker(false);
                  await _twilioService.toggleBluetooth(true);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAudioDeviceOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF185ADB).withOpacity(0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF185ADB),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  void _endCall() async {
    await _twilioService.hangUpCall();
  }

  void _toggleDialpad() {
    setState(() {
      _isDialpadVisible = !_isDialpadVisible;
    });
  }

  void _sendDigit(String digit) async {
    setState(() {
      _dialpadInput += digit;
    });
    await _twilioService.sendDigits(digit);
  }

  @override
  void dispose() {
    _callTimer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A1931),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF0A1931),
                const Color(0xFF185ADB).withOpacity(0.6),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                if (!_isDialpadVisible)
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.5),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      _callerName.isNotEmpty
                                          ? _callerName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF185ADB),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _callerName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _callerNumber,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _callDuration,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_isDialpadVisible)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _callDuration,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                if (_isDialpadVisible)
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24)),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              _dialpadInput,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final buttonWidth = constraints.maxWidth / 3;
                                final buttonHeight = constraints.maxHeight / 4;

                                return Center(
                                  child: SizedBox(
                                    width: constraints.maxWidth,
                                    height: constraints.maxHeight,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _buildResponsiveDialpadButton('1',
                                                '', buttonWidth, buttonHeight),
                                            _buildResponsiveDialpadButton(
                                                '2',
                                                'ABC',
                                                buttonWidth,
                                                buttonHeight),
                                            _buildResponsiveDialpadButton(
                                                '3',
                                                'DEF',
                                                buttonWidth,
                                                buttonHeight),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _buildResponsiveDialpadButton(
                                                '4',
                                                'GHI',
                                                buttonWidth,
                                                buttonHeight),
                                            _buildResponsiveDialpadButton(
                                                '5',
                                                'JKL',
                                                buttonWidth,
                                                buttonHeight),
                                            _buildResponsiveDialpadButton(
                                                '6',
                                                'MNO',
                                                buttonWidth,
                                                buttonHeight),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _buildResponsiveDialpadButton(
                                                '7',
                                                'PQRS',
                                                buttonWidth,
                                                buttonHeight),
                                            _buildResponsiveDialpadButton(
                                                '8',
                                                'TUV',
                                                buttonWidth,
                                                buttonHeight),
                                            _buildResponsiveDialpadButton(
                                                '9',
                                                'WXYZ',
                                                buttonWidth,
                                                buttonHeight),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _buildResponsiveDialpadButton('*',
                                                '', buttonWidth, buttonHeight),
                                            _buildResponsiveDialpadButton('0',
                                                '+', buttonWidth, buttonHeight),
                                            _buildResponsiveDialpadButton('#',
                                                '', buttonWidth, buttonHeight),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!_isDialpadVisible) const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            icon: Icons.mic_off,
                            label: 'Mute',
                            onPressed: _toggleMute,
                            isActive: _isMuted,
                          ),
                          _buildActionButton(
                            icon: Icons.dialpad,
                            label: 'Keypad',
                            onPressed: _toggleDialpad,
                            isActive: _isDialpadVisible,
                          ),
                          _buildActionButton(
                            icon: _selectedAudioDevice == AudioDevice.bluetooth
                                ? Icons.bluetooth_audio
                                : _selectedAudioDevice == AudioDevice.speaker
                                    ? Icons.volume_up
                                    : Icons.phone_in_talk,
                            label: _selectedAudioDevice == AudioDevice.bluetooth
                                ? 'Bluetooth'
                                : _selectedAudioDevice == AudioDevice.speaker
                                    ? 'Speaker'
                                    : 'Phone',
                            onPressed: _toggleBluetooth,
                            isActive:
                                _selectedAudioDevice != AudioDevice.earpiece,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildEndCallButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveDialpadButton(
      String digit, String subText, double width, double height) {
    return InkWell(
      onTap: () => _sendDigit(digit),
      child: Container(
        width: width * 0.85,
        height: height * 0.85,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              digit,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (subText.isNotEmpty)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    subText,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white.withOpacity(0.7),
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? const Color(0xFF185ADB)
                  : Colors.white.withOpacity(0.2),
            ),
            child: Icon(
              icon,
              size: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
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
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.call_end,
          size: 32,
          color: Colors.white,
        ),
      ),
    );
  }
}

enum AudioDevice {
  earpiece,
  speaker,
  bluetooth,
}
