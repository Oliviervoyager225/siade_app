import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:siade2/src/commons/widgets/optimized_image.dart';
import 'package:siade2/src/core/services/chat_service.dart';
import 'package:siade2/src/features/home/pages/conversation_page.dart';
import 'package:siade2/src/theme/colors/app_colors.dart';

/// Page affichant tous les utilisateurs disponibles pour démarrer une conversation
class UsersListPage extends StatefulWidget {
  const UsersListPage({super.key});

  @override
  State<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  final _search = TextEditingController();
  final _chat = ChatService();
  String _query = '';

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

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final me = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: isLight ? Colors.white : const Color(0xFF050026),
      body: Column(
        children: [
          // ── Header + Search ──
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _circleBtn(
                        Icons.arrow_back,
                        isLight,
                        () => Navigator.pop(context),
                      ),
                      Text(
                        'NOUVEAU MESSAGE',
                        style: TextStyle(
                          color: isLight
                              ? const Color(0xFF60438C).withOpacity(0.8)
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 34), // Espacer pour centrer le titre
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
                      hintText: 'Rechercher un utilisateur...',
                      prefixIcon: const Icon(Icons.search, color: Colors.white70),
                      hintStyle: const TextStyle(color: Colors.white70),
                      fillColor: isLight
                          ? const Color(0xFF60438C).withOpacity(0.8)
                          : AppColors.darkGrey,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Divider(color: AppColors.darkGrey, height: 1),

          // ── Liste des utilisateurs ──
          Expanded(
            child: me == null
                ? const Center(
                    child: Text(
                      'Connectez-vous pour voir les utilisateurs',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _chat.watchOtherUsers(),
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF60438C),
                          ),
                        );
                      }

                      if (!snap.hasData || snap.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.grey.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun utilisateur disponible',
                                style: TextStyle(
                                  color: isLight
                                      ? const Color(0xFF60438C).withOpacity(0.6)
                                      : Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Les utilisateurs apparaîtront ici\nlorsqu\'ils s\'inscrivent',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isLight
                                      ? const Color(0xFF60438C).withOpacity(0.4)
                                      : Colors.grey.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Filtrer l'utilisateur actuel et appliquer la recherche
                      var users = snap.data!.docs
                          .where((d) => d.id != me.uid)
                          .toList();

                      if (_query.isNotEmpty) {
                        users = users.where((d) {
                          final data = d.data();
                          final name = (data['displayName'] ??
                                  data['firstName'] ??
                                  data['username'] ??
                                  '')
                              .toString()
                              .toLowerCase();
                          final email =
                              (data['email'] ?? '').toString().toLowerCase();
                          return name.contains(_query) ||
                              email.contains(_query);
                        }).toList();
                      }

                      if (users.isEmpty) {
                        return Center(
                          child: Text(
                            _query.isEmpty
                                ? 'Aucun autre utilisateur'
                                : 'Aucun résultat pour "$_query"',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: users.length,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        separatorBuilder: (_, __) => Divider(
                          color: AppColors.darkGrey.withOpacity(0.3),
                          height: 0.5,
                          indent: 80,
                        ),
                        itemBuilder: (ctx, i) {
                          final data = users[i].data();
                          final uid = users[i].id;
                          final displayName = (data['displayName'] ??
                              data['firstName'] ??
                              data['username'] ??
                              'Utilisateur') as String;
                          final email = (data['email'] ?? '') as String;
                          final photoUrl = (data['photoURL'] ?? '') as String;
                          final poste = (data['poste'] ?? '') as String;
                          final organisation =
                              (data['organisation'] ?? '') as String;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            onTap: () async {
                              // Ouvrir ou créer la conversation
                              final cid = await _chat.openConversation(
                                uid,
                                displayName,
                                photoUrl.isEmpty ? null : photoUrl,
                              );

                              if (ctx.mounted) {
                                // Retourner à la page de messages puis ouvrir la conversation
                                Navigator.pop(ctx);
                                Navigator.push(
                                  ctx,
                                  MaterialPageRoute(
                                    builder: (_) => ConversationPage(
                                      conversationId: cid,
                                      otherUid: uid,
                                      otherName: displayName,
                                      otherPhotoUrl:
                                          photoUrl.isEmpty ? null : photoUrl,
                                    ),
                                  ),
                                );
                              }
                            },
                            leading: Stack(
                              children: [
                                _avatar(displayName, photoUrl, radius: 28),
                                // Indicateur en ligne (optionnel - à activer si vous ajoutez un champ isOnline)
                                // Positioned(
                                //   right: 0,
                                //   bottom: 0,
                                //   child: Container(
                                //     width: 14,
                                //     height: 14,
                                //     decoration: BoxDecoration(
                                //       color: Colors.green,
                                //       shape: BoxShape.circle,
                                //       border: Border.all(
                                //         color: isLight
                                //             ? Colors.white
                                //             : const Color(0xFF050026),
                                //         width: 2,
                                //       ),
                                //     ),
                                //   ),
                                // ),
                              ],
                            ),
                            title: Text(
                              displayName,
                              style: TextStyle(
                                color: isLight
                                    ? const Color(0xFF60438C)
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (email.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    email,
                                    style: TextStyle(
                                      color: isLight
                                          ? const Color(0xFF60438C)
                                              .withOpacity(0.6)
                                          : Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                                if (poste.isNotEmpty || organisation.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    [poste, organisation]
                                        .where((s) => s.isNotEmpty)
                                        .join(' • '),
                                    style: TextStyle(
                                      color: isLight
                                          ? const Color(0xFF60438C)
                                              .withOpacity(0.5)
                                          : Colors.grey.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: isLight
                                  ? const Color(0xFF60438C).withOpacity(0.4)
                                  : Colors.grey,
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

  // ─── widget helpers ────────────────────────────────────────────────────────

  Widget _circleBtn(IconData icon, bool isLight, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        width: 34,
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFF60438C).withOpacity(0.8) : null,
          border: Border.all(
            color: isLight ? Colors.transparent : AppColors.darkGrey,
            width: 2,
          ),
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
