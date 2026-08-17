import 'package:flutter/material.dart';
import '../commons/data/models/speaker.dart';
import '../commons/data/models/program.dart';
import '../commons/data/models/news.dart';
import '../commons/data/models/exponent.dart';
import '../commons/data/models/caterer.dart';
import '../core/services/data_service.dart';

class DataProvider with ChangeNotifier {
  final DataService _dataService = DataService();

  List<Speaker> _speakers = [];
  List<Program> _programs = [];
  List<Article> _articles = [];
  List<Exponent> _exponents = [];
  List<Caterer> _caterers = [];
  bool _isLoading = false;

  List<Speaker> get speakers => _speakers;
  List<Program> get programs => _programs;
  List<Article> get articles => _articles;
  List<Exponent> get exponents => _exponents;
  List<Caterer> get caterers => _caterers;
  bool get isLoading => _isLoading;

  /// Vrai quand le dernier chargement a échoué sur au moins une ressource.
  ///
  /// Sans ce drapeau, une liste vide signifiait à la fois « le serveur n'a
  /// rien » et « le serveur est injoignable », et l'écran affichait « Aucune
  /// donnée disponible » dans les deux cas — un message rassurant devant une
  /// panne, sans aucun moyen de réessayer.
  bool _echecChargement = false;
  bool get echecChargement => _echecChargement;

  // ─── Charger toutes les données ─────────────────────────────────────────────
  Future<void> loadAllData() async {
    _isLoading = true;
    _echecChargement = false;
    notifyListeners();

    // Chaque ressource est chargée pour son propre compte. `Future.wait`
    // rejetait en bloc dès la première panne : les quatre autres réponses,
    // pourtant arrivées, étaient perdues.
    final echecs = <String>[];
    await Future.wait([
      _charger('intervenants', _dataService.fetchSpeakers,
          (v) => _speakers = v, echecs),
      _charger('programme', _dataService.fetchPrograms,
          (v) => _programs = v, echecs),
      _charger('actualités', _dataService.fetchArticles,
          (v) => _articles = v, echecs),
      _charger('exposants', _dataService.fetchExponents,
          (v) => _exponents = v, echecs),
      _charger('restauration', _dataService.fetchCaterers,
          (v) => _caterers = v, echecs),
    ]);

    _echecChargement = echecs.isNotEmpty;
    if (_echecChargement) {
      debugPrint('DataProvider: échec sur ${echecs.join(", ")}');
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Charge une ressource et note son libellé dans [echecs] si elle tombe.
  Future<void> _charger<T>(
    String libelle,
    Future<List<T>> Function() recuperer,
    void Function(List<T>) affecter,
    List<String> echecs,
  ) async {
    try {
      affecter(await recuperer());
    } catch (e) {
      echecs.add(libelle);
      debugPrint('DataProvider: $libelle — $e');
    }
  }

  // ─── Refresh spécifique ────────────────────────────────────────────────────
  // Les lectures peuvent désormais lever : ces méthodes passent par le même
  // chemin que [loadAllData] pour qu'un rafraîchissement raté remonte dans
  // [echecChargement] au lieu de casser l'appelant.

  Future<void> refreshSpeakers() =>
      _rafraichir('intervenants', _dataService.fetchSpeakers,
          (v) => _speakers = v);

  Future<void> refreshPrograms() =>
      _rafraichir('programme', _dataService.fetchPrograms,
          (v) => _programs = v);

  Future<void> refreshArticles() =>
      _rafraichir('actualités', _dataService.fetchArticles,
          (v) => _articles = v);

  Future<void> refreshExponents() =>
      _rafraichir('exposants', _dataService.fetchExponents,
          (v) => _exponents = v);

  Future<void> refreshCaterers() =>
      _rafraichir('restauration', _dataService.fetchCaterers,
          (v) => _caterers = v);

  Future<void> _rafraichir<T>(
    String libelle,
    Future<List<T>> Function() recuperer,
    void Function(List<T>) affecter,
  ) async {
    final echecs = <String>[];
    await _charger(libelle, recuperer, affecter, echecs);
    _echecChargement = echecs.isNotEmpty;
    notifyListeners();
  }
}
