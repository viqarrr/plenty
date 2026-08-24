import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/di/injector.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/core/widgets/custom_button.dart';
import 'package:plenty/core/widgets/custom_text_field.dart';
import 'package:plenty/features/profile/domain/repositories/user_repository.dart';

/// Modal bottom sheet allowing users to change their account password.
///
/// Reuses [CustomTextField] and [CustomButton] with validation and visibility toggles.
class ChangePasswordSheet extends StatefulWidget {
  final IUserRepository? userRepository;
  final String? userId;

  const ChangePasswordSheet({
    super.key,
    this.userRepository,
    this.userId,
  });

  /// Opens the modal bottom sheet and returns `true` if password change was submitted.
  static Future<bool?> show(
    BuildContext context, {
    IUserRepository? userRepository,
    String? userId,
  }) {
    return context.showAppBottomSheet<bool>(
      ChangePasswordSheet(
        userRepository: userRepository,
        userId: userId,
      ),
    );
  }

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final IUserRepository _userRepo;
  bool _isLoading = false;
  String? _errorMessage;

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _userRepo = widget.userRepository ?? Injector.userRepository;
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final currentPass = _currentPasswordController.text;
    final newPass = _newPasswordController.text;

    final result = await _userRepo.updatePassword(
      userId: widget.userId,
      currentPassword: currentPass,
      newPassword: newPass,
    );

    if (!mounted) return;

    switch (result) {
      case Success():
        setState(() => _isLoading = false);
        if (Navigator.of(context).canPop()) {
          context.pop(true);
        }
      case Error(:final failure):
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ubah Kata Sandi',
                    style: AppTypography.title2Bold.copyWith(
                      fontSize: 18,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.muted),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.caption1Regular.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Current password
              CustomTextField(
                controller: _currentPasswordController,
                label: 'Kata Sandi Saat Ini',
                hintText: '••••••••',
                obscureText: _obscureCurrent,
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: AppColors.mutedGray,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrent
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.mutedGray,
                  ),
                  onPressed: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Kata sandi saat ini wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // New password
              CustomTextField(
                controller: _newPasswordController,
                label: 'Kata Sandi Baru',
                hintText: '••••••••',
                obscureText: _obscureNew,
                supportingText: 'Minimal 6 karakter',
                prefixIcon: const Icon(
                  Icons.key_outlined,
                  color: AppColors.mutedGray,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.mutedGray,
                  ),
                  onPressed: () =>
                      setState(() => _obscureNew = !_obscureNew),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Kata sandi baru wajib diisi';
                  }
                  if (val.length < 6) return 'Kata sandi minimal 6 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Confirm password
              CustomTextField(
                controller: _confirmPasswordController,
                label: 'Konfirmasi Kata Sandi Baru',
                hintText: '••••••••',
                obscureText: _obscureConfirm,
                prefixIcon: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.mutedGray,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.mutedGray,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Konfirmasi kata sandi wajib diisi';
                  }
                  if (val != _newPasswordController.text) {
                    return 'Konfirmasi kata sandi tidak cocok';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              CustomButton(
                text: 'Simpan Kata Sandi Baru',
                isLoading: _isLoading,
                height: 50,
                borderRadius: BorderRadius.circular(25),
                onPressed: _isLoading ? null : _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
