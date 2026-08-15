import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/constants/app_typography.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/core/utils/widgets/widgets.dart';
import 'package:plenty/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:plenty/features/authentication/domain/repositories/auth_repository.dart';
import 'package:plenty/features/authentication/presentation/register_screen.dart';
import 'package:plenty/features/plant/presentation/home/home_screen.dart';

/// Login Screen (Figma node: Login 83:2308).
class LoginScreen extends StatefulWidget {
  final AuthRepository? authRepository;

  const LoginScreen({super.key, this.authRepository});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AuthRepository _authRepository;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? AuthRepositoryImpl();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final result = await _authRepository.login(
      email: email,
      password: password,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.when(
      success: (user) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selamat datang kembali, ${user.displayName}!'),
            backgroundColor: AppColors.emerald,
          ),
        );
        context.pushAndRemoveAll(const HomeScreen());
      },
      error: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppColors.error,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasDefault,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Masuk ke akun anda',
                  style: AppTypography.displayLarge.copyWith(
                    color: AppColors.inkSoft,
                    fontSize: 36,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masukkan email dan kata sandi anda untuk masuk.',
                  style: AppTypography.bodyRegular.copyWith(
                    color: AppColors.mutedGray,
                  ),
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email / Username',
                  hintText: 'budihartono / nama@gmail.com',
                  keyboardType: TextInputType.emailAddress,
                  supportingText: 'Gunakan email atau username terdaftar',
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: AppColors.mutedGray,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Email atau username wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _passwordController,
                  label: 'Kata Sandi',
                  hintText: '••••••••',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  supportingText: 'Minimal 8 karakter kombinasi huruf & angka',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppColors.mutedGray,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.mutedGray,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Kata sandi wajib diisi';
                    }
                    if (val.length < 4) {
                      return 'Kata sandi minimal 4 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Masuk',
                  height: 54,
                  borderRadius: BorderRadius.circular(30),
                  isLoading: _isLoading,
                  onPressed: _handleLogin,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: 'Belum memiliki akun? ',
                        style: AppTypography.footnoteRegular.copyWith(
                          color: AppColors.inkSoft,
                        ),
                        children: [
                          TextSpan(
                            text: 'Daftar',
                            style: AppTypography.footnoteBold.copyWith(
                              color: AppColors.forest,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => context.push(const RegisterScreen()),
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
      ),
    );
  }
}
