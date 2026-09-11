import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/di/injector.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/core/widgets/custom_button.dart';
import 'package:plenty/core/widgets/custom_text_field.dart';
import 'package:plenty/features/garden/domain/models/site_model.dart';
import 'package:plenty/features/garden/domain/repositories/site_repository.dart';
import 'package:plenty/features/garden/presentation/extensions/site_extension.dart';

/// Representation of a room or area site option.
class SiteOption {
  final String id;
  final String name;
  final IconData icon;
  final bool isCustom;
  final bool isIndoor;

  const SiteOption({
    required this.id,
    required this.name,
    required this.icon,
    this.isCustom = false,
    this.isIndoor = true,
  });

  SiteOption copyWith({
    String? id,
    String? name,
    IconData? icon,
    bool? isCustom,
    bool? isIndoor,
  }) {
    return SiteOption(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isCustom: isCustom ?? this.isCustom,
      isIndoor: isIndoor ?? this.isIndoor,
    );
  }
}

/// Step 3: Room / Zone selection with interactive 2-column grid & custom site SQLite CRUD.
class WizardAreaStep extends StatefulWidget {
  final String selectedRoom;
  final ValueChanged<String> onRoomSelected;
  final bool isIndoor;
  final ISiteRepository? siteRepo;

  const WizardAreaStep({
    super.key,
    required this.selectedRoom,
    required this.onRoomSelected,
    this.isIndoor = true,
    this.siteRepo,
  });

  @override
  State<WizardAreaStep> createState() => _WizardAreaStepState();
}

class _WizardAreaStepState extends State<WizardAreaStep>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const List<IconData> _availableIcons = [
    Icons.weekend_outlined,
    Icons.bed_outlined,
    Icons.soup_kitchen_outlined,
    Icons.computer_outlined,
    Icons.table_restaurant_outlined,
    Icons.chair_outlined,
    Icons.bathtub_outlined,
    Icons.meeting_room_outlined,
    Icons.balcony_outlined,
    Icons.yard_outlined,
    Icons.deck_outlined,
    Icons.fence_outlined,
    Icons.window_outlined,
    Icons.roofing_outlined,
    Icons.park_outlined,
    Icons.local_florist_outlined,
  ];

  late final ISiteRepository _siteRepo;
  late List<SiteOption> _indoorSites;
  late List<SiteOption> _outdoorSites;

  @override
  void initState() {
    super.initState();
    _siteRepo = widget.siteRepo ?? Injector.siteRepository;

    _indoorSites = [
      const SiteOption(
        id: 'site_default_ruang_tamu',
        name: 'Ruang Tamu',
        icon: Icons.weekend_outlined,
        isIndoor: true,
      ),
      const SiteOption(
        id: 'site_default_kamar_tidur',
        name: 'Kamar Tidur',
        icon: Icons.bed_outlined,
        isIndoor: true,
      ),
      const SiteOption(
        id: 'site_default_dapur',
        name: 'Dapur',
        icon: Icons.soup_kitchen_outlined,
        isIndoor: true,
      ),
    ];

    _outdoorSites = [
      const SiteOption(
        id: 'site_default_balkon',
        name: 'Balkon',
        icon: Icons.balcony_outlined,
        isIndoor: false,
      ),
      const SiteOption(
        id: 'site_default_teras',
        name: 'Teras',
        icon: Icons.roofing_outlined,
        isIndoor: false,
      ),
    ];

    _loadSavedSites();
  }

  Future<void> _loadSavedSites() async {
    try {
      final sitesResult = await _siteRepo.getSites();
      final sites = sitesResult.dataOrNull ?? [];
      if (!mounted) return;

      setState(() {
        final indoor = sites
            .where((s) => s.isIndoor)
            .map((s) => SiteOption(
                  id: s.id,
                  name: s.name,
                  icon: s.iconData,
                  isCustom: s.isCustom,
                  isIndoor: s.isIndoor,
                ))
            .toList();

        final outdoor = sites
            .where((s) => !s.isIndoor)
            .map((s) => SiteOption(
                  id: s.id,
                  name: s.name,
                  icon: s.iconData,
                  isCustom: s.isCustom,
                  isIndoor: s.isIndoor,
                ))
            .toList();

        // Preserve any custom sites already present in memory
        for (final local in _indoorSites.where((s) => s.isCustom)) {
          if (!indoor.any((s) => s.id == local.id || s.name == local.name)) {
            indoor.add(local);
          }
        }
        for (final local in _outdoorSites.where((s) => s.isCustom)) {
          if (!outdoor.any((s) => s.id == local.id || s.name == local.name)) {
            outdoor.add(local);
          }
        }

        if (indoor.isNotEmpty) _indoorSites = indoor;
        if (outdoor.isNotEmpty) _outdoorSites = outdoor;
      });
    } catch (_) {}
  }

  void _openAddCustomSiteSheet({required bool isIndoor}) {
    final nameController = TextEditingController();
    IconData selectedIcon =
        isIndoor ? Icons.meeting_room_outlined : Icons.park_outlined;

    context.showAppBottomSheet(
      StatefulBuilder(
        builder: (sheetContext, setModalState) {
          final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              decoration: const BoxDecoration(
                color: AppColors.canvasDefault,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                    Text(
                      isIndoor
                          ? 'Tambah Lokasi Indoor Kustom'
                          : 'Tambah Lokasi Outdoor Kustom',
                      style: AppTypography.title2Bold.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Beri nama dan tentukan ikon untuk lokasi baru Anda.',
                      style: AppTypography.footnoteRegular.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: nameController,
                      label: 'Nama Lokasi',
                      hintText: isIndoor
                          ? 'Contoh: Kamar Mandi, Ruang Keluarga...'
                          : 'Contoh: Rooftop, Halaman Belakang...',
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Pilih Ikon Lokasi',
                      style: AppTypography.calloutBold.copyWith(
                        color: AppColors.inkSoft,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _availableIcons.map((icon) {
                        final isIconSelected = selectedIcon == icon;
                        return InkWell(
                          onTap: () {
                            setModalState(() => selectedIcon = icon);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isIconSelected
                                  ? AppColors.forest
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isIconSelected
                                    ? AppColors.forest
                                    : AppColors.border,
                              ),
                            ),
                            child: Icon(
                              icon,
                              size: 22,
                              color: isIconSelected
                                  ? Colors.white
                                  : AppColors.muted,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Simpan Lokasi',
                      height: 50,
                      borderRadius: BorderRadius.circular(25),
                      onPressed: () async {
                        final trimmed = nameController.text.trim();
                        if (trimmed.isEmpty) return;

                        final customId =
                            'custom_${DateTime.now().millisecondsSinceEpoch}';
                        final newSite = SiteOption(
                          id: customId,
                          name: trimmed,
                          icon: selectedIcon,
                          isCustom: true,
                          isIndoor: isIndoor,
                        );

                        final dbModel = SiteModel(
                          id: customId,
                          name: trimmed,
                          iconCode: selectedIcon.codePoint,
                          isIndoor: isIndoor,
                          isCustom: true,
                          createdAt: DateTime.now(),
                        );

                        await _siteRepo.addCustomSite(dbModel);

                        setState(() {
                          if (isIndoor) {
                            if (!_indoorSites.any((s) => s.id == newSite.id || s.name == newSite.name)) {
                              _indoorSites.add(newSite);
                            }
                          } else {
                            if (!_outdoorSites.any((s) => s.id == newSite.id || s.name == newSite.name)) {
                              _outdoorSites.add(newSite);
                            }
                          }
                        });

                        widget.onRoomSelected(trimmed);
                        if (sheetContext.mounted) {
                          sheetContext.pop();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCustomSiteOptions(SiteOption site) {
    context.showAppBottomSheet(
      Builder(
        builder: (sheetContext) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            decoration: const BoxDecoration(
              color: AppColors.canvasDefault,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                Text(
                  'Kelola Lokasi: ${site.name}',
                  style: AppTypography.title2Bold.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.pastelGreenBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.forest,
                      size: 20,
                    ),
                  ),
                  title: const Text('Ubah Nama & Ikon'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    sheetContext.pop();
                    _openEditCustomSiteSheet(site);
                  },
                ),
                const SizedBox(height: 6),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.pastelRedBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: AppColors.pastelRedText,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Hapus Lokasi',
                    style: TextStyle(color: AppColors.pastelRedText),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    sheetContext.pop();
                    _confirmDeleteCustomSite(site);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openEditCustomSiteSheet(SiteOption site) {
    final nameController = TextEditingController(text: site.name);
    IconData selectedIcon = site.icon;

    context.showAppBottomSheet(
      StatefulBuilder(
        builder: (sheetContext, setModalState) {
          final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              decoration: const BoxDecoration(
                color: AppColors.canvasDefault,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                    Text(
                      'Ubah Lokasi Kustom',
                      style: AppTypography.title2Bold.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: nameController,
                      label: 'Nama Lokasi',
                      hintText: 'Nama lokasi...',
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Pilih Ikon Lokasi',
                      style: AppTypography.calloutBold.copyWith(
                        color: AppColors.inkSoft,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _availableIcons.map((icon) {
                        final isIconSelected = selectedIcon == icon;
                        return InkWell(
                          onTap: () {
                            setModalState(() => selectedIcon = icon);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isIconSelected
                                  ? AppColors.forest
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isIconSelected
                                    ? AppColors.forest
                                    : AppColors.border,
                              ),
                            ),
                            child: Icon(
                              icon,
                              size: 22,
                              color: isIconSelected
                                  ? Colors.white
                                  : AppColors.muted,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Simpan Perubahan',
                      height: 50,
                      borderRadius: BorderRadius.circular(25),
                      onPressed: () async {
                        final trimmed = nameController.text.trim();
                        if (trimmed.isEmpty) return;

                        final updated = site.copyWith(
                          name: trimmed,
                          icon: selectedIcon,
                        );

                        final dbModel = SiteModel(
                          id: site.id,
                          name: trimmed,
                          iconCode: selectedIcon.codePoint,
                          isIndoor: site.isIndoor,
                          isCustom: true,
                          createdAt: DateTime.now(),
                        );

                        await _siteRepo.updateCustomSite(dbModel);

                        setState(() {
                          if (site.isIndoor) {
                            final idx = _indoorSites
                                .indexWhere((s) => s.id == site.id);
                            if (idx != -1) _indoorSites[idx] = updated;
                          } else {
                            final idx = _outdoorSites
                                .indexWhere((s) => s.id == site.id);
                            if (idx != -1) _outdoorSites[idx] = updated;
                          }
                        });

                        if (widget.selectedRoom == site.name) {
                          widget.onRoomSelected(trimmed);
                        }

                        if (sheetContext.mounted) {
                          sheetContext.pop();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteCustomSite(SiteOption site) {
    context.showAppDialog(
      Builder(
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Hapus Lokasi?',
              style: AppTypography.title2Bold.copyWith(fontSize: 18),
            ),
            content: Text(
              'Lokasi "${site.name}" akan dihapus dari daftar pilihan.',
              style: AppTypography.bodyRegular.copyWith(
                color: AppColors.muted,
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => dialogContext.pop(),
                child: Text(
                  'Batal',
                  style: AppTypography.calloutBold.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _siteRepo.deleteCustomSite(site.id);

                  setState(() {
                    if (site.isIndoor) {
                      _indoorSites.removeWhere((s) => s.id == site.id);
                    } else {
                      _outdoorSites.removeWhere((s) => s.id == site.id);
                    }
                  });

                  if (widget.selectedRoom == site.name) {
                    final relevantSites =
                        widget.isIndoor ? _indoorSites : _outdoorSites;
                    final fallback = relevantSites.isNotEmpty
                        ? relevantSites.first.name
                        : (widget.isIndoor ? 'Ruang Tamu' : 'Balkon');
                    widget.onRoomSelected(fallback);
                  }

                  if (dialogContext.mounted) {
                    dialogContext.pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pastelRedBg,
                  foregroundColor: AppColors.pastelRedText,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Hapus'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void didUpdateWidget(covariant WizardAreaStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadSavedSites();
    if (oldWidget.isIndoor != widget.isIndoor) {
      final relevantSites = widget.isIndoor ? _indoorSites : _outdoorSites;
      if (relevantSites.isNotEmpty &&
          !relevantSites.any((s) => s.name == widget.selectedRoom)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onRoomSelected(relevantSites.first.name);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isIndoor = widget.isIndoor;
    final relevantSites = isIndoor ? _indoorSites : _outdoorSites;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isIndoor ? 'Lokasi Ruangan' : 'Lokasi Area Outdoor',
            style: AppTypography.displayLarge.copyWith(
              fontSize: 32,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isIndoor
                ? 'Pilih ruangan atau zona indoor tempat tanaman ini akan diletakkan.'
                : 'Pilih area outdoor tempat tanaman ini akan diletakkan.',
            style: AppTypography.bodyRegular.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 24),

          // Environment-specific Section
          _buildSectionHeader(
            title: isIndoor ? 'Lokasi Indoor' : 'Lokasi Outdoor',
            onAddCustom: () => _openAddCustomSiteSheet(isIndoor: isIndoor),
          ),
          const SizedBox(height: 12),
          _buildSitesGrid(relevantSites),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required VoidCallback onAddCustom,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTypography.title2Bold.copyWith(
            color: AppColors.forest,
            fontSize: 16,
          ),
        ),
        InkWell(
          onTap: onAddCustom,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.pastelGreenBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.forest.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add,
                  color: AppColors.forest,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'Custom',
                  style: AppTypography.caption1Bold.copyWith(
                    color: AppColors.forest,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSitesGrid(List<SiteOption> sites) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sites.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemBuilder: (context, index) {
        final site = sites[index];
        final isSelected = widget.selectedRoom == site.name;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onRoomSelected(site.name),
            onLongPress:
                site.isCustom ? () => _showCustomSiteOptions(site) : null,
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.forest
                      : const Color(0xFFE5E5EA),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.pastelGreenBg
                          : AppColors.canvasDefault,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      site.icon,
                      color: isSelected
                          ? AppColors.forest
                          : const Color(0xFF8E8E93),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      site.name,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.forest
                            : const Color(0xFF6B7280),
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (site.isCustom)
                    GestureDetector(
                      onTap: () => _showCustomSiteOptions(site),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Icon(
                          Icons.more_vert,
                          size: 16,
                          color: isSelected
                              ? AppColors.forest
                              : const Color(0xFF8E8E93),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
