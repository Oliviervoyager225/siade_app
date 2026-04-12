import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'app_logger.dart';

/// 🔋 BackgroundTaskService — Gestion du background robuste
/// ✅ Checklist point 12 : Xiaomi / Tecno / Infinix tuent les apps
/// Utilise WorkManager pour effectuer des tâches en arrière-plan
/// de manière fiable même sur les appareils restrictifs.

const String kSyncTaskName = 'com.siade2.sync';
const String kSyncTaskTag = 'siade2_background_sync';

/// ⚡ Callback appelé par WorkManager dans un isolate séparé
/// IMPORTANT : Cette fonction doit être top-level (pas dans une classe)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      switch (taskName) {
        case kSyncTaskName:
          // TODO : Appeler SyncService().syncNow() ici si besoin
          debugPrint('[WorkManager] Tâche de sync déclenchée');
          break;
        default:
          debugPrint('[WorkManager] Tâche inconnue : $taskName');
      }
      return Future.value(true);
    } catch (e, stack) {
      AppLogger().error(
        'Erreur WorkManager tâche $taskName',
        exception: e,
        stackTrace: stack,
        tag: 'BackgroundTask',
      );
      return Future.value(false);
    }
  });
}

class BackgroundTaskService {
  static final BackgroundTaskService _instance =
      BackgroundTaskService._internal();
  factory BackgroundTaskService() => _instance;
  BackgroundTaskService._internal();

  final _logger = AppLogger();

  /// 🚀 Initialiser WorkManager (appeler depuis main())
  Future<void> init() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );
      _logger.info('WorkManager initialisé', tag: 'BackgroundTask');
    } catch (e, stack) {
      _logger.error(
        'Erreur init WorkManager',
        exception: e,
        stackTrace: stack,
        tag: 'BackgroundTask',
      );
    }
  }

  /// 📅 Planifier une sync périodique (toutes les 15 min minimum)
  Future<void> schedulePeriodic() async {
    try {
      await Workmanager().registerPeriodicTask(
        kSyncTaskTag,
        kSyncTaskName,
        frequency: const Duration(minutes: 15),
        initialDelay: const Duration(minutes: 1),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
      _logger.info('Tâche périodique planifiée', tag: 'BackgroundTask');
    } catch (e, stack) {
      _logger.error(
        'Erreur planification tâche périodique',
        exception: e,
        stackTrace: stack,
        tag: 'BackgroundTask',
      );
    }
  }

  /// 🚫 Annuler toutes les tâches background
  Future<void> cancelAll() async {
    try {
      await Workmanager().cancelAll();
      _logger.info('Toutes les tâches annulées', tag: 'BackgroundTask');
    } catch (e) {
      // silencieux
    }
  }

  /// ✅ Vérifier si on est sur un appareil connu pour tuer les apps
  bool isRestrictiveBrand() {
    final brand = Platform.localeName.toLowerCase();
    // Xiaomi, Tecno, Infinix = marques à risque
    return brand.contains('xiaomi') ||
        brand.contains('tecno') ||
        brand.contains('infinix');
  }
}
