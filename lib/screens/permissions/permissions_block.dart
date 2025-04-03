import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gbpn_dealer/utils/utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twilio_voice/twilio_voice.dart';

import 'permission_tile.dart';

class PermissionsBlock extends StatefulWidget {
  const PermissionsBlock({super.key});

  @override
  State<PermissionsBlock> createState() => _PermissionsBlockState();
}

class _PermissionsBlockState extends State<PermissionsBlock> {
  final _tv = TwilioVoice.instance;
  bool activeCall = false;

  //#region #region Permissions
  bool _hasMicPermission = false;

  set setMicPermission(bool value) {
    if (!mounted) return;
    setState(() {
      _hasMicPermission = value;
    });
  }

  bool _hasRegisteredPhoneAccount = false;

  set setPhoneAccountRegistered(bool value) {
    if (!mounted) return;
    setState(() {
      _hasRegisteredPhoneAccount = value;
    });
  }

  bool _hasCallPhonePermission = false;

  set setCallPhonePermission(bool value) {
    if (!mounted) return;
    setState(() {
      _hasCallPhonePermission = value;
    });
  }

  bool _hasManageCallsPermission = false;

  set setManageCallsPermission(bool value) {
    if (!mounted) return;
    setState(() {
      _hasManageCallsPermission = value;
    });
  }

  bool _isPhoneAccountEnabled = false;

  set setIsPhoneAccountEnabled(bool value) {
    if (!mounted) return;
    setState(() {
      _isPhoneAccountEnabled = value;
    });
  }

  bool _hasReadPhoneStatePermission = false;

  set setReadPhoneStatePermission(bool value) {
    if (!mounted) return;
    setState(() {
      _hasReadPhoneStatePermission = value;
    });
  }

  bool _hasReadPhoneNumbersPermission = false;

  set setReadPhoneNumbersPermission(bool value) {
    if (!mounted) return;
    setState(() {
      _hasReadPhoneNumbersPermission = value;
    });
  }

  bool _hasBackgroundPermissions = false;

  set setBackgroundPermission(bool value) {
    if (!mounted) return;
    setState(() {
      _hasBackgroundPermissions = value;
    });
  }

  bool _hasIgnoreBatteryOptimizationPermission = false;

  set setIgnoreBatteryOptimizationPermission(bool value) {
    if (!mounted) return;
    setState(() {
      _hasIgnoreBatteryOptimizationPermission = value;
    });
  }

  late List<bool> _allPermissions = [
    _hasMicPermission,
    _hasRegisteredPhoneAccount,
    _hasCallPhonePermission,
    _hasManageCallsPermission,
    _isPhoneAccountEnabled,
    _hasReadPhoneStatePermission,
    _hasReadPhoneNumbersPermission,
    _hasBackgroundPermissions,
    _hasIgnoreBatteryOptimizationPermission,
  ];

  @override
  void initState() {
    super.initState();
    _updatePermissions();
  }

  void _updatePermissions() {
    // get all permission states
    _tv.hasMicAccess().then((value) => setMicPermission = value);
    _tv
        .hasReadPhoneStatePermission()
        .then((value) => setReadPhoneStatePermission = value);
    _tv
        .hasReadPhoneNumbersPermission()
        .then((value) => setReadPhoneNumbersPermission = value);
    if (Firebase.apps.isNotEmpty) {
      FirebaseMessaging.instance.requestPermission().then((value) =>
          setBackgroundPermission =
              value.authorizationStatus == AuthorizationStatus.authorized);
    }
    _tv
        .hasCallPhonePermission()
        .then((value) => setCallPhonePermission = value);
    _tv
        .hasManageOwnCallsPermission()
        .then((value) => setManageCallsPermission = value);
    _tv
        .hasRegisteredPhoneAccount()
        .then((value) => setPhoneAccountRegistered = value);
    _tv
        .isPhoneAccountEnabled()
        .then((value) => setIsPhoneAccountEnabled = value);

    // Check battery optimization permission
    if (!kIsWeb && Platform.isAndroid) {
      Permission.ignoreBatteryOptimizations.status.then((status) =>
          setIgnoreBatteryOptimizationPermission = status.isGranted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop && result != null) return;
          _updatePermissions();
          _allPermissions = [
            _hasMicPermission,
            _hasRegisteredPhoneAccount,
            _hasCallPhonePermission,
            _hasManageCallsPermission,
            _isPhoneAccountEnabled,
            _hasReadPhoneStatePermission,
            _hasReadPhoneNumbersPermission,
            _hasIgnoreBatteryOptimizationPermission,
          ];

          if (_allPermissions.any(
            (element) => false == element,
          )) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please grant all permissions")),
            );
          } else {
            PermissionState.savePermissionState(
                hasMicPermission: _hasMicPermission,
                hasReadPhoneStatePermission: _hasReadPhoneStatePermission,
                hasReadPhoneNumbersPermission: _hasReadPhoneNumbersPermission,
                hasCallPhonePermission: _hasCallPhonePermission,
                hasManageCallsPermission: _hasManageCallsPermission,
                hasRegisteredPhoneAccount: _hasRegisteredPhoneAccount,
                isPhoneAccountEnabled: _isPhoneAccountEnabled,
                hasIgnoreBatteryOptimizationPermission:
                    _hasIgnoreBatteryOptimizationPermission);
            Navigator.of(context).pop(true);
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // permissions
                Text("Permissions",
                    style: Theme.of(context).textTheme.titleLarge),

                Column(
                  children: [
                    PermissionTile(
                      icon: Icons.mic,
                      title: "Microphone",
                      granted: _hasMicPermission,
                      onRequestPermission: () async {
                        await _tv.requestMicAccess();
                        setMicPermission = await _tv.hasMicAccess();
                      },
                    ),

                    if (Firebase.apps.isNotEmpty)
                      PermissionTile(
                        icon: Icons.notifications,
                        title: "Notifications",
                        granted: _hasBackgroundPermissions,
                        onRequestPermission: () async {
                          await FirebaseMessaging.instance.requestPermission();
                          final settings = await FirebaseMessaging.instance
                              .getNotificationSettings();
                          setBackgroundPermission =
                              settings.authorizationStatus ==
                                  AuthorizationStatus.authorized;
                        },
                      ),

                    // if android
                    if (!kIsWeb && Platform.isAndroid)
                      PermissionTile(
                        icon: Icons.phone,
                        title: "Read Phone State",
                        granted: _hasReadPhoneStatePermission,
                        onRequestPermission: () async {
                          await _tv.requestReadPhoneStatePermission();
                          setReadPhoneStatePermission =
                              await _tv.hasReadPhoneStatePermission();
                        },
                      ),

                    // if android
                    if (!kIsWeb && Platform.isAndroid)
                      PermissionTile(
                        icon: Icons.phone,
                        title: "Read Phone Numbers",
                        granted: _hasReadPhoneNumbersPermission,
                        onRequestPermission: () async {
                          await _tv.requestReadPhoneNumbersPermission();
                          setReadPhoneNumbersPermission =
                              await _tv.hasReadPhoneNumbersPermission();
                        },
                      ),

                    // if android
                    if (!kIsWeb && Platform.isAndroid)
                      PermissionTile(
                        icon: Icons.call_made,
                        title: "Call Phone",
                        granted: _hasCallPhonePermission,
                        onRequestPermission: () async {
                          await _tv.requestCallPhonePermission();
                          setCallPhonePermission =
                              await _tv.hasCallPhonePermission();
                        },
                      ),

                    // if android
                    if (!kIsWeb && Platform.isAndroid)
                      PermissionTile(
                        icon: Icons.call_received,
                        title: "Manage Calls",
                        granted: _hasManageCallsPermission,
                        onRequestPermission: () async {
                          await _tv.requestManageOwnCallsPermission();
                          setManageCallsPermission =
                              await _tv.hasManageOwnCallsPermission();
                        },
                      ),

                    // if android
                    if (!kIsWeb && Platform.isAndroid)
                      PermissionTile(
                        icon: Icons.phonelink_setup,
                        title: "Phone Account",
                        granted: _hasRegisteredPhoneAccount,
                        onRequestPermission: () async {
                          await _tv.registerPhoneAccount();
                          setPhoneAccountRegistered =
                              await _tv.hasRegisteredPhoneAccount();
                        },
                      ),

                    // if android
                    if (!kIsWeb && Platform.isAndroid)
                      PermissionTile(
                        icon: Icons.battery_alert,
                        title: "Ignore Battery Optimization",
                        granted: _hasIgnoreBatteryOptimizationPermission,
                        onRequestPermission: () async {
                          if (!_hasIgnoreBatteryOptimizationPermission) {
                            await Permission.ignoreBatteryOptimizations
                                .request();
                            final status = await Permission
                                .ignoreBatteryOptimizations.status;
                            setIgnoreBatteryOptimizationPermission =
                                status.isGranted;
                          }
                        },
                      ),

                    // if android
                    if (!kIsWeb && Platform.isAndroid)
                      ListTile(
                        enabled: _hasRegisteredPhoneAccount,
                        dense: true,
                        leading: const Icon(Icons.phonelink_lock_outlined),
                        title: const Text("Phone Account Status"),
                        subtitle: Text(_hasRegisteredPhoneAccount
                            ? (_isPhoneAccountEnabled
                                ? "Enabled"
                                : "Not Enabled")
                            : "Not Registered"),
                        trailing: ElevatedButton(
                          onPressed: _hasRegisteredPhoneAccount &&
                                  !_isPhoneAccountEnabled
                              ? () async {
                                  if (_isPhoneAccountEnabled) {
                                    if (!mounted) return;
                                    setState(() {
                                      _updatePermissions();
                                    });
                                    return;
                                  }
                                  await _tv.openPhoneAccountSettings();
                                  _isPhoneAccountEnabled =
                                      await _tv.isPhoneAccountEnabled();
                                  _updatePermissions();
                                }
                              : null,
                          child: const Text("Open Settings"),
                        ),
                      ),
                    Align(
                      child: ElevatedButton(
                        onPressed: () async {
                          _isPhoneAccountEnabled =
                              await _tv.isPhoneAccountEnabled();
                          _updatePermissions();
                          if (_isPhoneAccountEnabled) {
                            Navigator.pop(context, true);
                            PermissionState.savePermissionState(
                                hasMicPermission: _hasMicPermission,
                                hasReadPhoneStatePermission:
                                    _hasReadPhoneStatePermission,
                                hasReadPhoneNumbersPermission:
                                    _hasReadPhoneNumbersPermission,
                                hasCallPhonePermission: _hasCallPhonePermission,
                                hasManageCallsPermission:
                                    _hasManageCallsPermission,
                                hasRegisteredPhoneAccount:
                                    _hasRegisteredPhoneAccount,
                                isPhoneAccountEnabled: _isPhoneAccountEnabled,
                                hasIgnoreBatteryOptimizationPermission:
                                    _hasIgnoreBatteryOptimizationPermission);
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Please grant all permissions")),
                          );
                        },
                        child: Text('Go back'),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class PermissionState {
  static const String _micPermissionKey = 'mic_permission';
  static const String _phoneStateKey = 'phone_state_permission';
  static const String _phoneNumbersKey = 'phone_numbers_permission';
  static const String _callPhoneKey = 'call_phone_permission';
  static const String _manageCallsKey = 'manage_calls_permission';
  static const String _phoneAccountKey = 'phone_account_permission';
  static const String _accountEnabledKey = 'account_enabled';
  static const String _ignoreBatteryOptimizationKey =
      'ignore_battery_optimization';

  static Future<void> savePermissionState({
    required bool hasMicPermission,
    required bool hasReadPhoneStatePermission,
    required bool hasReadPhoneNumbersPermission,
    required bool hasCallPhonePermission,
    required bool hasManageCallsPermission,
    required bool hasRegisteredPhoneAccount,
    required bool isPhoneAccountEnabled,
    required bool hasIgnoreBatteryOptimizationPermission,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_micPermissionKey, hasMicPermission);
    await prefs.setBool(_phoneStateKey, hasReadPhoneStatePermission);
    await prefs.setBool(_phoneNumbersKey, hasReadPhoneNumbersPermission);
    await prefs.setBool(_callPhoneKey, hasCallPhonePermission);
    await prefs.setBool(_manageCallsKey, hasManageCallsPermission);
    await prefs.setBool(_phoneAccountKey, hasRegisteredPhoneAccount);
    await prefs.setBool(_accountEnabledKey, isPhoneAccountEnabled);
    await prefs.setBool(
        _ignoreBatteryOptimizationKey, hasIgnoreBatteryOptimizationPermission);
  }

  static Future<bool> checkAllPermissions() async {
    final _tv = TwilioVoice.instance;
    final prefs = await SharedPreferences.getInstance();

    // Check and save microphone access
    final hasMicPermission = await _tv.hasMicAccess();
    await prefs.setBool(_micPermissionKey, hasMicPermission);

    // Check and save phone state permission
    final hasReadPhoneStatePermission = await _tv.hasReadPhoneStatePermission();
    await prefs.setBool(_phoneStateKey, hasReadPhoneStatePermission);

    // Check and save phone numbers permission
    final hasReadPhoneNumbersPermission =
        await _tv.hasReadPhoneNumbersPermission();
    await prefs.setBool(_phoneNumbersKey, hasReadPhoneNumbersPermission);

    // Check and save call phone permission
    final hasCallPhonePermission = await _tv.hasCallPhonePermission();
    await prefs.setBool(_callPhoneKey, hasCallPhonePermission);

    // Check and save manage calls permission
    final hasManageCallsPermission = await _tv.hasManageOwnCallsPermission();
    await prefs.setBool(_manageCallsKey, hasManageCallsPermission);

    // Check and save phone account registration
    final hasRegisteredPhoneAccount = await _tv.hasRegisteredPhoneAccount();
    await prefs.setBool(_phoneAccountKey, hasRegisteredPhoneAccount);

    // Check and save if phone account is enabled
    final isPhoneAccountEnabled = await _tv.isPhoneAccountEnabled();
    await prefs.setBool(_accountEnabledKey, isPhoneAccountEnabled);

    // Check and save battery optimization permission
    bool hasIgnoreBatteryOptimizationPermission = false;
    if (!kIsWeb && Platform.isAndroid) {
      final status = await Permission.ignoreBatteryOptimizations.status;
      hasIgnoreBatteryOptimizationPermission = status.isGranted;
      await prefs.setBool(_ignoreBatteryOptimizationKey,
          hasIgnoreBatteryOptimizationPermission);
    } else {
      await prefs.setBool(_ignoreBatteryOptimizationKey, true);
      hasIgnoreBatteryOptimizationPermission = true;
    }

    return hasMicPermission &&
        hasReadPhoneStatePermission &&
        hasReadPhoneNumbersPermission &&
        hasCallPhonePermission &&
        hasManageCallsPermission &&
        hasRegisteredPhoneAccount &&
        isPhoneAccountEnabled &&
        hasIgnoreBatteryOptimizationPermission;
  }

  static Future<bool> getStoredPermissionState() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_micPermissionKey) == true &&
        prefs.getBool(_phoneStateKey) == true &&
        prefs.getBool(_phoneNumbersKey) == true &&
        prefs.getBool(_callPhoneKey) == true &&
        prefs.getBool(_manageCallsKey) == true &&
        prefs.getBool(_phoneAccountKey) == true &&
        prefs.getBool(_accountEnabledKey) == true &&
        prefs.getBool(_ignoreBatteryOptimizationKey) == true;
  }
}
