import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:siade2/src/core/services/moderation_service.dart';
import 'package:siade2/src/theme/colors/app_colors.dart';

/// Liste des comptes bloqués, avec déblocage.
///
/// Apple vérifie que le blocage est réversible : sans cet écran, un
/// utilisateur bloqué par erreur le resterait définitivement.
class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  final _moderation = ModerationService();

  /// Les noms viennent de Firestore quand il répond, sinon on affiche
  /// l'identifiant : l'écran doit rester utilisable hors ligne.
  Future<String> _nom(String uid) async {
    try {
      final doc = await FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'native-db',
      ).collection('users').doc(uid).get().timeout(
            const Duration(seconds: 8),
          );
      final data = doc.data();
      final nom = (data?['displayName'] ?? data?['username']) as String?;
      if (nom != null && nom.trim().isNotEmpty) return nom;
    } catch (_) {
      // Silencieux : l'identifiant fait office de repli.
    }
    return 'Utilisateur $uid';
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor:
          isLight ? const Color(0xFFF7F7F7) : const Color(0xFF050026),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Comptes bloqués',
          style: TextStyle(
            color: isLight ? const Color(0xFF60438C) : Colors.white,
          ),
        ),
        iconTheme: IconThemeData(
          color: isLight ? const Color(0xFF60438C) : Colors.white,
        ),
      ),
      body: ListenableBuilder(
        listenable: _moderation,
        builder: (context, _) {
          final uids = _moderation.utilisateursBloques.toList();

          if (uids.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user_outlined,
                        size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Aucun compte bloqué',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Vous pouvez bloquer un utilisateur depuis une '
                      'publication ou une conversation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: uids.length,
            separatorBuilder: (_, __) =>
                Divider(color: AppColors.darkGrey, height: 0.5),
            itemBuilder: (context, i) {
              final uid = uids[i];
              return FutureBuilder<String>(
                future: _nom(uid),
                builder: (context, snap) {
                  final nom = snap.data ?? 'Chargement…';
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.redAccent,
                      child: Icon(Icons.block, color: Colors.white, size: 20),
                    ),
                    title: Text(
                      nom,
                      style: TextStyle(
                        color: isLight
                            ? const Color(0xFF60438C)
                            : Colors.white,
                      ),
                    ),
                    trailing: TextButton(
                      onPressed: () => _moderation.debloquer(uid),
                      child: const Text('Débloquer'),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// Raccourci pour ouvrir l'écran depuis un menu.
void ouvrirComptesBloques(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const BlockedUsersPage()),
  );
}
