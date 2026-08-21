import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/constants/app_images.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/auth/presentation/screens/auth_selection_screen.dart';
import 'package:plenty/features/garden/presentation/screens/home_screen.dart';
import 'package:plenty/features/profile/presentation/screens/welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleInitialNavigation();
  }

  Future<void> _handleInitialNavigation() async {
    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (PreferenceHandler.isOnboard) {
      if (PreferenceHandler.isLogin) {
        context.pushReplacement(const HomeScreen());
      } else {
        context.pushReplacement(const AuthSelectionScreen());
      }
    } else {
      context.pushReplacement(const WelcomeScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.forest,
      body: Center(
        child: Image.asset(
          AppImages.logoDark,
          width: 250,
          errorBuilder: (context, error, stackTrace) => const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.spa, color: Colors.white, size: 48),
              SizedBox(width: 12),
              Text(
                'Plenty',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
