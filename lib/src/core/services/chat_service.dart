import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class ChatService {
  static final ChatService _i = ChatService._();
  factory ChatService() => _i;
  ChatService._();

  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'native-db',
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser?.uid ?? '';
  String get displayName => _auth.currentUser?.displayName ?? 'Utilisateur';
  String? get photoUrl => _auth.currentUser?.photoURL;

  /// ID unique et déterministe pour une conversation entre deux utilisateurs
  String convId(String a, String b) {
    final s = [a, b]..sort();
    return '${s[0]}_${s[1]}';
  }

  /// Stream des conversations de l'utilisateur courant, triées par date
  Stream<QuerySnapshot<Map<String, dynamic>>> watchConversations() {
    return _db
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  /// Stream des messages d'une conversation
  Stream<QuerySnapshot<Map<String, dynamic>>> watchMessages(String cid) {
    return _db
        .collection('conversations')
        .doc(cid)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }

  /// Envoyer un message (atomic batch)
  /// Met à jour unreadCount : incrémente pour le destinataire, remet à 0 pour l'expéditeur
  Future<void> sendMessage(String cid, String receiverId, String text) async {
    final now = Timestamp.now();
    final batch = _db.batch();

    batch.set(
      _db.collection('conversations').doc(cid).collection('messages').doc(),
      {'senderId': uid, 'text': text, 'timestamp': now},
    );

    batch.set(
      _db.collection('conversations').doc(cid),
      {
        'participants': ([uid, receiverId]..sort()),
        'lastMessage': text,
        'lastMessageTime': now,
        'lastSenderId': uid,
        // Incrémente le compteur non-lu du destinataire, remet à 0 celui de l'expéditeur
        'unreadCount': {
          uid: 0,
          receiverId: FieldValue.increment(1),
        },
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  /// Marquer tous les messages d'une conversation comme lus pour l'utilisateur courant
  Future<void> markConversationRead(String cid) async {
    if (uid.isEmpty) return;
    await _db.collection('conversations').doc(cid).update({
      'unreadCount.$uid': 0,
    });
  }

  /// Stream du nombre total de messages non lus dans toutes les conversations
  Stream<int> watchTotalUnreadStream() {
    if (uid.isEmpty) return Stream.value(0);
    return _db
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snap) {
      int total = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        final unreadMap = data['unreadCount'] as Map<String, dynamic>?;
        if (unreadMap != null) {
          final count = unreadMap[uid];
          if (count is int) total += count;
        }
      }
      return total;
    });
  }

  /// Créer ou ouvrir une conversation avec un utilisateur
  Future<String> openConversation(
      String otherUid, String otherName, String? otherPhoto) async {
    if (uid.isEmpty) {
      throw 'Vous devez être connecté avec Firebase pour envoyer des messages.';
    }
    final cid = convId(uid, otherUid);
    final ref = _db.collection('conversations').doc(cid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'participants': ([uid, otherUid]..sort()),
        'participantInfo': {
          uid: {'name': displayName, 'photoUrl': photoUrl ?? ''},
          otherUid: {'name': otherName, 'photoUrl': otherPhoto ?? ''},
        },
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': '',
      });
    }
    return cid;
  }

  /// Stream des autres utilisateurs (barre de statuts)
  Stream<QuerySnapshot<Map<String, dynamic>>> watchOtherUsers() {
    return _db.collection('users').snapshots();
  }

  /// Stream des utilisateurs actifs dans les 3 dernières heures (max 20),
  /// triés : en ligne en premier, puis par lastSeen décroissant.
  /// Inclut TOUS les utilisateurs (online ou offline) vus dans les 3h.
  Stream<List<Map<String, dynamic>>> watchActiveUsers() {
    final cutoff = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(hours: 3)));
    return _db
        .collection('users')
        .where('lastSeen', isGreaterThan: cutoff)
        .limit(20)
        .snapshots()
        .map((snap) {
      final docs = snap.docs
          .where((d) => d.id != uid)
          .map((d) => {'id': d.id, ...d.data()})
          .toList();
      // Trier : isOnline == true en premier, puis lastSeen décroissant
      docs.sort((a, b) {
        final aOnline = (a['isOnline'] as bool?) == true ? 0 : 1;
        final bOnline = (b['isOnline'] as bool?) == true ? 0 : 1;
        if (aOnline != bOnline) return aOnline - bOnline;
        final aTs = (a['lastSeen'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        final bTs = (b['lastSeen'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        return bTs.compareTo(aTs);
      });
      return docs;
    });
  }
}
