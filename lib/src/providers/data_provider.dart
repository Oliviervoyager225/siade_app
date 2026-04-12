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

  // ─── Charger toutes les données ─────────────────────────────────────────────
  Future<void> loadAllData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _dataService.fetchSpeakers(),
        _dataService.fetchPrograms(),
        _dataService.fetchArticles(),
        _dataService.fetchExponents(),
        _dataService.fetchCaterers(),
      ]);

      _speakers = results[0] as List<Speaker>;
      _programs = results[1] as List<Program>;
      _articles = results[2] as List<Article>;
      _exponents = results[3] as List<Exponent>;
      _caterers = results[4] as List<Caterer>;
    } catch (e) {
      debugPrint('Erreur DataProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Refresh spécifique ────────────────────────────────────────────────────
  Future<void> refreshSpeakers() async {
    _speakers = await _dataService.fetchSpeakers();
    notifyListeners();
  }

  Future<void> refreshPrograms() async {
    _programs = await _dataService.fetchPrograms();
    notifyListeners();
  }

  Future<void> refreshArticles() async {
    _articles = await _dataService.fetchArticles();
    notifyListeners();
  }

  Future<void> refreshExponents() async {
    _exponents = await _dataService.fetchExponents();
    notifyListeners();
  }

  Future<void> refreshCaterers() async {
    _caterers = await _dataService.fetchCaterers();
    notifyListeners();
  }
}
