import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Outils de modération des contenus publiés par les utilisateurs.
///
/// La règle 1.2 de l'App Store impose, dès qu'une app diffuse du contenu
/// généré par les utilisateurs, un moyen de signaler un contenu offensant,
/// la possibilité de bloquer un utilisateur abusif, et un traitement des
/// signalements sous 24 heures.
///
/// Tout est stocké sur l'appareil : le blocage et le masquage prennent effet
/// immédiatement, sans dépendre du réseau ni de Firestore. Le signalement,
/// lui, part vers le formulaire de contact avec l'identifiant du contenu,
/// pour que l'équipe puisse retrouver et retirer la publication.
class ModerationService extends ChangeNotifier {
  static final ModerationService _instance = ModerationService._interne();
  factory ModerationService() => _instance;
  ModerationService._interne();

  static const String _cleBloques = 'moderation_utilisateurs_bloques';
  static const String _cleMasques = 'moderation_contenus_masques';

  /// Formulaire vers lequel les signalements sont dirigés.
  static const String urlContact = 'https://siade.online/contact';

  static const List<String> motifs = [
    'Contenu offensant ou haineux',
    'Harcèlement ou intimidation',
    'Contenu à caractère sexuel',
    'Violence ou menaces',
    'Spam ou publicité',
    'Fausse information',
    'Autre',
  ];

  final Set<String> _bloques = {};
  final Set<String> _masques = {};
  bool _charge = false;

  Set<String> get utilisateursBloques => Set.unmodifiable(_bloques);
  bool get estCharge => _charge;

  /// À appeler une fois au démarrage, avant l'affichage du premier écran.
  Future<void> charger() async {
    if (_charge) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _bloques
        ..clear()
        ..addAll(prefs.getStringList(_cleBloques) ?? const []);
      _masques
        ..clear()
        ..addAll(prefs.getStringList(_cleMasques) ?? const []);
    } catch (e) {
      debugPrint('[ModerationService] Chargement impossible: $e');
    }
    _charge = true;
    notifyListeners();
  }

  bool estBloque(String? uid) => uid != null && _bloques.contains(uid);

  bool estMasque(String? contenuId) =>
      contenuId != null && _masques.contains(contenuId);

  /// Un contenu est affiché tant que son auteur n'est pas bloqué et que le
  /// contenu lui-même n'a pas été signalé depuis cet appareil.
  bool estVisible({String? auteurId, String? contenuId}) =>
      !estBloque(auteurId) && !estMasque(contenuId);

  Future<void> bloquer(String uid) async {
    if (uid.isEmpty || !_bloques.add(uid)) return;
    await _enregistrer(_cleBloques, _bloques);
    notifyListeners();
  }

  Future<void> debloquer(String uid) async {
    if (!_bloques.remove(uid)) return;
    await _enregistrer(_cleBloques, _bloques);
    notifyListeners();
  }

  Future<void> masquer(String contenuId) async {
    if (contenuId.isEmpty || !_masques.add(contenuId)) return;
    await _enregistrer(_cleMasques, _masques);
    notifyListeners();
  }

  /// Masque le contenu sur-le-champ, puis ouvre le formulaire de contact
  /// pré-rempli. Rend `false` si le navigateur n'a pas pu être ouvert — le
  /// masquage local reste acquis dans tous les cas.
  Future<bool> signaler({
    required String contenuId,
    required String typeContenu,
    required String motif,
    String? auteurId,
  }) async {
    await masquer(contenuId);

    final uri = Uri.parse(urlContact).replace(queryParameters: {
      'sujet': 'Signalement de contenu',
      'type': typeContenu,
      'contenu': contenuId,
      'motif': motif,
      if (auteurId != null && auteurId.isNotEmpty) 'auteur': auteurId,
    });

    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[ModerationService] Ouverture du formulaire impossible: $e');
      return false;
    }
  }

  Future<void> _enregistrer(String cle, Set<String> valeurs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(cle, valeurs.toList());
    } catch (e) {
      debugPrint('[ModerationService] Enregistrement impossible: $e');
    }
  }
}
