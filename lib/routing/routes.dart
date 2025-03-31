import 'package:flutter/material.dart';
import 'package:gbpn_dealer/screens/incoming_screen/incoming_call_screen.dart';
import 'package:gbpn_dealer/screens/permissions/permissions_block.dart';
import '../screens/dialpad/dialer_screen.dart';
import '../screens/intro/screen.dart';
import '../screens/main_screen/main_screen_view.dart';
import '../screens/signin/screen.dart';
import '../screens/splash/screen.dart';

class Routes {
  static Route? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/intro':
        return MaterialPageRoute(builder: (_) => const MyHomeScreen());
      case '/splash':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/signin':
        return MaterialPageRoute(builder: (_) => const SignInScreen());
      case '/main':
        return MaterialPageRoute(builder: (_) => const MainScreenView());
      case '/dialpad':
        return MaterialPageRoute(builder: (_) => const DialpadScreen());
      case '/permission_block':
        return MaterialPageRoute(builder: (_) => const PermissionsBlock());
      case '/incoming_call_screen':
        return MaterialPageRoute(
            builder: (_) =>
                IncomingCallScreen(callerName: "My Testing Twilio"));
      default:
        return null;
    }
  }
}
