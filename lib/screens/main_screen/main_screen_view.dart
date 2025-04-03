import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gbpn_dealer/screens/dialpad/active_number_reminder_dialog.dart';
import 'package:gbpn_dealer/screens/out_going_call/out_going_call.dart';
import 'package:gbpn_dealer/screens/permissions/permissions_block.dart';
import 'package:gbpn_dealer/services/storage_service.dart';
import 'package:gbpn_dealer/services/twilio_service.dart';
import 'package:gbpn_dealer/utils/utils.dart';
import 'package:twilio_voice/models/call_event.dart';

import '../contacts/contact_screen.dart';
import '../dialpad/dialer_screen.dart';
import '../recent/recent_screen.dart';

class MainScreenView extends StatefulWidget {
  const MainScreenView({super.key});

  @override
  State<MainScreenView> createState() => _MainScreenViewState();
}

class _MainScreenViewState extends State<MainScreenView> {
  List<Widget> pages = <Widget>[];
  int _currentIndex = 0;
  late final TwilioService _twilioService;
  late String twilioToken = "";
  StreamSubscription<CallEvent>? _callEventSubscription; // Store event listener
  final TextEditingController _controller = TextEditingController();
  @override
  void initState() {
    super.initState();
    pages = [
      DialpadScreen(
        phoneNumberController: _controller,
        onMakeCall: _makeCall,
      ),
      RecentScreen(),
      ContactScreen(
        onMakeCall: _makeCall,
      ),
    ];
    _twilioService = TwilioService();
    //requestPermissions();
    Future.delayed(
      Duration(seconds: 1),
      () {
        _fetchTwilioToken();
      },
    );
  }

  @override
  void dispose() {
    _callEventSubscription?.cancel(); // Cancel event listener
    _controller.dispose();
    super.dispose();
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
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/signin');
      }
    }
  }

  /// Initialize Twilio Service
  Future<void> _initializeTwilio() async {
    try {
      final deviceToken = await StorageService().getFCMToken();
      if (!mounted) return;
      await _twilioService.initialize(twilioToken, deviceToken!, context);

      _setupCallListeners();
      _permissionRequiredDialog();
    } catch (e) {
      printDebug("Error initializing Twilio: $e");
    }
  }

  /// Setup call event listeners
  void _setupCallListeners() {
    _callEventSubscription = _twilioService.callEvents.listen((event) {
      if (!mounted) return;
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

  // Usage example:
  void _showActiveNumberReminder(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ActiveNumberReminderDialog(
        onNavigateToSettings: () {
          // Navigate to settings screen
          Navigator.pushNamed(context, '/settings');
        },
      ),
    );
  }

  Future<void> _permissionRequiredDialog() async {
    if (await PermissionState.checkAllPermissions()) return;
    if (!mounted) return;
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
                Navigator.pop(context);
                await Navigator.pushNamed(context, '/permission_block');
              },
              child: const Text("Proceed"),
            ),
          ],
        );
      },
    );
  }

  /// Make a call using Twilio
  void _makeCall(String phoneNumber, {String? name}) async {
    if (phoneNumber.isEmpty) return;

    try {
      bool hasPermission = await PermissionState.checkAllPermissions();
      if (!hasPermission) {
        printDebug("⚠️ No Phone Account Registered! Registering now...");
        _permissionRequiredDialog();
        return;
      }

      if (!_twilioService.isTokenExpired(twilioToken)) {
        final fromNumber = await StorageService().getActivePhoneNumber();
        if (!mounted) return;
        if (fromNumber == null) {
          _showActiveNumberReminder(context);
          return;
        }
        if (Platform.isIOS) {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return CallScreen(
              phoneNumber: phoneNumber,
              callerName: name ?? phoneNumber,
              twilioService: _twilioService,
            );
          }));
        }
        // Place the call
        await _twilioService.makeCall(fromNumber.phoneNumber, phoneNumber);
      } else {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/signin');
        }
      }
    } catch (e) {
      printDebug("Call failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        title: Text(
          _currentIndex == 0
              ? "GBPN Dialer"
              : _currentIndex == 1
                  ? "Recent"
                  : "Contacts",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          Visibility(
            visible: _currentIndex == 1,
            child: IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.menu,
                size: 30,
              ),
            ),
          ),
          Visibility(
            visible: _currentIndex == 0,
            child: IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
              icon: Icon(
                Icons.settings,
                size: 30,
              ),
            ),
          ),
          SizedBox(width: 15),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        elevation: 5,
        selectedItemColor: Colors.black,
        showSelectedLabels: true,
        showUnselectedLabels: false,
        selectedIconTheme: IconThemeData(size: 30),
        backgroundColor: Colors.white,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dialpad),
            label: 'Keypad',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.watch_later_outlined),
            label: 'Recent',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contact_page),
            label: 'Contacts',
          ),
        ],
      ),
    );
  }
}
