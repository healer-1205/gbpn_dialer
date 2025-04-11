import 'package:flutter/material.dart';
import 'package:gbpn_dealer/screens/permissions/permissions_block.dart';
import 'package:gbpn_dealer/screens/settings/settings_screen.dart';
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
      case '/permission_block':
        return MaterialPageRoute(builder: (_) => const PermissionsBlock());
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      default:
        return null;
    }
  }
}
