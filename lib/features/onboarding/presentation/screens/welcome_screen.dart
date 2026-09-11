import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/core/widgets/custom_button.dart';
import 'package:plenty/features/auth/presentation/screens/login_screen.dart';
import 'package:plenty/features/onboarding/presentation/screens/preference_flow.dart';
import 'package:plenty/features/onboarding/presentation/widgets/hero_illustration_container.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  static const List<_WelcomeSlide> _slides = [
    _WelcomeSlide(
      animationPath: 'assets/animations/leaf_line.json',
      primaryBackdropColor: Color(0xFF4A6B5B),
      secondaryBackdropColor: Color(0xFF6B8F7D),
      title: 'Jangan Pernah Lupa Menyiram',
      description:
          'Pengingat cerdas otomatis yang menyesuaikan kebutuhan air dan paparan sinar matahari tiap tanaman.',
    ),
    _WelcomeSlide(
      animationPath: 'assets/animations/tree_leaf.json',
      primaryBackdropColor: Color(0xFFD48C53),
      secondaryBackdropColor: Color(0xFFE5A876),
      title: 'Raih Lencana & Koleksi Prestasi',
      description:
          'Pertahankan streak merawat harian, kumpulkan poin pengalaman (XP), dan buka lencana botani eksklusif.',
    ),
    _WelcomeSlide(
      animationPath: 'assets/animations/monstera_leaf.json',
      primaryBackdropColor: Color(0xFF4A6B5B),
      secondaryBackdropColor: Color(0xFF7E9F8E),
      title: 'Pantau Tumbuh Kembang Tanamanmu',
      description:
          'Catat tinggi tanaman secara berkala, simpan foto perkembangan, dan amati daun barunya tumbuh subur.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasDefault,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Middle Section: Onboarding Carousel Slider
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: _onPageChanged,
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];

                  return Center(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 6),
                            // Unbounded Hero Lottie Animation (no blob background, extra large)
                            HeroIllustrationContainer(
                              animationPath: slide.animationPath,
                              repeatAnimation: false,
                              showBackdrop: false,
                              size: 320,
                              iconSize: 320,
                            ),
                            const SizedBox(height: 18),

                            // Main Title
                            Text(
                              slide.title,
                              style: AppTypography.displayLarge.copyWith(
                                color: AppColors.inkSoft,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                                letterSpacing: -0.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),

                            // Description
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Text(
                                slide.description,
                                style: AppTypography.bodyRegular.copyWith(
                                  color: AppColors.muted,
                                  fontSize: 14,
                                  height: 1.45,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Dot Pagination Indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (index) {
                  final isActive = index == _currentPage;
                  return GestureDetector(
                    onTap: () => _goToPage(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 24 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.forest
                            : AppColors.forest.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Bottom Actions: Mulai & Masuk
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomButton(
                    text: 'Mulai',
                    height: 52,
                    borderRadius: BorderRadius.circular(28),
                    onPressed: () {
                      context.push(const PreferencesFlowScreen());
                    },
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: RichText(
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeSlide {
  final String animationPath;
  final Color primaryBackdropColor;
  final Color secondaryBackdropColor;
  final String title;
  final String description;

  const _WelcomeSlide({
    required this.animationPath,
    required this.primaryBackdropColor,
    required this.secondaryBackdropColor,
    required this.title,
    required this.description,
  });
}
