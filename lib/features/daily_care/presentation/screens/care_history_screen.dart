import 'dart:io';

import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/daily_care/domain/models/care_history_item.dart';
import 'package:plenty/features/daily_care/data/care_repository.dart';

/// Care Action History screen matching Plenty design language.
class CareHistoryScreen extends StatefulWidget {
  final CareRepository? careRepo;

  const CareHistoryScreen({super.key, this.careRepo});

  @override
  State<CareHistoryScreen> createState() => _CareHistoryScreenState();
}

class _CareHistoryScreenState extends State<CareHistoryScreen> {
  late final CareRepository _careRepo;
  List<CareHistoryItem> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _careRepo = widget.careRepo ?? CareRepository();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await PreferenceHandler.getUser();
      final userId =
          (user?.id != null && user!.id! > 0) ? user.id.toString() : '1';
      final results = await _careRepo.getCareHistory(userId: userId);
      if (!mounted) return;
      setState(() {
        _items = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final diffDays = today.difference(target).inDays;
    if (diffDays == 0) return 'Hari Ini';
    if (diffDays == 1) return 'Kemarin';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  IconData _getTaskIcon(String taskType) {
    switch (taskType) {
      case 'monitor_tinggi':
        return Icons.straighten;
      case 'siram':
        return Icons.water_drop_outlined;
      case 'bersih_bersih':
        return Icons.cleaning_services_outlined;
      default:
        return Icons.task_alt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasDefault,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.forest,
            size: 20,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          'Riwayat Perawatan',
          style: AppTypography.title2Bold.copyWith(
            color: AppColors.inkSoft,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.forest),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Gagal memuat riwayat: $_errorMessage',
                      style: AppTypography.bodyRegular.copyWith(
                        color: AppColors.muted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.history_outlined,
                            size: 48,
                            color: AppColors.muted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada riwayat perawatan.',
                            style: AppTypography.calloutBold.copyWith(
                              color: AppColors.inkSoft,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Selesaikan rutinitas harian untuk mencatat lini masa perawatan tanamanmu.',
                            style: AppTypography.caption1Regular.copyWith(
                              color: AppColors.muted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : _buildHistoryList(),
    );
  }

  Widget _buildHistoryList() {
    final grouped = <String, List<CareHistoryItem>>{};
    for (final item in _items) {
      final header = _formatDateHeader(item.completedAt);
      grouped.putIfAbsent(header, () => []).add(item);
    }

    return ListView.builder(
      itemCount: grouped.keys.length,
      itemBuilder: (context, index) {
        final header = grouped.keys.elementAt(index);
        final groupItems = grouped[header]!;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: 18,
                  bottom: 8,
                  left: 4,
                ),
                child: Text(
                  header,
                  style: AppTypography.caption1Bold.copyWith(
                    color: AppColors.inkSoft,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: groupItems.length,
                  separatorBuilder: (_, _) => const Divider(
                    color: AppColors.border,
                    height: 1,
                    indent: 56,
                  ),
                  itemBuilder: (context, itemIdx) {
                    final item = groupItems[itemIdx];
                    return _buildHistoryTile(item);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThumbnail(String path) {
    Widget image;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      image = Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.local_florist, color: AppColors.forest, size: 18),
      );
    } else if (path.startsWith('assets/')) {
      image = Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.local_florist, color: AppColors.forest, size: 18),
      );
    } else {
      image = Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.local_florist, color: AppColors.forest, size: 18),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(width: 40, height: 40, child: image),
    );
  }

  Widget _buildHistoryTile(CareHistoryItem item) {
    final hasPhoto = item.photoPath != null && item.photoPath!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          if (hasPhoto)
            _buildThumbnail(item.photoPath!)
          else
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.pastelGreenBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getTaskIcon(item.taskType),
                color: AppColors.forest,
                size: 20,
              ),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.plantNickname,
                  style: AppTypography.calloutBold.copyWith(
                    color: AppColors.inkSoft,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.activityDetail,
                  style: AppTypography.caption1Regular.copyWith(
                    color: AppColors.muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.pastelGreenBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.forest.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  '+${item.xpAwarded} XP',
                  style: AppTypography.caption2Bold.copyWith(
                    color: AppColors.forest,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(item.completedAt),
                style: AppTypography.caption1Regular.copyWith(
                  color: AppColors.muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
