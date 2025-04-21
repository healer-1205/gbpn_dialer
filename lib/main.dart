import 'dart:isolate';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gbpn_dealer/helpers/call_manager.dart';
import 'package:gbpn_dealer/services/firebase_options.dart';
import 'package:gbpn_dealer/services/firebase_service.dart';
import 'package:gbpn_dealer/services/twilio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'routing/routes.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  await FirebaseService().initialize();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final ReceivePort receivePort = ReceivePort();
  IsolateNameServer.registerPortWithName(
    receivePort.sendPort,
    'twilio_call_port',
  );

  receivePort.listen((message) {
    if (message is Map<String, dynamic>) {
      TwilioService().handleIncomingCallFromTerminated(message);
    }
  });

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.white,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  bool isFirstLaunch = await _checkFirstLaunch();
  runApp(MyApp(initialRoute: isFirstLaunch ? '/intro' : '/splash'));
}

Future<bool> _checkFirstLaunch() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isFirstLaunch') ?? true;
}

class MyApp extends StatefulWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
      builder: (context, child) {
        return Container(
          child: child ?? const SizedBox.shrink(),
        );
      },
      navigatorKey: navigatorKey,
      initialRoute: widget.initialRoute,
      onGenerateRoute: Routes.generateRoute,
    );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  print("Handling background message: ${message.messageId}");

  if (message.data.containsKey('twi_message_type') &&
      message.data['twi_message_type'] == 'twilio.voice.call') {
    final SendPort? sendPort =
        IsolateNameServer.lookupPortByName('twilio_call_port');

    if (sendPort != null) {
      sendPort.send(message.data);
    } else {}
  }
}
