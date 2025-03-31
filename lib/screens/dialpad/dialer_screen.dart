import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gbpn_dealer/screens/permissions/permissions_block.dart'
    show PermissionState;
import 'package:gbpn_dealer/utils/extension.dart';
import 'package:gbpn_dealer/utils/utils.dart';
import 'package:twilio_voice/twilio_voice.dart';

import '../../services/storage_service.dart';
import '../../services/twilio_service.dart';

class DialpadScreen extends StatefulWidget {
  const DialpadScreen({super.key});

  @override
  State<DialpadScreen> createState() => _DialpadScreenState();
}

class _DialpadScreenState extends State<DialpadScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final TwilioService _twilioService = TwilioService(); // Singleton Instance
  late String twilioToken = "";
  StreamSubscription<CallEvent>? _callEventSubscription; // Store event listener

  @override
  void initState() {
    super.initState();
    _controller.text = "";
    //requestPermissions();
    Future.delayed(
      Duration(seconds: 1),
      () {
        _fetchTwilioToken();
      },
    );
  }

  /// Fetches and initializes Twilio Token
  Future<void> _fetchTwilioToken() async {
    try {
      final token = await StorageService().getTwilioAccessToken();
      if (token != null && !_twilioService.isTokenExpired(token)) {
        setState(() {
          twilioToken = token;
        });
        _initializeTwilio();
      } else {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/signin');
        }
      }
    } catch (e) {
      print("Error fetching Twilio token: $e");
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/signin');
      }
    }
  }

  /// Initialize Twilio Service
  Future<void> _initializeTwilio() async {
    try {
      final deviceToken = await StorageService().getFCMToken();
      await _twilioService.initialize(twilioToken, deviceToken!, context);

      _setupCallListeners();
      _permissionRequiredDialog();
    } catch (e) {
      printDebug("Error initializing Twilio: $e");
    }
  }

  Future<void> _permissionRequiredDialog() async {
    if (await PermissionState.checkAllPermissions()) return;
    await showAdaptiveDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Permission Required",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.security,
                size: 48,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                "To make calls, we need access to your phone permissions. Please grant the required permissions to continue.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                await Navigator.pushNamed(context, '/permission_block');
                Navigator.pop(context);
              },
              child: const Text("Proceed"),
            ),
          ],
        );
      },
    );
  }

  /// Setup call event listeners
  void _setupCallListeners() {
    _callEventSubscription = _twilioService.callEvents.listen((event) {
      if (!mounted) return;

      setState(() {
        print("Call event received: $event");
      });

      switch (event) {
        case CallEvent.callEnded:
          _controller.text = '';
          if (Navigator.canPop(context)) {
            Navigator.pop(context); // Close Outgoing Call Screen when call ends
          }
          break;
        case CallEvent.connected:
          print('Call Connected');
          break;
        case CallEvent.incoming:
          print('Incoming call');
          break;
        default:
          break;
      }
    });
  }

  @override
  void dispose() {
    _callEventSubscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onNumberPressed(String number) {
    int cursorPosition = _controller.selection.baseOffset;

    if (cursorPosition < 0) {
      cursorPosition = _controller.text.length;
    }

    String newText = _controller.text.substring(0, cursorPosition) +
        number +
        _controller.text.substring(cursorPosition);

    setState(() {
      _controller.text = newText;
      _controller.selection =
          TextSelection.collapsed(offset: cursorPosition + 1);
    });

    scrollToEndPosition();

    HapticFeedback.lightImpact();
  }

  void _onBackspace() {
    int cursorPosition = _controller.selection.baseOffset;

    if (cursorPosition > 0) {
      String newText = _controller.text.substring(0, cursorPosition - 1) +
          _controller.text.substring(cursorPosition);

      setState(() {
        _controller.text = newText;
        _controller.selection =
            TextSelection.collapsed(offset: cursorPosition - 1);
      });

      scrollToEndPosition();

      HapticFeedback.mediumImpact();
    }
  }

  void _onLongBackspace() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _controller.text = "";
      });

      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Align(
              //   alignment: Alignment.centerLeft,
              //   child: Text(
              //     "GBPN Dialer",
              //     style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              //   ),
              // ),
              _buildNumberDisplay(),
              _buildDialpad(),
              _buildActionButtons(),
            ],
          )

          // Old UI
          // Column(
          //   children: [
          //     const SizedBox(height: 50),
          //     const Align(
          //       alignment: Alignment.centerLeft,
          //       child: Text(
          //         "GBPN Dialer",
          //         style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          //       ),
          //     ),
          //     const Spacer(),
          //     _buildNumberDisplay(),
          //     const SizedBox(height: 10),
          //     _buildDialpad(),
          //     const SizedBox(height: 20),
          //     _buildActionButtons(),
          //     const SizedBox(height: 40),
          //   ],
          // ),
          ),
      // bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildNumberDisplay() {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      scrollController: _scrollController,
      readOnly: true,
      showCursor: true,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      decoration: const InputDecoration(
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildDialpad() {
    return Column(
      children: [
        _buildRow(["1", "2", "3"], ["", "ABC", "DEF"]),
        const SizedBox(height: 10),
        _buildRow(["4", "5", "6"], ["GHI", "JKL", "MNO"]),
        const SizedBox(height: 10),
        _buildRow(["7", "8", "9"], ["PQRS", "TUV", "WXYZ"]),
        const SizedBox(height: 10),
        _buildRow(["*", "0", "#"], ["", "+", ""]),
      ],
    );
  }

  Widget _buildRow(List<String> numbers, List<String> subTexts) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(3, (index) {
        return _buildDialButton(numbers[index], subTexts[index]);
      }),
    );
  }

  Widget _buildDialButton(String number, String subText) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onNumberPressed(number),
        child: Container(
          height: context.screenWidth / 5.5,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 187, 186, 186),
            shape: BoxShape.circle,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                number,
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              if (subText.isNotEmpty)
                Text(
                  subText,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Spacer(),
        Expanded(
          child: Align(
            alignment: Alignment.center,
            child: _buildCallButton(),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: _buildBackspaceButton(),
          ),
        ),
      ],
    );
  }

  Widget _buildCallButton() {
    IconData icon = Icons.call;
    Color buttonColor = Colors.green;

    return GestureDetector(
      // onTap: _isCallActive ? _hangUpCall : _makeCall,
      onTap: _makeCall,
      child: Container(
        height: context.screenWidth / 5.5,
        width: context.screenWidth / 5.5,
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return GestureDetector(
      onTap: _onBackspace,
      onLongPress: _onLongBackspace,
      behavior: HitTestBehavior.translucent,
      child: const SizedBox(
        width: 70,
        height: 70,
        child: Icon(
          Icons.backspace,
          color: Color.fromARGB(255, 187, 186, 186),
          size: 32,
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem("Keypad", true),
          _buildNavItem("Recents", false),
          _buildNavItem("Contacts", false),
        ],
      ),
    );
  }

  Widget _buildNavItem(String text, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text,
            style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.black : Colors.grey)),
        if (isSelected)
          Container(
              width: 40,
              height: 2,
              color: Colors.black,
              margin: const EdgeInsets.only(top: 4)),
      ],
    );
  }

  void scrollToEndPosition() {
    _scrollController.animateTo(_scrollController.position.maxScrollExtent + 13,
        curve: Curves.ease, duration: Duration(milliseconds: 100));
    _focusNode.requestFocus();
  }

  /// Make a call using Twilio
  void _makeCall() async {
    if (_controller.text.isEmpty) return;

    try {
      bool hasPermission = await PermissionState.checkAllPermissions();
      if (!hasPermission) {
        printDebug("⚠️ No Phone Account Registered! Registering now...");
        await _permissionRequiredDialog();
      }

      if (!_twilioService.isTokenExpired(twilioToken)) {
        // Place the call
        await _twilioService.makeCall(_controller.text);
      } else {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/signin');
        }
      }
    } catch (e) {
      printDebug("Call failed: $e");
    }
  }
}
