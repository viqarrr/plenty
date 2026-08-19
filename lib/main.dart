import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plenty/core/constants/app_theme.dart';
import 'package:plenty/data/datasources/preference_handler.dart';
import 'package:plenty/presentation/onboarding/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PreferenceHandler.init();
  await dotenv.load(fileName: '.env');
  runApp(const ProviderScope(child: PlentyApp()));
}

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
