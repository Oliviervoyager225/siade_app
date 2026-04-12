import 'package:flutter/material.dart';
import 'package:siade2/src/commons/services/api_service.dart';

class ContentProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  List<dynamic> _speakers = [];
  List<dynamic> _exponents = [];
  List<dynamic> _programs = [];
  List<dynamic> _news = [];

  bool get isLoading => _isLoading;
  List<dynamic> get speakers => _speakers;
  List<dynamic> get exponents => _exponents;
  List<dynamic> get programs => _programs;
  List<dynamic> get news => _news;

  Future<void> fetchAllContent() async {
    _isLoading = true;
    notifyListeners();

    try {
      final responses = await Future.wait([
        _apiService.getSpeakers(),
        _apiService.getExponents(),
        _apiService.getPrograms(),
        _apiService.getArticles(),
      ]);

      _speakers = responses[0].data;
      _exponents = responses[1].data;
      _programs = responses[2].data;
      _news = responses[3].data;
    } catch (e) {
      debugPrint("Erreur lors de la récupération du contenu: $e");
    }

    _isLoading = false;
    notifyListeners();
  }
}
