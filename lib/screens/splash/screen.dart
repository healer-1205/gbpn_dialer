import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/assets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    bool isLoggedIn = await _authService.isLoggedIn();

    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/dialpad');
    } else {
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          ImageAssets.logo,
          width: 150,
          fit: BoxFit.fitWidth,
        ),
      ),
    );
  }
}
