import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plenty/data/datasources/database_helper.dart';
import 'package:plenty/data/models/community_post_model.dart';
import 'package:plenty/data/models/post_comment_model.dart';
import 'package:sqflite/sqflite.dart';

/// Repository managing community posts, discussions, comments, and kudos.
class ForumRepository {
  final DatabaseHelper _dbHelper;

  ForumRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  static const List<Map<String, dynamic>> defaultSeedPosts = [
    {
      'id': 'post_seed_1',
      'user_id': 1,
      'category': 'Pamer Tanaman',
      'caption':
          'Monstera Deliciosa-ku akhirnya mengeluarkan daun baru dengan fenestrasi ganda! 🎉 Rutin semprot air dan taruh di dekat jendela.',
      'image_url': null,
      'kudos_count': 12,
      'comment_count': 3,
      'created_at': '2026-08-18T10:30:00.000Z',
    },
    {
      'id': 'post_seed_2',
      'user_id': 1,
      'category': 'Tanya Jawab',
      'caption':
          'Ujung daun Sansevieria saya agak menguning dan lembek, apakah ini tanda overwatering? Ada saran perawatannya?',
      'image_url': null,
      'kudos_count': 5,
      'comment_count': 4,
      'created_at': '2026-08-17T15:45:00.000Z',
    },
    {
      'id': 'post_seed_3',
      'user_id': 1,
      'category': 'Tips & Trik',
      'caption':
          'Tips perbanyakan Pothos (Sirih Gading): potong di bawah node, rendam di air selama 2 minggu sampai akar tumbuh 5cm baru pindah ke media tanam!',
      'image_url': null,
      'kudos_count': 24,
      'comment_count': 6,
      'created_at': '2026-08-16T08:15:00.000Z',
    },
  ];

  /// Seeds initial community discussions if the table is empty.
  Future<void> seedInitialPosts() async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseHelper.tableCommunityPosts}',
      ),
    );

    if (count == null || count == 0) {
      final batch = db.batch();
      for (final post in defaultSeedPosts) {
        batch.insert(
          DatabaseHelper.tableCommunityPosts,
          post,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    }
  }

  /// Retrieves community feed posts, optionally filtered by category.
  Future<List<CommunityPostModel>> getPosts({String? category}) async {
    final db = await _dbHelper.database;
    await seedInitialPosts();

    String query = '''
      SELECT 
        p.*,
        u.display_name,
        u.avatar_url
      FROM ${DatabaseHelper.tableCommunityPosts} p
      LEFT JOIN ${DatabaseHelper.tableUsers} u ON p.user_id = u.id
    ''';

    final args = <dynamic>[];
    if (category != null && category != 'Semua' && category.isNotEmpty) {
      query += ' WHERE p.category = ?';
      args.add(category);
    }

    query += ' ORDER BY p.created_at DESC;';

    final results = await db.rawQuery(query, args);

    return results.map((row) => CommunityPostModel.fromMap(row)).toList();
  }

  /// Creates a new community post.
  Future<CommunityPostModel> createPost({
    required String userId,
    required String category,
    required String caption,
    String? imageUrl,
  }) async {
    final db = await _dbHelper.database;
    final id = 'post_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    final post = CommunityPostModel(
      id: id,
      userId: userId,
      authorName: 'Saya',
      category: category,
      caption: caption,
      imageUrl: imageUrl,
      kudosCount: 0,
      commentCount: 0,
      createdAt: now,
    );

    await db.insert(
      DatabaseHelper.tableCommunityPosts,
      post.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return post;
  }

  /// Toggles kudos / like on a post.
  Future<int> toggleKudos(String postId) async {
    final db = await _dbHelper.database;
    await db.rawUpdate('''
      UPDATE ${DatabaseHelper.tableCommunityPosts}
      SET kudos_count = kudos_count + 1
      WHERE id = ?
    ''', [postId]);

    final res = await db.query(
      DatabaseHelper.tableCommunityPosts,
      columns: ['kudos_count'],
      where: 'id = ?',
      whereArgs: [postId],
    );

    return (res.firstOrNull?['kudos_count'] as int?) ?? 0;
  }

  /// Retrieves comments for a given post.
  Future<List<PostCommentModel>> getComments(String postId) async {
    final db = await _dbHelper.database;

    final results = await db.rawQuery('''
      SELECT 
        c.*,
        u.display_name,
        u.avatar_url
      FROM ${DatabaseHelper.tablePostComments} c
      LEFT JOIN ${DatabaseHelper.tableUsers} u ON c.user_id = u.id
      WHERE c.post_id = ?
      ORDER BY c.created_at ASC;
    ''', [postId]);

    return results.map((row) => PostCommentModel.fromMap(row)).toList();
  }

  /// Adds a comment to a post.
  Future<PostCommentModel> addComment({
    required String postId,
    required String userId,
    required String content,
  }) async {
    final db = await _dbHelper.database;
    final id = 'cmt_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    final comment = PostCommentModel(
      id: id,
      postId: postId,
      userId: userId,
      authorName: 'Saya',
      content: content,
      createdAt: now,
    );

    await db.transaction((txn) async {
      await txn.insert(
        DatabaseHelper.tablePostComments,
        comment.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.rawUpdate('''
        UPDATE ${DatabaseHelper.tableCommunityPosts}
        SET comment_count = comment_count + 1
        WHERE id = ?
      ''', [postId]);
    });

    return comment;
  }
}

final forumRepositoryProvider = Provider<ForumRepository>((ref) {
  return ForumRepository();
});
