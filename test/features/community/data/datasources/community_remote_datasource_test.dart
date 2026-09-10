import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plenty/features/community/data/datasources/community_remote_datasource.dart';
import 'package:plenty/features/community/domain/models/community_post.dart';
import 'package:plenty/features/community/domain/models/post_comment_model.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}
class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}
class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockPostsCollection;
  late MockDocumentReference mockPostDoc;
  late MockCollectionReference mockLikesCollection;
  late MockDocumentReference mockLikeDoc;
  late MockCollectionReference mockCommentsCollection;
  late MockDocumentReference mockCommentDoc;
  late FirestoreCommunityRemoteDataSourceImpl dataSource;

  setUpAll(() {
    registerFallbackValue(SetOptions(merge: true));
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockPostsCollection = MockCollectionReference();
    mockPostDoc = MockDocumentReference();
    mockLikesCollection = MockCollectionReference();
    mockLikeDoc = MockDocumentReference();
    mockCommentsCollection = MockCollectionReference();
    mockCommentDoc = MockDocumentReference();

    when(() => mockFirestore.collection(FirestoreCommunityRemoteDataSourceImpl.postsCollection))
        .thenReturn(mockPostsCollection);
    when(() => mockPostsCollection.doc(any())).thenReturn(mockPostDoc);

    when(() => mockPostDoc.collection(FirestoreCommunityRemoteDataSourceImpl.likesSubcollection))
        .thenReturn(mockLikesCollection);
    when(() => mockLikesCollection.doc(any())).thenReturn(mockLikeDoc);

    when(() => mockPostDoc.collection(FirestoreCommunityRemoteDataSourceImpl.commentsSubcollection))
        .thenReturn(mockCommentsCollection);
    when(() => mockCommentsCollection.doc(any())).thenReturn(mockCommentDoc);

    dataSource = FirestoreCommunityRemoteDataSourceImpl(firestore: mockFirestore);
  });

  group('FirestoreCommunityRemoteDataSourceImpl Posts', () {
    test('getPosts returns list of CommunityPost sorted by createdAt descending', () async {
      final mockDoc1 = MockQueryDocumentSnapshot();
      final mockDoc2 = MockQueryDocumentSnapshot();
      final mockQuerySnapshot = MockQuerySnapshot();

      when(() => mockDoc1.id).thenReturn('post_1');
      when(() => mockDoc1.data()).thenReturn({
        'id': 'post_1',
        'user_id': 'user_1',
        'author_name': 'Sarah',
        'category': 'pertanyaan',
        'caption': 'Post 1 content',
        'created_at': DateTime(2026, 1, 1).toIso8601String(),
      });

      when(() => mockDoc2.id).thenReturn('post_2');
      when(() => mockDoc2.data()).thenReturn({
        'id': 'post_2',
        'user_id': 'user_2',
        'author_name': 'Alex',
        'category': 'tips',
        'caption': 'Post 2 content',
        'created_at': DateTime(2026, 1, 2).toIso8601String(),
      });

      when(() => mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2]);
      when(() => mockPostsCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

      final posts = await dataSource.getPosts();
      expect(posts.length, 2);
      // Sorted desc: post_2 comes first
      expect(posts[0].id, 'post_2');
      expect(posts[1].id, 'post_1');
    });

    test('savePost sets data to document with merge true', () async {
      when(() => mockPostDoc.set(any(), any())).thenAnswer((_) async {});

      final post = CommunityPost(
        id: 'new_post',
        authorName: 'Alex',
        timeAgo: 'Baru saja',
        category: 'tips',
        content: 'Tips menanam aglaonema',
        createdAt: DateTime.now(),
      );

      await dataSource.savePost(post, userId: 'user_123');

      verify(() => mockPostsCollection.doc('new_post')).called(1);
      verify(() => mockPostDoc.set(any(), any())).called(1);
    });

    test('updatePost merges category, caption, and image_url', () async {
      when(() => mockPostDoc.set(any(), any())).thenAnswer((_) async {});

      final post = CommunityPost(
        id: 'edit_post',
        authorName: 'Alex',
        timeAgo: 'Baru saja',
        category: 'pertanyaan',
        content: 'Konten terupdate',
        imagePath: 'https://example.com/img.jpg',
        createdAt: DateTime.now(),
      );

      await dataSource.updatePost(post, userId: 'user_123');

      verify(() => mockPostsCollection.doc('edit_post')).called(1);
      verify(() => mockPostDoc.set(
            {
              'category': 'pertanyaan',
              'caption': 'Konten terupdate',
              'image_url': 'https://example.com/img.jpg',
            },
            any(),
          )).called(1);
    });

    test('deletePost calls delete on document', () async {
      when(() => mockPostDoc.delete()).thenAnswer((_) async {});

      await dataSource.deletePost('post_to_delete');

      verify(() => mockPostsCollection.doc('post_to_delete')).called(1);
      verify(() => mockPostDoc.delete()).called(1);
    });

    test('getPostById returns CommunityPost when document exists', () async {
      final mockPostSnap = MockDocumentSnapshot();
      when(() => mockPostSnap.exists).thenReturn(true);
      when(() => mockPostSnap.data()).thenReturn({
        'id': 'post_target',
        'user_id': 'user_1',
        'author_name': 'Sarah',
        'category': 'pertanyaan',
        'caption': 'Target post content',
        'created_at': DateTime(2026, 1, 1).toIso8601String(),
      });
      when(() => mockPostDoc.get()).thenAnswer((_) async => mockPostSnap);

      final post = await dataSource.getPostById('post_target');
      expect(post, isNotNull);
      expect(post!.id, 'post_target');
      expect(post.authorName, 'Sarah');
    });
  });

  group('FirestoreCommunityRemoteDataSourceImpl Likes', () {
    test('toggleLike deletes like and decrements count if already liked', () async {
      final mockLikeSnap = MockDocumentSnapshot();
      when(() => mockLikeSnap.exists).thenReturn(true);
      when(() => mockLikeDoc.get()).thenAnswer((_) async => mockLikeSnap);
      when(() => mockLikeDoc.delete()).thenAnswer((_) async {});
      when(() => mockPostDoc.set(any(), any())).thenAnswer((_) async {});

      final isLiked = await dataSource.toggleLike('post_1', 'user_1');
      expect(isLiked, isFalse);

      verify(() => mockLikeDoc.delete()).called(1);
      verify(() => mockPostDoc.set(any(), any())).called(1);
    });

    test('toggleLike adds like document and increments count if not yet liked', () async {
      final mockLikeSnap = MockDocumentSnapshot();
      when(() => mockLikeSnap.exists).thenReturn(false);
      when(() => mockLikeDoc.get()).thenAnswer((_) async => mockLikeSnap);
      when(() => mockLikeDoc.set(any(), any())).thenAnswer((_) async {});
      when(() => mockPostDoc.set(any(), any())).thenAnswer((_) async {});

      final isLiked = await dataSource.toggleLike('post_1', 'user_1');
      expect(isLiked, isTrue);

      verify(() => mockLikeDoc.set(any(), any())).called(1);
      verify(() => mockPostDoc.set(any(), any())).called(1);
    });

    test('isPostLikedByUser returns like document existence', () async {
      final mockLikeSnap = MockDocumentSnapshot();
      when(() => mockLikeSnap.exists).thenReturn(true);
      when(() => mockLikeDoc.get()).thenAnswer((_) async => mockLikeSnap);

      final result = await dataSource.isPostLikedByUser('post_1', 'user_1');
      expect(result, isTrue);
    });
  });

  group('FirestoreCommunityRemoteDataSourceImpl Comments', () {
    test('getComments returns list of comments sorted by createdAt ascending', () async {
      final mockDoc1 = MockQueryDocumentSnapshot();
      final mockDoc2 = MockQueryDocumentSnapshot();
      final mockQuerySnap = MockQuerySnapshot();

      when(() => mockDoc1.data()).thenReturn({
        'id': 'c_1',
        'post_id': 'post_1',
        'user_id': 'user_1',
        'author_name': 'Rian',
        'content': 'Komentar 1',
        'created_at': DateTime(2026, 1, 1).toIso8601String(),
      });

      when(() => mockDoc2.data()).thenReturn({
        'id': 'c_2',
        'post_id': 'post_1',
        'user_id': 'user_2',
        'author_name': 'Sarah',
        'content': 'Komentar 2',
        'created_at': DateTime(2026, 1, 2).toIso8601String(),
      });

      when(() => mockQuerySnap.docs).thenReturn([mockDoc2, mockDoc1]);
      when(() => mockCommentsCollection.get()).thenAnswer((_) async => mockQuerySnap);

      final comments = await dataSource.getComments('post_1');
      expect(comments.length, 2);
      expect(comments[0].id, 'c_1');
      expect(comments[1].id, 'c_2');
    });

    test('saveComment writes comment and increments post comment_count', () async {
      when(() => mockCommentDoc.set(any(), any())).thenAnswer((_) async {});
      when(() => mockPostDoc.set(any(), any())).thenAnswer((_) async {});

      final comment = PostCommentModel(
        id: 'new_comment',
        postId: 'post_1',
        userId: 'user_1',
        authorName: 'Rian',
        content: 'Komentar baru',
        createdAt: DateTime.now(),
      );

      await dataSource.saveComment(comment);

      verify(() => mockCommentsCollection.doc('new_comment')).called(1);
      verify(() => mockCommentDoc.set(any(), any())).called(1);
      verify(() => mockPostDoc.set(any(), any())).called(1);
    });

    test('deleteComment removes comment and decrements post comment_count', () async {
      when(() => mockCommentDoc.delete()).thenAnswer((_) async {});
      when(() => mockPostDoc.set(any(), any())).thenAnswer((_) async {});

      await dataSource.deleteComment('post_1', 'c_1');

      verify(() => mockCommentsCollection.doc('c_1')).called(1);
      verify(() => mockCommentDoc.delete()).called(1);
      verify(() => mockPostDoc.set(any(), any())).called(1);
    });
  });

  group('FirestoreCommunityRemoteDataSourceImpl Badge Sharing', () {
    test('hasUserSharedBadge queries post by user_id and badge_id', () async {
      final mockQuery = MockQuery();
      final mockQuerySnap = MockQuerySnapshot();
      final mockDoc = MockQueryDocumentSnapshot();

      when(() => mockPostsCollection.where('user_id', isEqualTo: 'user_1'))
          .thenReturn(mockQuery);
      when(() => mockQuery.where('badge_id', isEqualTo: 'first_plant'))
          .thenReturn(mockQuery);
      when(() => mockQuery.limit(1)).thenReturn(mockQuery);
      when(() => mockQuerySnap.docs).thenReturn([mockDoc]);
      when(() => mockQuery.get()).thenAnswer((_) async => mockQuerySnap);

      final hasShared = await dataSource.hasUserSharedBadge('first_plant', 'user_1');
      expect(hasShared, isTrue);
    });
  });
}
