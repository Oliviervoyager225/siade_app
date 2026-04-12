import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// 🧠 AppLogger — Système centralisé de logs avec Firebase Crashlytics
/// ✅ Checklist point 8 (gestion erreurs) + point 9 (suivi crashs)
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  // ------------------------------------------------------------------
  // 📝 Log d'information simple (visible uniquement en debug)
  // ------------------------------------------------------------------
  void info(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('[INFO]${tag != null ? '[$tag]' : ''} $message');
    }
    _crashlytics.log('[INFO] $message');
  }

  // ------------------------------------------------------------------
  // ⚠️ Log d'avertissement
  // ------------------------------------------------------------------
  void warning(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('[WARN]${tag != null ? '[$tag]' : ''} $message');
    }
    _crashlytics.log('[WARN] $message');
  }

  // ------------------------------------------------------------------
  // ❌ Log d'erreur — envoie automatiquement à Crashlytics en prod
  // ------------------------------------------------------------------
  void error(
    String message, {
    Object? exception,
    StackTrace? stackTrace,
    String? tag,
    bool fatal = false,
  }) {
    if (kDebugMode) {
      debugPrint('[ERROR]${tag != null ? '[$tag]' : ''} $message');
      if (exception != null) debugPrint('  Exception: $exception');
      if (stackTrace != null) debugPrint('  StackTrace: $stackTrace');
    }

    if (!kDebugMode || fatal) {
      if (exception != null) {
        _crashlytics.recordError(
          exception,
          stackTrace,
          reason: message,
          fatal: fatal,
        );
      } else {
        _crashlytics.log('[ERROR] $message');
      }
    }
  }

  // ------------------------------------------------------------------
  // 🔐 Associer l'utilisateur connecté aux rapports Crashlytics
  // ------------------------------------------------------------------
  Future<void> setUser(String userId, {String? email}) async {
    await _crashlytics.setUserIdentifier(userId);
    if (email != null) {
      await _crashlytics.setCustomKey('email', email);
    }
  }

  // ------------------------------------------------------------------
  // 🧹 Effacer l'identité utilisateur (déconnexion)
  // ------------------------------------------------------------------
  Future<void> clearUser() async {
    await _crashlytics.setUserIdentifier('');
  }

  // ------------------------------------------------------------------
  // 📌 Ajouter des clés custom pour mieux diagnostiquer les crashs
  // ------------------------------------------------------------------
  Future<void> setContext(String key, dynamic value) async {
    await _crashlytics.setCustomKey(key, value.toString());
  }
}
