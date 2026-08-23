import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/features/community/domain/models/community_post.dart';
import 'package:plenty/features/community/presentation/controllers/community_controller.dart';
import 'package:plenty/features/community/presentation/screens/create_post_screen.dart';
import 'package:plenty/features/community/presentation/widgets/community_post_card.dart';

/// Main Community Feed Screen with Category Filtering, Header Bar, and Post Creation.
class CommunityScreen extends StatefulWidget {
  final CommunityController? controller;
  final String? initialCategory;

  const CommunityScreen({
    super.key,
    this.controller,
    this.initialCategory,
  });

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late final CommunityController _controller;
  bool _ownsController = false;

  final List<_CategoryFilterItem> _categoryFilters = const [
    _CategoryFilterItem(id: 'all', label: 'Semua'),
    _CategoryFilterItem(
      id: 'pertanyaan',
      label: 'Pertanyaan',
      activeColor: AppColors.pastelBlueText,
      activeBg: AppColors.pastelBlueBg,
    ),
    _CategoryFilterItem(
      id: 'pencapaian',
      label: 'Pencapaian',
      activeColor: AppColors.pastelGreenText,
      activeBg: AppColors.pastelGreenBg,
    ),
    _CategoryFilterItem(
      id: 'tips',
      label: 'Tips & Trick',
      activeColor: AppColors.pastelYellowText,
      activeBg: AppColors.pastelYellowBg,
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = CommunityController();
      _ownsController = true;
    }
    _controller.addListener(_onControllerUpdate);

    final startCategory = widget.initialCategory ?? _controller.selectedCategory;
    _controller.loadPosts(category: startCategory);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _handleRefresh() async {
    await _controller.loadPosts();
  }

  void _openCreatePost() {
    context.push(CreatePostScreen(controller: _controller));
  }

  void _handleEditPost(CommunityPost post) {
    context.push(CreatePostScreen(controller: _controller, initialPost: post));
  }

  void _handleDeletePost(CommunityPost post) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Hapus Postingan?',
          style: AppTypography.headlineSemiBold.copyWith(
            color: AppColors.inkDark,
          ),
        ),
        content: Text(
          'Postingan ini akan dihapus secara permanen dari komunitas.',
          style: AppTypography.bodyRegular.copyWith(
            color: AppColors.inkBody,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Batal',
              style: AppTypography.calloutRegular.copyWith(
                color: AppColors.muted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final success = await _controller.deletePost(post.id);
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Postingan berhasil dihapus'),
                      backgroundColor: AppColors.darkGreen,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _controller.errorMessage ?? 'Gagal menghapus postingan',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreatePost,
        backgroundColor: AppColors.forest,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppColors.forest,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Header Bar ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Komunitas',
                        style: AppTypography.largeTitleBold.copyWith(
                          fontSize: 28,
                          color: AppColors.inkDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Temukan & Berbagi Tips Tanaman',
                        style: AppTypography.caption1Regular.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Filter Pills (Horizontal Bar) ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _categoryFilters.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final filter = _categoryFilters[index];
                        final isSelected = _controller.selectedCategory == filter.id;

                        Color bg = isSelected
                            ? (filter.activeBg ?? AppColors.forest)
                            : AppColors.surface;
                        Color text = isSelected
                            ? (filter.activeColor ?? Colors.white)
                            : AppColors.inkBody;

                        if (filter.id == 'all' && isSelected) {
                          bg = AppColors.forest;
                          text = Colors.white;
                        }

                        return GestureDetector(
                          onTap: () => _controller.setCategory(filter.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? (filter.activeColor ?? AppColors.forest)
                                        .withValues(alpha: 0.3)
                                    : AppColors.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                filter.label,
                                style: AppTypography.caption1Bold.copyWith(
                                  color: text,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // ── Post List or Empty / Loading State ──
              if (_controller.isLoading && _controller.posts.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.forest),
                  ),
                )
              else if (_controller.posts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: AppColors.pastelGreenBg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.forum_outlined,
                              size: 40,
                              color: AppColors.forest,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum Ada Diskusi',
                            style: AppTypography.title2Bold.copyWith(
                              color: AppColors.inkDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Jadilah yang pertama membuat postingan di kategori ini!',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyRegular.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _openCreatePost,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Buat Postingan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.forest,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = _controller.posts[index];
                        return CommunityPostCard(
                          post: post,
                          onLikeTap: () => _controller.toggleLike(post.id),
                          onEditTap: () => _handleEditPost(post),
                          onDeleteTap: () => _handleDeletePost(post),
                          onCommentTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Komentar postingan segera dibuka!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        );
                      },
                      childCount: _controller.posts.length,
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

class _CategoryFilterItem {
  final String id;
  final String label;
  final Color? activeColor;
  final Color? activeBg;

  const _CategoryFilterItem({
    required this.id,
    required this.label,
    this.activeColor,
    this.activeBg,
  });
}
