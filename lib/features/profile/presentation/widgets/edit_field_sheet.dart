import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/widgets/custom_button.dart';
import 'package:plenty/core/widgets/custom_text_field.dart';

/// Reusable modal bottom sheet for editing a profile text field.
///
/// Reuses standard [CustomTextField] and [CustomButton] components
/// with support for validation, character limits, multi-line, and prefix icons.
class EditFieldSheet extends StatefulWidget {
  final String title;
  final String? label;
  final String initialValue;
  final String? hintText;
  final Widget? prefixIcon;
  final int maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;

  const EditFieldSheet({
    super.key,
    required this.title,
    required this.initialValue,
    this.label,
    this.hintText,
    this.prefixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
  });

  /// Opens the modal bottom sheet and returns the edited string,
  /// or `null` if canceled.
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String initialValue,
    String? label,
    String? hintText,
    Widget? prefixIcon,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditFieldSheet(
        title: title,
        label: label,
        initialValue: initialValue,
        hintText: hintText,
        prefixIcon: prefixIcon,
        maxLines: maxLines,
        maxLength: maxLength,
        validator: validator,
      ),
    );
  }

  @override
  State<EditFieldSheet> createState() => _EditFieldSheetState();
}

class _EditFieldSheetState extends State<EditFieldSheet> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final trimmed = _controller.text.trim();
    if (trimmed.isNotEmpty) {
      Navigator.of(context).pop(trimmed);
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

              // Title
              Text(
                widget.title,
                style: AppTypography.title2Bold.copyWith(
                  fontSize: 18,
                  color: AppColors.inkSoft,
                ),
              ),

              const SizedBox(height: 16),

              // Reused CustomTextField
              CustomTextField(
                controller: _controller,
                label: widget.label,
                hintText: widget.hintText,
                prefixIcon: widget.prefixIcon,
                maxLines: widget.maxLines,
                validator: widget.validator,
              ),
              const SizedBox(height: 24),

              // Reused CustomButton
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Batal',
                      isOutlined: true,
                      height: 48,
                      borderRadius: BorderRadius.circular(24),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Simpan',
                      height: 48,
                      borderRadius: BorderRadius.circular(24),
                      onPressed: _handleSave,
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
