import 'package:flutter/material.dart';

import 'package:siade2/src/core/services/moderation_service.dart';

/// Feuilles de dialogue de signalement et de blocage.
///
/// Regroupées ici pour que le fil d'actualité, les stories, les commentaires
/// et la messagerie présentent exactement la même expérience, et pour qu'un
/// seul endroit soit à modifier si Apple fait évoluer ses exigences.
class ModerationActions {
  const ModerationActions._();

  static const Color _fondSombre = Color(0xFF141B33);

  /// Propose les motifs, puis masque le contenu et ouvre le formulaire.
  static Future<void> signaler(
    BuildContext context, {
    required String contenuId,
    required String typeContenu,
    String? auteurId,
    String? libelleContenu,
  }) async {
    final motif = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _fondSombre,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                libelleContenu == null
                    ? 'Signaler ce contenu'
                    : 'Signaler $libelleContenu',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Le contenu disparaîtra immédiatement de votre fil et notre '
                'équipe le traitera sous 24 heures.',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            ...ModerationService.motifs.map(
              (m) => ListTile(
                title: Text(m, style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, m),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (motif == null) return;

    await ModerationService().signaler(
      contenuId: contenuId,
      typeContenu: typeContenu,
      motif: motif,
      auteurId: auteurId,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Signalement envoyé. Ce contenu ne vous sera plus affiché.',
        ),
      ),
    );
  }

  /// Demande confirmation, puis masque tous les contenus de cet utilisateur.
  static Future<bool> bloquer(
    BuildContext context, {
    required String uid,
    required String nom,
  }) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _fondSombre,
        title: Text(
          'Bloquer $nom ?',
          style: const TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Vous ne verrez plus ses publications ni ses messages. '
          'Vous pourrez le débloquer à tout moment depuis vos réglages.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Bloquer',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirme != true) return false;

    await ModerationService().bloquer(uid);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$nom a été bloqué.')),
      );
    }
    return true;
  }

  /// Les deux entrées à insérer dans un menu contextuel existant.
  ///
  /// [onAvant] est appelé avant l'action, typiquement pour refermer le menu.
  static List<Widget> entreesMenu(
    BuildContext context, {
    required String contenuId,
    required String typeContenu,
    required String auteurId,
    required String auteurNom,
    VoidCallback? onAvant,
    Color couleurTexte = Colors.white,
  }) {
    final moi = ModerationService();
    // Rien à signaler ni à bloquer sur son propre contenu.
    if (auteurId.isEmpty || moi.estBloque(auteurId)) return const [];

    return [
      ListTile(
        leading: const Icon(Icons.flag_outlined, color: Colors.orangeAccent),
        title: Text('Signaler', style: TextStyle(color: couleurTexte)),
        onTap: () {
          onAvant?.call();
          signaler(
            context,
            contenuId: contenuId,
            typeContenu: typeContenu,
            auteurId: auteurId,
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.block, color: Colors.redAccent),
        title: Text('Bloquer $auteurNom', style: TextStyle(color: couleurTexte)),
        onTap: () {
          onAvant?.call();
          bloquer(context, uid: auteurId, nom: auteurNom);
        },
      ),
    ];
  }
}
