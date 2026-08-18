import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/constants/app_images.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/core/widgets/custom_button.dart';
import 'package:plenty/presentation/auth/login.dart';
import 'package:plenty/presentation/auth/register.dart';

class AuthSelection extends StatelessWidget {
  const AuthSelection({super.key});

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
              Text(
                'Selamat datang di Plenty',
                style: AppTypography.subheadlineBold.copyWith(
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Daftar atau masuk ke akun anda',
                style: AppTypography.displayLarge.copyWith(
                  color: AppColors.inkSoft,
                  fontSize: 32,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 32),
              // Primary Register button
              CustomButton(
                text: 'Daftar',
                height: 54,
                borderRadius: BorderRadius.circular(30),
                onPressed: () {
                  context.push(const RegisterScreen());
                },
              ),
              const SizedBox(height: 16),
              // Separator "Atau"
              Row(
                children: [
                  const Expanded(
                    child: Divider(color: AppColors.border, thickness: 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Atau',
                      style: AppTypography.caption1Bold.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Divider(color: AppColors.border, thickness: 1),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Masuk dengan Email
              CustomButton(
                text: 'Masuk dengan Email',
                isOutlined: true,
                height: 54,
                borderRadius: BorderRadius.circular(30),
                icon: Icons.mail_outline,
                onPressed: () {
                  context.push(const LoginScreen());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
