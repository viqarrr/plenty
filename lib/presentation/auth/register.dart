import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/core/widgets/custom_button.dart';
import 'package:plenty/core/widgets/custom_text_field.dart';
import 'package:plenty/data/models/user_model.dart';
import 'package:plenty/data/repositories/auth_repository_impl.dart';
import 'package:plenty/presentation/auth/login.dart';

class RegisterScreen extends StatefulWidget {
  final AuthRepositoryImpl? authRepository;

  const RegisterScreen({super.key, this.authRepository});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  final List<GlobalKey<FormState>> _formKeys = List.generate(
    5,
    (_) => GlobalKey<FormState>(),
  );

  final _displayNameC = TextEditingController();
  final _usernameC = TextEditingController();
  final _emailC = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final AuthRepositoryImpl _authRepository;
  int _currentStep = 0;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? AuthRepositoryImpl();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _displayNameC.dispose();
    _usernameC.dispose();
    _emailC.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  List<Widget> get _inputPages => [
    _buildStepPage(
      stepIndex: 0,
      title: 'Beritahu kami siapa namamu',
      desc: 'Agar kami tahu bagaimana memanggilmu.',
      inputField: CustomTextField(
        controller: _displayNameC,
        label: 'Nama Lengkap',
        hintText: 'Contoh: Budi Hartono',
        prefixIcon: const Icon(
          Icons.person_outline,
          color: AppColors.mutedGray,
        ),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
      ),
    ),
    _buildStepPage(
      stepIndex: 1,
      title: 'Buat username',
      desc: 'Akan ditampilkan di profil publik.',
      inputField: CustomTextField(
        controller: _usernameC,
        label: 'Username',
        hintText: 'Contoh: budihartono',
        prefixIcon: const Icon(
          Icons.alternate_email,
          color: AppColors.mutedGray,
        ),
        supportingText: 'Hanya huruf, angka, dan underscore',
        validator: (v) {
          if (v == null || v.trim().isEmpty) {
            return 'Username tidak boleh kosong';
          }
          if (RegExp(r'\s').hasMatch(v.trim())) {
            return 'Username tidak boleh mengandung spasi';
          }
          if (v.trim().length < 3) {
            return 'Username minimal 3 karakter';
          }
          return null;
        },
      ),
    ),
    _buildStepPage(
      stepIndex: 2,
      title: 'Masukkan alamat emailmu',
      desc: 'Untuk verifikasi akun dan notifikasi.',
      inputField: CustomTextField(
        controller: _emailC,
        label: 'Email',
        hintText: 'Contoh: nama@gmail.com',
        keyboardType: TextInputType.emailAddress,
        prefixIcon: const Icon(
          Icons.email_outlined,
          color: AppColors.mutedGray,
        ),
        supportingText: 'Pastikan email aktif',
        validator: (v) {
          if (v == null || v.trim().isEmpty) {
            return 'Email tidak boleh kosong';
          }
          if (!RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
            return 'Format email tidak valid';
          }
          return null;
        },
      ),
    ),
    _buildStepPage(
      stepIndex: 3,
      title: 'Buat kata sandi yang aman',
      desc: 'Minimal 8 karakter kombinasi huruf & angka.',
      inputField: CustomTextField(
        controller: _passwordController,
        label: 'Kata Sandi',
        hintText: '••••••••',
        obscureText: _obscurePassword,
        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.mutedGray),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.mutedGray,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        supportingText: 'Minimal 8 karakter kombinasi huruf & angka',
        validator: (v) {
          if (v == null || v.isEmpty) {
            return 'Kata sandi tidak boleh kosong';
          }
          if (v.length < 8) {
            return 'Minimal 8 karakter kombinasi huruf & angka';
          }
          return null;
        },
      ),
    ),
    _buildStepPage(
      stepIndex: 4,
      title: 'Konfirmasi kata sandi',
      desc: 'Masukkan kembali kata sandi yang sudah kamu buat sebelumnya.',
      inputField: CustomTextField(
        controller: _confirmPasswordController,
        label: 'Konfirmasi Kata Sandi',
        hintText: '••••••••',
        obscureText: _obscureConfirmPassword,
        textInputAction: TextInputAction.done,
        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.mutedGray),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.mutedGray,
          ),
          onPressed: () => setState(
            () => _obscureConfirmPassword = !_obscureConfirmPassword,
          ),
          // onPressed: () {
          //   context.push(DatabaseList());
          // },
        ),
        supportingText: 'Ulangi kata sandi yang sama',
        validator: (v) {
          if (v == null || v.isEmpty) {
            return 'Konfirmasi kata sandi tidak boleh kosong';
          }
          if (v != _passwordController.text) {
            return 'Konfirmasi kata sandi tidak cocok';
          }
          return null;
        },
      ),
    ),
  ];

  Widget _buildStepPage({
    required int stepIndex,
    required String title,
    required String desc,
    required Widget inputField,
  }) {
    return Form(
      key: _formKeys[stepIndex],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: AppTypography.displayLarge.copyWith(
                color: AppColors.inkSoft,
                fontSize: 36,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              style: AppTypography.bodyRegular.copyWith(
                color: AppColors.mutedGray,
              ),
            ),
            const SizedBox(height: 36),
            inputField,
          ],
        ),
      ),
    );
  }

  void _nextStep() {
    final formState = _formKeys[_currentStep].currentState;
    if (formState != null && !formState.validate()) return;

    if (_currentStep < _inputPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _handleRegister();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop();
    }
  }

  Future<void> _handleRegister() async {
    setState(() => _isLoading = true);

    final user = UserModel(
      displayName: _displayNameC.text.trim(),
      username: _usernameC.text.trim(),
      email: _emailC.text.trim(),
      password: _passwordController.text,
      createdAt: DateTime.now().toIso8601String(),
    );

    final result = await _authRepository.register(user);

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrasi berhasil! Silakan masuk.'),
            backgroundColor: AppColors.emerald,
          ),
        );
        context.pushReplacement(const LoginScreen());
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
          onPressed: _previousStep,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: (_currentStep + 1) / _inputPages.length,
                minHeight: 6,
                borderRadius: BorderRadius.circular(10),
                color: AppColors.forest,
                backgroundColor: AppColors.border,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) =>
                      setState(() => _currentStep = index),
                  children: _inputPages,
                ),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: _currentStep == _inputPages.length - 1
                    ? 'Daftar'
                    : 'Lanjut',
                height: 52,
                borderRadius: BorderRadius.circular(30),
                isLoading: _isLoading,
                onPressed: _nextStep,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
