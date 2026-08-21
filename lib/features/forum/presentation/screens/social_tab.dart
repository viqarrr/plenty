import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/widgets/custom_button.dart';
import 'package:plenty/core/widgets/custom_text_field.dart';
import 'package:plenty/features/forum/domain/models/community_post_model.dart';
import 'package:plenty/features/forum/data/repositories/forum_repository.dart';
import 'package:plenty/features/forum/presentation/widgets/social_post_card.dart';

class SocialTab extends StatefulWidget {
  final ForumRepository? forumRepo;

  const SocialTab({super.key, this.forumRepo});

  @override
  State<SocialTab> createState() => _SocialTabState();
}

class _SocialTabState extends State<SocialTab> {
  late final ForumRepository _repo;
  String _selectedCategory = 'Semua';
  List<CommunityPostModel> _posts = [];
  bool _isLoading = true;

  static const List<String> _categories = [
    'Semua',
    'Pamer Tanaman',
    'Tanya Jawab',
    'Tips & Trik',
  ];

  @override
  void initState() {
    super.initState();
    _repo = widget.forumRepo ?? ForumRepository();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    final results = await _repo.getPosts(
      category: _selectedCategory == 'Semua' ? null : _selectedCategory,
    );
    if (!mounted) return;
    setState(() {
      _posts = results;
      _isLoading = false;
    });
  }

  Future<void> _handleKudos(CommunityPostModel post) async {
    final newCount = await _repo.toggleKudos(post.id);
    if (!mounted) return;
    setState(() {
      _posts = _posts.map((p) {
        if (p.id == post.id) {
          return p.copyWith(
            kudosCount: newCount,
            isLikedByMe: !p.isLikedByMe,
          );
        }
        return p;
      }).toList();
    });
  }

  void _showCreatePostDialog() {
    final captionController = TextEditingController();
    String category = 'Pamer Tanaman';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: AppColors.canvasDefault,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Buat Postingan Baru', style: AppTypography.title2Bold),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _categories
                        .where((c) => c != 'Semua')
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => category = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: captionController,
                    label: 'Ceritakan pengalamanmu...',
                    hintText: 'Tulis tips, tanya kendala tanaman, atau pamer foto tanamanmu!',
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: 'Bagikan ke Komunitas',
                    onPressed: () async {
                      if (captionController.text.trim().isEmpty) return;
                      await _repo.createPost(
                        userId: 'usr_default',
                        category: category,
                        caption: captionController.text.trim(),
                      );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      _loadPosts();
                    },
                  ),
                ],
              ),
            );
          },
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
        title: Text(
          'Komunitas Plenty',
          style: AppTypography.title2Bold.copyWith(color: AppColors.inkSoft),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.forest,
        onPressed: _showCreatePostDialog,
        child: const Icon(Icons.add_comment_outlined, color: Colors.white),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: AppColors.forest,
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.inkSoft,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? AppColors.forest : AppColors.border,
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = cat);
                      _loadPosts();
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.forest),
                  )
                : _posts.isEmpty
                    ? Center(
                        child: Text(
                          'Belum ada postingan di kategori ini.',
                          style: AppTypography.footnoteRegular.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPosts,
                        color: AppColors.forest,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 8.0,
                          ),
                          itemCount: _posts.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final post = _posts[index];
                            return SocialPostCard(
                              post: post,
                              onKudos: () => _handleKudos(post),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
