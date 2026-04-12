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

  void _init() {
    _subscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final wasOnline = _isOnline;
        _isOnline = results.any(
          (r) =>
              r == ConnectivityResult.wifi ||
              r == ConnectivityResult.mobile ||
              r == ConnectivityResult.ethernet,
        );
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
    _isOnline = results.any(
      (r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet,
    );
    notifyListeners();
  }

  Future<bool> checkNow() async {
    final results = await Connectivity().checkConnectivity();
    _isOnline = results.any(
      (r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet,
    );
    return _isOnline;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
