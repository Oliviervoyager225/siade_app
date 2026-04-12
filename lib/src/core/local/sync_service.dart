import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:siade2/src/core/local/local_database.dart';
import 'package:siade2/src/core/local/connectivity_service.dart';
import 'package:siade2/src/core/network/api_client.dart';
import 'package:siade2/src/core/constants/api_constants.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final LocalDatabase _localDb = LocalDatabase();
  final ConnectivityService _connectivity = ConnectivityService();
  final ApiClient _apiClient = ApiClient();

  bool _isSyncing = false;

  /// Appelé au démarrage et quand le réseau revient
  void startListening() {
    _connectivity.addListener(_onConnectivityChange);
  }

  void stopListening() {
    _connectivity.removeListener(_onConnectivityChange);
  }

  void _onConnectivityChange() {
    if (_connectivity.isOnline) {
      debugPrint('[SyncService] Réseau disponible → synchronisation...');
      syncNow();
    }
  }

  /// Lance la synchronisation manuelle de tous les éléments en attente
  Future<void> syncNow() async {
    if (_isSyncing) return;
    if (!_connectivity.isOnline) {
      debugPrint('[SyncService] Hors ligne, synchronisation reportée.');
      return;
    }

    _isSyncing = true;
    debugPrint('[SyncService] Début de la synchronisation...');

    try {
      final pending = await _localDb.getPendingSyncItems();
      debugPrint('[SyncService] ${pending.length} éléments en attente.');

      for (final item in pending) {
        final itemId = item['id'] as int;
        final action = item['action'] as String;
        final endpoint = item['endpoint'] as String;
        final payload = jsonDecode(item['payload'] as String) as Map<String, dynamic>;

        try {
          if (action == 'POST') {
            final response = await _apiClient.post(endpoint, payload);

            if ((response.statusCode ?? 0) >= 200 &&
                (response.statusCode ?? 0) < 300) {
              debugPrint('[SyncService] ✅ Synchronisé: $endpoint');

              // Si c'est une inscription, mettre à jour l'utilisateur local
              if (endpoint == ApiConstants.users) {
                final email = payload['email'] as String?;
                final remoteId = response.data['id'] as int?;
                if (email != null && remoteId != null) {
                  await _localDb.markUserSynced(email, remoteId);
                  debugPrint('[SyncService] Utilisateur $email marqué comme synchronisé (remote_id=$remoteId)');
                }
              }

              await _localDb.deleteSyncItem(itemId);
            } else {
              await _localDb.incrementRetryCount(itemId);
            }
          }
        } catch (e) {
          debugPrint('[SyncService] ❌ Échec de sync item $itemId: $e');
          await _localDb.incrementRetryCount(itemId);
        }
      }
    } finally {
      _isSyncing = false;
      debugPrint('[SyncService] Synchronisation terminée.');
    }
  }

  Future<int> getPendingCount() => _localDb.getPendingSyncCount();
}
