import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_theme.dart';
import 'package:plenty/core/database/preference_handler.dart';
import 'package:plenty/features/splash/presentation/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PreferenceHandler.init();
  runApp(const PlentyApp());
}

/// Root application widget configuring Theme and navigation router.
class PlentyApp extends StatelessWidget {
  const PlentyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plenty',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const SplashScreen(),
    );
  }
}
