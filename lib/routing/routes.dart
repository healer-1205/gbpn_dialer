import 'package:flutter/material.dart';
import '../screens/intro/screen.dart';
import '../screens/signin/screen.dart';
import '../screens/dialpad/screen.dart';
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
      case '/dialpad':
        return MaterialPageRoute(builder: (_) => const DialpadScreen());
      default:
        return null;
    }
  }
}
