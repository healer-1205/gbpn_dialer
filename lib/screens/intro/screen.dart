import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/style.dart';
import '../../utils/assets.dart';
import '../../utils/constant.dart';

class MyHomeScreen extends StatefulWidget {
  const MyHomeScreen({super.key});

  @override
  State<MyHomeScreen> createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<MyHomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

    if (!isFirstLaunch) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/splash');
      }
    }
  }

  Future<void> _completeOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLaunch', false); // Mark as seen
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/signin'); // Navigate to login
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Text(
              StringConstants.appTitle,
              style: AppStyles.textStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "Powers voice and messages across your devices",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                ImageAssets.homeImage,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _completeOnboarding,
            style: AppStyles.elevatedButtonStyle(
              backgroundColor: Colors.deepPurpleAccent,
              foregroundColor: Colors.white,
              borderRadius: 12.0,
            ),
            child: const Text(
              "Start making calls",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
