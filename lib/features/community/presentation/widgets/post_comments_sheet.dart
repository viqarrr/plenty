import 'dart:io';

import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/features/auth/domain/models/user_model.dart';
import 'package:plenty/features/community/domain/models/community_post.dart';
import 'package:plenty/features/community/domain/models/post_comment_model.dart';
import 'package:plenty/features/community/presentation/controllers/community_controller.dart';

/// Modal bottom sheet displaying comments for a community post,
/// allowing users to read, post new comments, and delete their comments.
class PostCommentsSheet extends StatefulWidget {
  final CommunityController controller;
  final CommunityPost post;

  const PostCommentsSheet({
    super.key,
    required this.controller,
    required this.post,
  });

  /// Opens the comments sheet as an app bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required CommunityController controller,
    required CommunityPost post,
  }) {
    return context.showAppBottomSheet<void>(
      PostCommentsSheet(controller: controller, post: post),
    );
  }

  @override
  State<PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends State<PostCommentsSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<PostCommentModel> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = await PreferenceHandler.getUser();
    final comments = await widget.controller.getComments(widget.post.id);
    if (mounted) {
      setState(() {
        _currentUser = user;
        _comments = comments;
        _isLoading = false;
      });
    }
  }

  Future<void> _submitComment() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    final newComment = await widget.controller.addComment(
      widget.post.id,
      text,
    );

    if (mounted) {
      if (newComment != null) {
        _textController.clear();
        setState(() {
          _comments = [..._comments, newComment];
          _isSubmitting = false;
        });

        // Scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent,
            );
          }
        });
      } else {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.controller.errorMessage ?? 'Gagal menambahkan komentar',
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteComment(PostCommentModel comment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Komentar'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus komentar ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pastelRedText,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await widget.controller.deleteComment(
      widget.post.id,
      comment.id,
    );

    if (mounted) {
      if (success) {
        setState(() {
          _comments = _comments.where((c) => c.id != comment.id).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.controller.errorMessage ?? 'Gagal menghapus komentar',
            ),
          ),
        );
      }
    }
  }

  bool _canDeleteComment(PostCommentModel comment) {
    if (_currentUser == null) return false;
    final currentNumericId = _currentUser?.numericId?.toString();
    final currentUid = _currentUser?.id;

    final isCommentAuthor =
        comment.userId == currentNumericId ||
        (currentUid != null && comment.userId == currentUid);

    final isPostAuthor =
        widget.post.userId != null &&
        widget.post.userId == _currentUser?.numericId;

    return isCommentAuthor || isPostAuthor;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Komentar',
                      style: AppTypography.title2Bold.copyWith(
                        color: AppColors.inkDark,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.pastelGreenBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_comments.length}',
                        style: AppTypography.caption2Bold.copyWith(
                          color: AppColors.forest,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22),
                      color: AppColors.muted,
                      onPressed: () => context.pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.border),

              // Comments Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.forest,
                        ),
                      )
                    : _comments.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: const BoxDecoration(
                                      color: AppColors.pastelGreenBg,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 32,
                                      color: AppColors.forest,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Belum Ada Komentar',
                                    style: AppTypography.headlineSemiBold.copyWith(
                                      color: AppColors.inkDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Jadilah yang pertama berkomentar di diskusi ini!',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.caption1Regular.copyWith(
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            itemCount: _comments.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final comment = _comments[index];
                              final canDelete = _canDeleteComment(comment);

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _CommentAvatar(
                                    avatarUrl: comment.authorAvatarUrl,
                                    name: comment.authorName,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              comment.authorName,
                                              style: AppTypography.caption1Bold
                                                  .copyWith(
                                                color: AppColors.inkDark,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              comment.timeAgo,
                                              style: AppTypography
                                                  .caption2Regular
                                                  .copyWith(
                                                color: AppColors.muted,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          comment.content,
                                          style: AppTypography.bodyRegular
                                              .copyWith(
                                            color: AppColors.inkBody,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (canDelete)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: AppColors.muted,
                                      ),
                                      onPressed: () =>
                                          _handleDeleteComment(comment),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                ],
                              );
                            },
                          ),
              ),

              const Divider(height: 1, color: AppColors.border),

              // Comment Input Field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.canvasBackground,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _textController,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _submitComment(),
                          decoration: const InputDecoration(
                            hintText: 'Tulis komentar...',
                            hintStyle: TextStyle(
                              color: AppColors.muted,
                              fontSize: 13.5,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _isSubmitting
                        ? const SizedBox(
                            width: 36,
                            height: 36,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.forest,
                              ),
                            ),
                          )
                        : IconButton(
                            onPressed: _submitComment,
                            icon: const Icon(
                              Icons.send_rounded,
                              color: AppColors.forest,
                              size: 24,
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;

  const _CommentAvatar({this.avatarUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      if (avatarUrl!.startsWith('http')) {
        return CircleAvatar(
          radius: 16,
          backgroundImage: NetworkImage(avatarUrl!),
        );
      } else if (avatarUrl!.startsWith('assets/')) {
        return CircleAvatar(
          radius: 16,
          backgroundImage: AssetImage(avatarUrl!),
        );
      } else {
        final file = File(avatarUrl!);
        if (file.existsSync()) {
          return CircleAvatar(radius: 16, backgroundImage: FileImage(file));
        }
      }
    }

    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.pastelGreenBg,
      child: Text(
        initial,
        style: AppTypography.caption1Bold.copyWith(
          color: AppColors.forest,
          fontSize: 12,
        ),
      ),
    );
  }
}
