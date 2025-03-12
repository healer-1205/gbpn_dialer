import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'routing/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
      builder: (context, child) {
        return SafeArea(
          child: child ?? const SizedBox.shrink(),
        );
      },
      initialRoute: initialRoute,
      onGenerateRoute: Routes.generateRoute,
    );
  }
}
