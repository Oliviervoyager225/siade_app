import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal() {
    _init();
  }

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  StreamSubscription? _subscription;

  /// Considère l'appareil en ligne dès qu'un transport existe.
  ///
  /// Lister les transports acceptés (wifi/mobile/ethernet) déclarait hors
  /// ligne tout ce qui sort de cette liste : `vpn`, `bluetooth`, et surtout
  /// `other`, que renvoient les simulateurs iOS. L'app basculait alors sur
  /// son authentification locale sans jamais joindre le serveur. Seuls une
  /// liste vide ou `none` signifient réellement une absence de réseau.
  static bool _enLigne(List<ConnectivityResult> resultats) {
    if (resultats.isEmpty) return false;
    return resultats.any((r) => r != ConnectivityResult.none);
  }

  void _init() {
    _subscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final wasOnline = _isOnline;
        _isOnline = _enLigne(results);
        if (_isOnline != wasOnline) {
          debugPrint(
            '[ConnectivityService] Statut réseau: ${_isOnline ? "EN LIGNE" : "HORS LIGNE"}',
          );
          notifyListeners();
        }
      },
    );

    // Vérification initiale
    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _isOnline = _enLigne(results);
    notifyListeners();
  }

  Future<bool> checkNow() async {
    final results = await Connectivity().checkConnectivity();
    _isOnline = _enLigne(results);
    debugPrint('[ConnectivityService] checkNow: $results → '
        '${_isOnline ? "EN LIGNE" : "HORS LIGNE"}');
    return _isOnline;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
