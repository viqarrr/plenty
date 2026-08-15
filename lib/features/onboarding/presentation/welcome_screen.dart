import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/constants/app_images.dart';
import 'package:plenty/core/constants/app_typography.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/core/utils/widgets/widgets.dart';
import 'package:plenty/features/authentication/presentation/login_screen.dart';
import 'package:plenty/features/onboarding/presentation/preferences_flow_screen.dart';

/// Welcome Screen (Figma node: Welcome 24:12592).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasDefault,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [Image.asset(AppImages.logoLight, height: 64)]),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  Text(
                    'Selamat datang di Plenty',
                    style: AppTypography.displayLarge.copyWith(
                      color: AppColors.inkSoft,
                      fontSize: 32,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    'Ubah kebiasaan merawat tanaman hiasmu menjadi rutinitas yang menyenangkan dan teratur.',
                    style: AppTypography.bodyRegular.copyWith(
                      color: AppColors.muted,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Start Button
              CustomButton(
                text: 'Mulai',
                borderRadius: BorderRadius.circular(30),
                height: 54,
                onPressed: () {
                  context.push(const PreferencesFlowScreen());
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'Sudah memiliki akun? ',
                      style: AppTypography.footnoteRegular.copyWith(
                        color: AppColors.inkSoft,
                      ),
                      children: [
                        TextSpan(
                          text: 'Masuk',
                          style: AppTypography.footnoteBold.copyWith(
                            color: AppColors.forest,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => context.push(const LoginScreen()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
