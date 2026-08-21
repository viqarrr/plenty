import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/widgets/custom_button.dart';
import 'package:plenty/core/widgets/custom_text_field.dart';

/// Modal bottom sheet allowing users to change their account password.
///
/// Reuses [CustomTextField] and [CustomButton] with validation and visibility toggles.
class ChangePasswordSheet extends StatefulWidget {
  const ChangePasswordSheet({super.key});

  /// Opens the modal bottom sheet and returns `true` if password change was submitted.
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ChangePasswordSheet(),
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

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(true);
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
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Current password
              CustomTextField(
                controller: _currentPasswordController,
                label: 'Kata Sandi Saat Ini',
                hintText: '••••••••',
                obscureText: _obscureCurrent,
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.mutedGray),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrent
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.mutedGray,
                  ),
                  onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Kata sandi saat ini wajib diisi';
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
                supportingText: 'Minimal 8 karakter kombinasi huruf & angka',
                prefixIcon: const Icon(Icons.key_outlined, color: AppColors.mutedGray),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.mutedGray,
                  ),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Kata sandi baru wajib diisi';
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
                prefixIcon: const Icon(Icons.check_circle_outline, color: AppColors.mutedGray),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.mutedGray,
                  ),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Konfirmasi kata sandi wajib diisi';
                  if (val != _newPasswordController.text) return 'Konfirmasi kata sandi tidak cocok';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              CustomButton(
                text: 'Simpan Kata Sandi Baru',
                height: 50,
                borderRadius: BorderRadius.circular(25),
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
