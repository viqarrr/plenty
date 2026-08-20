import 'dart:io';
import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/image_picker_helper.dart';
import 'package:plenty/data/repositories/user_repository.dart';
import 'package:plenty/presentation/profile/widgets/change_password_sheet.dart';
import 'package:plenty/presentation/profile/widgets/edit_field_sheet.dart';
import 'package:plenty/presentation/profile/widgets/settings_item_tile.dart';
import 'package:plenty/presentation/profile/widgets/settings_section.dart';
import 'package:plenty/presentation/profile/widgets/theme_selector_sheet.dart';

/// iOS-style profile edit & settings screen.
///
/// Persists profile changes (avatar, name, username, bio) to SQLite database
/// via [UserRepository] and active session.
class ProfileEditScreen extends StatefulWidget {
  /// Called when the user confirms logout via the confirmation dialog.
  final VoidCallback onLogout;

  final String initialDisplayName;
  final String initialUsername;
  final String initialBio;
  final String? initialAvatarPath;

  const ProfileEditScreen({
    super.key,
    required this.onLogout,
    this.initialDisplayName = 'Alex Gardner',
    this.initialUsername = 'alex_plants',
    this.initialBio = 'Urban gardener berlokasi di Jakarta...',
    this.initialAvatarPath,
  });

  static const _chevron = Icon(
    Icons.chevron_right,
    size: 20,
    color: AppColors.muted,
  );
  static const _lock = Icon(
    Icons.lock_outlined,
    size: 18,
    color: AppColors.muted,
  );

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _userRepo = UserRepository();
  late String _displayName;
  late String _username;
  late String _bio;
  String? _avatarPath;
  String _themeMode = 'Mode Terang';

  @override
  void initState() {
    super.initState();
    _displayName = widget.initialDisplayName;
    _username = widget.initialUsername;
    _bio = widget.initialBio;
    _avatarPath = widget.initialAvatarPath;
  }

  // ── Handlers ──────────────────────────────────────────────

  void _pickAvatar() {
    ImagePickerHelper.showPickerSheet(
      context: context,
      showRemoveOption: _avatarPath != null && _avatarPath!.isNotEmpty,
      onImageSelected: (path) async {
        setState(() => _avatarPath = path);
        await _userRepo.updateUserProfile(avatarUrl: path ?? '');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              path != null
                  ? 'Foto profil berhasil diperbarui.'
                  : 'Foto profil default digunakan.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  Future<void> _editDisplayName() async {
    final result = await EditFieldSheet.show(
      context,
      title: 'Ubah Nama',
      initialValue: _displayName,
      hintText: 'e.g. Alex Gardner',
      prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.forest),
      validator: (val) {
        if (val == null || val.trim().isEmpty) return 'Nama tampilan wajib diisi';
        return null;
      },
    );
    if (result != null && mounted) {
      setState(() => _displayName = result);
      await _userRepo.updateUserProfile(displayName: result);
    }
  }

  Future<void> _editUsername() async {
    final result = await EditFieldSheet.show(
      context,
      title: 'Ubah Username',
      initialValue: _username,
      hintText: 'e.g. alex_plants',
      prefixIcon: const Icon(Icons.alternate_email, color: AppColors.forest),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Nama pengguna wajib diisi';
        final clean = value.startsWith('@') ? value.substring(1) : value;
        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(clean)) {
          return 'Hanya huruf, angka, dan underscore';
        }
        return null;
      },
    );
    if (result != null && mounted) {
      final clean = result.startsWith('@') ? result.substring(1) : result;
      setState(() => _username = clean);
      await _userRepo.updateUserProfile(username: clean);
    }
  }

  Future<void> _editBio() async {
    final result = await EditFieldSheet.show(
      context,
      title: 'Ubah Teks Tentang (Bio)',
      initialValue: _bio,
      hintText: 'Ceritakan hobi berkebun Anda...',
      prefixIcon: const Icon(Icons.notes_outlined, color: AppColors.forest),
      maxLines: 3,
      maxLength: 150,
    );
    if (result != null && mounted) {
      setState(() => _bio = result);
      await _userRepo.updateUserProfile(bio: result);
    }
  }

  void _showEmailReadOnly() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alamat email terverifikasi dan tidak dapat diubah.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _editPassword() async {
    final changed = await ChangePasswordSheet.show(context);
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kata sandi berhasil diperbarui.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _selectTheme() async {
    final chosen = await ThemeSelectorSheet.show(
      context,
      currentTheme: _themeMode,
    );
    if (chosen != null && mounted) {
      setState(() => _themeMode = chosen);
    }
  }

  void _showLogoutConfirmation() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar dari Akun?'),
        content: const Text(
          'Anda harus masuk kembali untuk mengakses data Anda.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: AppTypography.calloutRegular.copyWith(
                color: AppColors.muted,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onLogout();
            },
            child: Text(
              'Keluar',
              style: AppTypography.calloutBold.copyWith(
                color: AppColors.pastelRedText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.searchBarSurface,
      appBar: AppBar(
        backgroundColor: AppColors.searchBarSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.inkSoft),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profil',
          style: AppTypography.displayLarge.copyWith(fontSize: 22),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            _AvatarEditSection(
              avatarPath: _avatarPath,
              onEditTap: _pickAvatar,
            ),
            const SizedBox(height: 28),

            // ── Informasi Akun ──
            SettingsSection(
              title: 'Informasi Akun',
              children: [
                SettingsItemTile(
                  icon: Icons.badge_outlined,
                  label: 'Nama tampilan',
                  value: _displayName,
                  trailing: ProfileEditScreen._chevron,
                  onTap: _editDisplayName,
                ),
                SettingsItemTile(
                  icon: Icons.alternate_email,
                  label: 'Nama pengguna',
                  value: '@$_username',
                  trailing: ProfileEditScreen._chevron,
                  onTap: _editUsername,
                ),
                SettingsItemTile(
                  icon: Icons.notes_outlined,
                  label: 'Teks tentang',
                  value: _bio,
                  trailing: ProfileEditScreen._chevron,
                  onTap: _editBio,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Keamanan ──
            SettingsSection(
              title: 'Keamanan',
              children: [
                SettingsItemTile(
                  icon: Icons.email_outlined,
                  label: 'Alamat email',
                  value: 'alex@gardner.com',
                  trailing: ProfileEditScreen._lock,
                  onTap: _showEmailReadOnly,
                ),
                SettingsItemTile(
                  icon: Icons.key_outlined,
                  label: 'Kata sandi',
                  value: '••••••••••••',
                  trailing: ProfileEditScreen._chevron,
                  onTap: _editPassword,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Pengaturan sistem ──
            SettingsSection(
              title: 'Pengaturan sistem',
              children: [
                SettingsItemTile(
                  icon: Icons.contrast,
                  label: 'Tema aplikasi',
                  onTap: _selectTheme,
                  trailing: Text(
                    _themeMode,
                    style: AppTypography.subheadlineRegular.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Aksi Akun (Logout) ──
            SettingsSection(
              children: [
                SettingsItemTile(
                  icon: Icons.logout_rounded,
                  label: 'Keluar dari Akun',
                  isDestructive: true,
                  onTap: _showLogoutConfirmation,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Circular avatar with a floating edit pencil button and image preview support.
class _AvatarEditSection extends StatelessWidget {
  final String? avatarPath;
  final VoidCallback? onEditTap;

  const _AvatarEditSection({
    this.avatarPath,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final photo = avatarPath;
    final hasPhoto = photo != null && photo.isNotEmpty;

    return Center(
      child: GestureDetector(
        onTap: onEditTap,
        child: SizedBox(
          width: 90,
          height: 90,
          child: Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.forest.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: hasPhoto
                      ? (photo.startsWith('http://') || photo.startsWith('https://'))
                          ? Image.network(
                              photo,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.person,
                                size: 48,
                                color: AppColors.forest,
                              ),
                            )
                          : photo.startsWith('assets/')
                              ? Image.asset(
                                  photo,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.person,
                                    size: 48,
                                    color: AppColors.forest,
                                  ),
                                )
                              : Image.file(
                                  File(photo),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.person,
                                    size: 48,
                                    color: AppColors.forest,
                                  ),
                                )
                      : const Icon(
                          Icons.person,
                          size: 48,
                          color: AppColors.forest,
                        ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.forest,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 14,
                    color: AppColors.surface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
