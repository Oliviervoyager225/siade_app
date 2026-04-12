import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../commons/data/models/story.dart';

class StoryService {
  static final StoryService _instance = StoryService._internal();
  factory StoryService() => _instance;
  StoryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'native-db',
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  String? get currentUserId => currentUser?.uid;
  FirebaseFirestore get firestore => _firestore;

  /// Créer une story
  Future<String?> createStory({
    required String caption,
    required String imageUrl,
    required String userName,
    required String userAvatar,
  }) async {
    final uid = currentUserId;
    if (uid == null) return null;
    final now = DateTime.now();
    final story = Story(
      userId: uid,
      userName: userName,
      userAvatar: userAvatar,
      caption: caption,
      imageUrl: imageUrl,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
    );
    final doc = await _firestore.collection('stories').add(story.toFirestore());
    return doc.id;
  }

  /// Stream des 10 dernières stories actives (moins de 24h)
  /// Priorisation : l'utilisateur courant en 1er, puis les utilisateurs avec
  /// lesquels il a interagi (likedBy, resharedFrom, favoris).
  Stream<List<Story>> getStoriesStream({
    Set<String> priorityUserIds = const {},
  }) {
    final since = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(hours: 24)));

    return _firestore
        .collection('stories')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .where('createdAt', isGreaterThanOrEqualTo: since)
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      final uid = currentUserId;
      final stories = snapshot.docs.map((d) => Story.fromFirestore(d)).toList();

      // Déduplique par userId (garde la plus récente par utilisateur)
      final Map<String, Story> byUser = {};
      for (final s in stories) {
        if (!byUser.containsKey(s.userId)) {
          byUser[s.userId] = s;
        }
      }

      final list = byUser.values.toList();

      // Tri : propre story en 1er, puis utilisateurs prioritaires, puis le reste
      list.sort((a, b) {
        final aIsMe = a.userId == uid ? 0 : 1;
        final bIsMe = b.userId == uid ? 0 : 1;
        if (aIsMe != bIsMe) return aIsMe - bIsMe;

        final aPriority = priorityUserIds.contains(a.userId) ? 0 : 1;
        final bPriority = priorityUserIds.contains(b.userId) ? 0 : 1;
        if (aPriority != bPriority) return aPriority - bPriority;

        return b.createdAt.compareTo(a.createdAt);
      });

      return list.take(10).toList();
    });
  }

  /// Stream de la story la plus récente de l'utilisateur courant (null si aucune)
  Stream<Story?> getMyStoryStream() {
    final uid = currentUserId;
    if (uid == null) return Stream.value(null);
    return _firestore
        .collection('stories')
        .where('userId', isEqualTo: uid)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty ? null : Story.fromFirestore(s.docs.first));
  }

  /// Stream de TOUTES les stories actives de l'utilisateur courant
  Stream<List<Story>> getMyStoriesStream() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);
    final since = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(hours: 24)));
    return _firestore
        .collection('stories')
        .where('userId', isEqualTo: uid)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .where('createdAt', isGreaterThanOrEqualTo: since)
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Story.fromFirestore(d)).toList());
  }

  /// Stream des stories actives d'un utilisateur donné
  Stream<List<Story>> getUserStoriesStream(String userId) {
    final since = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(hours: 24)));
    return _firestore
        .collection('stories')
        .where('userId', isEqualTo: userId)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .where('createdAt', isGreaterThanOrEqualTo: since)
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Story.fromFirestore(d)).toList());
  }

  /// Stream des commentaires d'une story
  Stream<List<StoryComment>> getCommentsStream(String storyId) {
    return _firestore
        .collection('stories')
        .doc(storyId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs
            .map((d) => StoryComment.fromFirestore(d.data(), d.id))
            .toList());
  }

  /// Ajouter un commentaire à une story
  Future<void> addComment(String storyId, String text) async {
    final uid = currentUserId;
    if (uid == null || text.trim().isEmpty) return;

    // Récupérer les infos utilisateur
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final userData = userDoc.data() ?? {};
    final firstName = (userData['first_name'] ?? '').toString().trim();
    final lastName = (userData['last_name'] ?? '').toString().trim();
    final name = firstName.isNotEmpty
        ? (lastName.isNotEmpty ? '$firstName $lastName' : firstName)
        : (userData['username'] ?? uid).toString();
    final avatar =
        (userData['photoURL'] ?? userData['photo'] ?? '').toString();

    await _firestore
        .collection('stories')
        .doc(storyId)
        .collection('comments')
        .add(StoryComment(
          id: '',
          userId: uid,
          userName: name,
          userAvatar: avatar,
          text: text.trim(),
          createdAt: DateTime.now(),
        ).toFirestore());
  }

  /// Marquer une story comme vue
  Future<void> markAsViewed(String storyId) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _firestore.collection('stories').doc(storyId).update({
      'viewedBy': FieldValue.arrayUnion([uid]),
    });
  }
}
