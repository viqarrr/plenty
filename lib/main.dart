import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:plenty/core/constants/app_theme.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/profile/presentation/screens/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PreferenceHandler.init();
  await dotenv.load(fileName: '.env');
  runApp(const PlentyApp());
}

class PlentyApp extends StatelessWidget {
  const PlentyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plenty',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
