import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siade2/src/features/welcome/welcome_page.dart';
import 'package:siade2/src/providers/user_provider.dart';

/// Suppression définitive du compte, depuis l'app.
///
/// La règle App Store 5.1.1(v) impose ce chemin : proposer seulement une
/// désactivation, ou renvoyer vers le support par téléphone ou e-mail, est
/// insuffisant. Le mot de confirmation à saisir est l'étape anti-accident
/// autorisée par la même règle.
class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  /// Mot que l'utilisateur doit recopier pour armer le bouton.
  static const String _motConfirmation = 'SUPPRIMER';

  final TextEditingController _confirmation = TextEditingController();
  bool _enCours = false;

  @override
  void initState() {
    super.initState();
    // Le bouton s'active dès que le mot est correctement saisi.
    _confirmation.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _confirmation.dispose();
    super.dispose();
  }

  bool get _confirme =>
      _confirmation.text.trim().toUpperCase() == _motConfirmation;

  Future<void> _supprimer() async {
    final provider = context.read<UserProvider>();
    // Capturé avant la navigation : après `pushAndRemoveUntil` le contexte de
    // cet écran est démonté et ne permet plus d'atteindre le ScaffoldMessenger.
    final messenger = ScaffoldMessenger.of(context);

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer définitivement ?'),
        content: const Text(
          'Votre compte, vos publications, vos stories et vos conversations '
          'seront effacés. Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirme != true || !mounted) return;

    setState(() => _enCours = true);
    final reussi = await provider.deleteAccount();
    if (!mounted) return;
    setState(() => _enCours = false);

    if (reussi) {
      // La session n'existe plus : on repart de l'accueil public, sans
      // possibilité de revenir sur les écrans authentifiés.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => WelcomePage()),
        (route) => false,
      );
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Votre compte a été supprimé.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'La suppression a échoué.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final couleurTexte = isLight ? const Color(0xFF60438C) : Colors.white;

    return Scaffold(
      backgroundColor:
          isLight ? const Color(0xFFF7F7F7) : const Color(0xFF050026),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Supprimer mon compte',
          style: TextStyle(color: couleurTexte),
        ),
        iconTheme: IconThemeData(color: couleurTexte),
      ),
      body: AbsorbPointer(
        absorbing: _enCours,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 56, color: Colors.redAccent),
            const SizedBox(height: 20),
            Text(
              'Cette action est définitive',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: couleurTexte,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'En supprimant votre compte, les données suivantes seront '
              'effacées de nos serveurs :',
              style: TextStyle(color: couleurTexte.withOpacity(0.8)),
            ),
            const SizedBox(height: 12),
            ..._elements.map(
              (element) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.close, size: 16, color: Colors.redAccent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        element,
                        style: TextStyle(
                          color: couleurTexte.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Pour confirmer, saisissez « $_motConfirmation » ci-dessous.',
              style: TextStyle(color: couleurTexte, fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _confirmation,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              style: TextStyle(color: couleurTexte),
              decoration: InputDecoration(
                hintText: _motConfirmation,
                hintStyle: TextStyle(color: couleurTexte.withOpacity(0.4)),
                filled: true,
                fillColor: isLight ? Colors.white : Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _confirme && !_enCours ? _supprimer : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  disabledBackgroundColor: Colors.red.withOpacity(0.3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _enCours
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Supprimer définitivement mon compte',
                        textAlign: TextAlign.center,
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _enCours ? null : () => Navigator.pop(context),
                child: Text(
                  'Annuler',
                  style: TextStyle(color: couleurTexte),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const List<String> _elements = [
    'Votre profil, votre nom et votre photo',
    'Vos publications, commentaires et réactions',
    'Vos stories et vos lives',
    'Vos conversations et vos messages',
    'Votre historique d\'appels',
    'Vos fichiers envoyés (photos et vidéos)',
  ];
}

/// Raccourci pour ouvrir l'écran depuis un menu.
void ouvrirSuppressionCompte(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const DeleteAccountPage()),
  );
}
