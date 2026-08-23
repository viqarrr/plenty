import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/features/community/domain/models/community_post.dart';
import 'package:plenty/features/community/presentation/controllers/community_controller.dart';

/// Screen for creating and editing community posts (Pertanyaan & Tips).
/// Note: 'Pencapaian' category is locked and triggered exclusively via Badge Detail Modal.
class CreatePostScreen extends StatefulWidget {
  final CommunityController controller;
  final CommunityPost? initialPost;

  const CreatePostScreen({
    super.key,
    required this.controller,
    this.initialPost,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String _selectedCategory = 'pertanyaan'; // 'pertanyaan' or 'tips'
  String? _pickedImagePath;
  bool _isSubmitting = false;

  bool get _isEditing => widget.initialPost != null;

  @override
  void initState() {
    super.initState();
    if (widget.initialPost != null) {
      _contentController.text = widget.initialPost!.content;
      _selectedCategory = widget.initialPost!.category;
      _pickedImagePath = widget.initialPost!.imagePath;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _pickedImagePath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e')),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _pickedImagePath = null;
    });
  }

  Future<void> _submitPost() async {
    final text = _contentController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan tulis konten postingan Anda')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    if (_isEditing) {
      final updated = await widget.controller.editPost(
        postId: widget.initialPost!.id,
        category: _selectedCategory,
        content: text,
        imagePath: _pickedImagePath,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (updated != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Postingan berhasil diperbarui! ✨'),
            backgroundColor: AppColors.darkGreen,
          ),
        );
        context.pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.controller.errorMessage ?? 'Gagal memperbarui postingan',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } else {
      final created = await widget.controller.createPost(
        category: _selectedCategory,
        content: text,
        imagePath: _pickedImagePath,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (created != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Postingan berhasil dibagikan ke komunitas! 🌱'),
            backgroundColor: AppColors.darkGreen,
          ),
        );
        context.pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.controller.errorMessage ?? 'Gagal membagikan postingan',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.close_rounded,
            color: AppColors.inkDark,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isEditing ? 'Edit Postingan' : 'Buat Postingan',
          style: AppTypography.headline.copyWith(
            color: AppColors.inkDark,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forest,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Simpan' : 'Posting',
                          style: AppTypography.calloutBold.copyWith(
                            color: Colors.white,
                            fontSize: 13.5,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Category Selector (Pertanyaan vs Tips) ──
            Text(
              'PILIH KATEGORI',
              style: AppTypography.caption2Bold.copyWith(
                color: AppColors.muted,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _CategoryChoiceChip(
                    label: 'Pertanyaan',
                    icon: Icons.help_outline_rounded,
                    isSelected: _selectedCategory == 'pertanyaan',
                    selectedColor: AppColors.pastelBlueText,
                    selectedBgColor: AppColors.pastelBlueBg,
                    onTap: () => setState(() => _selectedCategory = 'pertanyaan'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CategoryChoiceChip(
                    label: 'Tips & Trick',
                    icon: Icons.lightbulb_outline_rounded,
                    isSelected: _selectedCategory == 'tips',
                    selectedColor: AppColors.pastelYellowText,
                    selectedBgColor: AppColors.pastelYellowBg,
                    onTap: () => setState(() => _selectedCategory = 'tips'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Informational Banner for Locked Pencapaian ──
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.pastelGreenBg.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.pastelGreenText.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.forest,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Kategori Pencapaian dibuat otomatis saat Anda membagikan lencana penghargaan dari halaman profil.',
                      style: AppTypography.caption1Regular.copyWith(
                        color: AppColors.darkGreen,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Textarea Input ──
            Text(
              'ISI POSTINGAN',
              style: AppTypography.caption2Bold.copyWith(
                color: AppColors.muted,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _contentController,
                maxLines: 6,
                minLines: 4,
                style: AppTypography.bodyRegular.copyWith(
                  color: AppColors.inkDark,
                ),
                decoration: InputDecoration(
                  hintText: _selectedCategory == 'pertanyaan'
                      ? 'Ada masalah atau pertanyaan tentang tanamanmu? Ceritakan detailnya di sini...'
                      : 'Bagikan pengalaman dan tips perawatan tanaman terbaikmu...',
                  hintStyle: AppTypography.bodyRegular.copyWith(
                    color: AppColors.mutedGray,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Image Attachment Box ──
            Text(
              'LAMPIRAN FOTO (OPSIONAL)',
              style: AppTypography.caption2Bold.copyWith(
                color: AppColors.muted,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            if (_pickedImagePath != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(_pickedImagePath!),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: _removeImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 110,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.border,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.forest,
                        size: 32,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pilih Foto dari Galeri',
                        style: AppTypography.caption1Bold.copyWith(
                          color: AppColors.forest,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChoiceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color selectedColor;
  final Color selectedBgColor;
  final VoidCallback onTap;

  const _CategoryChoiceChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.selectedColor,
    required this.selectedBgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? selectedBgColor : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? selectedColor.withValues(alpha: 0.5)
                : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? selectedColor : AppColors.muted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.caption1Bold.copyWith(
                color: isSelected ? selectedColor : AppColors.inkBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
