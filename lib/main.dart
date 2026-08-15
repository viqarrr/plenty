import 'package:flutter/material.dart';
import 'package:plenty/constants/app_theme.dart';
import 'package:plenty/features/splash_screen/views/splash_screen.dart';
import 'package:plenty/services/preference_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PreferenceHandler.init();
  // await initializeDateFormatting("id_ID", null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plenty',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: SplashScreen(),
    );
  }
}
