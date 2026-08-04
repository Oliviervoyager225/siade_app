import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:siade2/src/providers/providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:siade2/src/commons/widgets/optimized_image.dart';
import 'package:siade2/src/core/services/chat_service.dart';
import 'package:siade2/src/core/services/moderation_service.dart';
import 'package:siade2/src/features/home/pages/conversation_page.dart';
import 'package:siade2/src/features/home/pages/users_list_page.dart';
import 'package:siade2/src/theme/colors/app_colors.dart';
import 'package:siade2/l10n/app_localizations.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _search = TextEditingController();
  final _chat = ChatService();
  String _query = '';
  bool _openingChat = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      setState(() => _query = _search.text.toLowerCase().trim());
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // ─── helpers ───────────────────────────────────────────────────────────────

  String _otherUid(Map<String, dynamic> data) {
    final list = List<String>.from(data['participants'] ?? []);
    return list.firstWhere((p) => p != _chat.uid, orElse: () => '');
  }

  String _otherName(Map<String, dynamic> data) {
    final oUid = _otherUid(data);
    final info =
        (data['participantInfo'] as Map<String, dynamic>?)?[oUid];
    return (info?['name'] ?? AppLocalizations.of(context)!.user) as String;
  }

  String _otherPhoto(Map<String, dynamic> data) {
    final oUid = _otherUid(data);
    final info =
        (data['participantInfo'] as Map<String, dynamic>?)?[oUid];
    return (info?['photoUrl'] ?? '') as String;
  }

  String _formatTime(dynamic ts) {
    if (ts == null) return '';
    final dt = (ts as Timestamp).toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    if (day == today) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (day == today.subtract(const Duration(days: 1))) {
      return AppLocalizations.of(context)!.yesterday;
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  // ─── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final me = FirebaseAuth.instance.currentUser;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isLight ? Colors.white : null,
      body: Column(
        children: [
          // ── Header + Search ──
          SafeArea(
            bottom: false,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 34), // conserve l'alignement centré du titre
                      Text(
                        l10n.chat.toUpperCase(),
                        style: TextStyle(
                          color: isLight
                              ? Color(0xFF60438C).withOpacity(0.8)
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      _circleBtn(
                        Icons.edit_outlined,
                        isLight,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UsersListPage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _search,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      hintText: '${l10n.search}...',
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.white70),
                      hintStyle: const TextStyle(color: Colors.white70),
                      fillColor: isLight
                          ? Color(0xFF60438C).withOpacity(0.8)
                          : AppColors.darkGrey,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Divider(color: AppColors.darkGrey, height: 1),

          // ── Barre de présence (moi en premier + utilisateurs actifs <3h) ──
          if (me != null)
            SizedBox(
              height: 95,
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _chat.watchActiveUsers(),
                builder: (ctx, snap) {
                  final users = snap.data ?? [];
                  
                  // Utiliser UserProvider pour mes infos (réactif)
                  final userProvider = context.watch<UserProvider>();
                  final meData = userProvider.user;
                  final myName = meData?['username'] ?? meData?['displayName'] ?? l10n.me;
                  final myPhoto = meData?['photoURL'] ?? meData?['photo'] ?? '';

                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 20, top: 10),
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemCount: users.length + 1,
                    itemBuilder: (ctx, i) {
                      // Premier item = moi (toujours en ligne)
                      if (i == 0) {
                        return Column(
                          children: [
                            Stack(
                              children: [
                                _avatar(myName, myPhoto, radius: 24),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: isLight
                                              ? Colors.white
                                              : const Color(0xFF050026),
                                          width: 2),
                                    ),
                                    child: const Icon(Icons.add,
                                        size: 10, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.me,
                              style: TextStyle(
                                color: isLight
                                    ? const Color(0xFF60438C)
                                    : Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      }

                      // Autres utilisateurs actifs dans les 3 dernières heures
                      final d = users[i - 1];
                      final name = (d['displayName'] ??
                          d['firstName'] ??
                          'User') as String;
                      final photo = (d['photoURL'] ?? '') as String;
                      final uid = d['id'] as String;
                      final isOnline = (d['isOnline'] as bool?) == true;
                      final dotColor =
                          isOnline ? const Color(0xFF4CAF50) : Colors.red;

                      return GestureDetector(
                        onTap: _openingChat
                            ? null
                            : () async {
                                setState(() => _openingChat = true);
                                try {
                                  final cid = await _chat.openConversation(
                                      uid, name, photo.isEmpty ? null : photo);
                                  if (!context.mounted) return;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ConversationPage(
                                        conversationId: cid,
                                        otherUid: uid,
                                        otherName: name,
                                        otherPhotoUrl:
                                            photo.isEmpty ? null : photo,
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Impossible d\'ouvrir la conversation: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } finally {
                                  if (mounted) setState(() => _openingChat = false);
                                }
                              },
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                _avatar(name, photo, radius: 24),
                                // Indicateur de présence : vert = en ligne, rouge = hors ligne
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 13,
                                    height: 13,
                                    decoration: BoxDecoration(
                                      color: dotColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isLight
                                            ? Colors.white
                                            : const Color(0xFF050026),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              name.length > 8
                                  ? '${name.substring(0, 8)}…'
                                  : name,
                              style: TextStyle(
                                color: isLight
                                    ? const Color(0xFF60438C)
                                    : Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

          Divider(color: AppColors.darkGrey, height: 1),

          // ── Liste des conversations ──
          Expanded(
            child: me == null
                ? const Center(
                    child: Text(
                      'Connectez-vous avec Firebase\npour accéder aux messages',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _chat.watchConversations(),
                    builder: (ctx, snap) {
                      if (snap.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      if (snap.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Erreur de chargement.\n${snap.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.redAccent, fontSize: 12),
                            ),
                          ),
                        );
                      }

                      var docs = snap.data?.docs ?? [];

                      // Les conversations avec un utilisateur bloqué
                      // disparaissent de la liste.
                      docs = docs
                          .where((d) => !ModerationService()
                              .estBloque(_otherUid(d.data())))
                          .toList();

                      // Filtre par recherche
                      if (_query.isNotEmpty) {
                        docs = docs.where((d) {
                          final name =
                              _otherName(d.data()).toLowerCase();
                          return name.contains(_query);
                        }).toList();
                      }

                      if (docs.isEmpty) {
                        return Center(
                          child: Text(
                            _query.isEmpty
                                ? 'Aucune conversation.\nCommencez à discuter !'
                                : 'Aucun résultat pour "$_query"',
                            textAlign: TextAlign.center,
                            style:
                                const TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => Divider(
                            color: AppColors.darkGrey, height: 0.5),
                        itemBuilder: (ctx, i) {
                          final data = docs[i].data();
                          final cid = docs[i].id;
                          final oUid = _otherUid(data);
                          final name = _otherName(data);
                          final photo = _otherPhoto(data);
                          final last =
                              (data['lastMessage'] ?? '') as String;
                          final time =
                              _formatTime(data['lastMessageTime']);

                          return ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 4),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ConversationPage(
                                  conversationId: cid,
                                  otherUid: oUid,
                                  otherName: name,
                                  otherPhotoUrl:
                                      photo.isEmpty ? null : photo,
                                ),
                              ),
                            ),
                            leading: _avatar(name, photo, radius: 28),
                            title: Text(
                              name,
                              style: TextStyle(
                                color: isLight
                                    ? Color(0xFF60438C)
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              last.length > 40
                                  ? '${last.substring(0, 40)}…'
                                  : last,
                              style: TextStyle(
                                color: isLight
                                    ? Color(0xFF60438C).withOpacity(0.6)
                                    : Colors.white70,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              time,
                              style: TextStyle(
                                color: isLight
                                    ? Color(0xFF60438C)
                                    : AppColors.greySecondary,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ─── widgets helpers ───────────────────────────────────────────────────────

  Widget _circleBtn(IconData icon, bool isLight, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        width: 34,
        decoration: BoxDecoration(
          color: isLight ? Color(0xFF60438C).withOpacity(0.8) : null,
          border: Border.all(
              color: isLight ? Colors.transparent : AppColors.darkGrey,
              width: 2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _avatar(String name, String photo, {required double radius}) {
    return OptimizedAvatar(
      imageUrl: photo.isEmpty ? null : photo,
      fallbackText: name,
      radius: radius,
      backgroundColor: const Color(0xFF60438C),
    );
  }
}
