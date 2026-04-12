import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:siade2/src/core/constants/api_constants.dart';
import 'package:siade2/src/core/network/api_client.dart';

/// Gère l'initialisation FCM, la sauvegarde du token et
/// les notifications in-app depuis Firestore.
///
/// Firestore : `notifications/{uid}/items/{notifId}`
///   - type:      'live'
///   - fromUid:   uid du streamer
///   - fromName:  nom du streamer
///   - fromPhoto: photo URL du streamer
///   - liveId:    id du live Firestore
///   - body:      "XYZ est en live !"
///   - read:      bool
///   - createdAt: Timestamp
class NotificationService {
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'native-db',
  );
  final _auth = FirebaseAuth.instance;
  final _apiClient = ApiClient();

  String? get _uid => _auth.currentUser?.uid;

  // Callback pour navigation lors du tap sur une notification push
  static void Function(RemoteMessage message)? onNotificationTap;

  // Callback pour naviguer vers l'onglet Alertes (index 3 dans AppLayout)
  static void Function()? onNavigateToAlerts;

  // Callback pour rejoindre un live depuis une notification
  static void Function(String liveId, String channelName, String hostName, String hostPhoto)? onNavigateToLive;

  // ─── Init complet (appeler une fois au démarrage de l'app) ───────────────

  Future<void> init() async {
    // 1. Demander la permission (iOS / Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('🔔 [NotificationService] permission: ${settings.authorizationStatus}');

    // 2. Sauvegarder le token FCM quand il est disponible
    await _saveToken();

    // 3. Renouvellement auto du token
    _messaging.onTokenRefresh.listen(_persistToken);

    // 4. Message reçu en foreground → bannière in-app
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5. Tap sur notification depuis background (app déjà ouverte)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 6. Tap sur notification qui a ouvert l'app depuis état terminé
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  // ─── Token FCM ────────────────────────────────────────────────────────────

  Future<void> _saveToken() async {
    try {
      final token = await _messaging
          .getToken()
          .timeout(const Duration(seconds: 15), onTimeout: () => null);
      if (token != null) await _persistToken(token);
    } catch (e) {
      debugPrint('⚠️ [NotificationService] getToken error: $e');
    }
  }

  Future<void> _persistToken(String token) async {
    // Sauvegarder dans Firestore si l'utilisateur est connecté
    final uid = _uid;
    if (uid != null) {
      try {
        await _db.collection('users').doc(uid)
            .update({'fcmToken': token})
            .timeout(const Duration(seconds: 5), onTimeout: () {});
        debugPrint('✅ [NotificationService] Firestore token OK');
      } catch (e) {
        debugPrint('⚠️ [NotificationService] Firestore error: $e');
      }
    }

    // Enregistrer auprès du backend Django (avec JWT si connecté)
    try {
      await _apiClient.post(ApiConstants.notificationsRegister, {
        'token': token,
        'device_type': 'ANDROID',
        'firebase_uid': _uid ?? '',
      });
      debugPrint('✅ [NotificationService] Django token OK');
    } catch (e) {
      debugPrint('⚠️ [NotificationService] Django error: $e');
    }
  }

  /// Appeler après connexion (le uid est disponible).
  Future<void> refreshTokenForCurrentUser() => _saveToken();

  // ─── Foreground message ───────────────────────────────────────────────────

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    debugPrint('🔔 [NotificationService] Foreground: ${notification.title}');

    // Bannière cliquable → ouvre AlertPage
    // (Firestore est écrit côté Django backend au moment de l'envoi)
    final ctx = _navigatorKey?.currentContext;
    if (ctx != null) {
      _showInAppBanner(ctx, notification.title, notification.body);
    }
  }


  void _showInAppBanner(BuildContext context, String? title, String? body) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1A1A4E),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onVisible: null,
        action: SnackBarAction(
          label: 'Voir',
          textColor: const Color(0xFF6562FB),
          onPressed: () => onNavigateToAlerts?.call(),
        ),
        content: GestureDetector(
          onTap: () {
            messenger.hideCurrentSnackBar();
            onNavigateToAlerts?.call();
          },
          child: Row(
            children: [
              const Icon(Icons.notifications_rounded, color: Color(0xFF6562FB), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    if (body != null)
                      Text(body,
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Tap sur notification (background / app fermée) ───────────────────────

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔔 [NotificationService] Tap: ${message.data}');
    onNotificationTap?.call(message);

    final data = message.data;
    if (data['type'] == 'live' && (data['liveId'] ?? '').isNotEmpty) {
      // Notif live → rejoindre directement le live
      onNavigateToLive?.call(
        data['liveId'] ?? '',
        data['channelName'] ?? data['liveId'] ?? '',
        data['fromName'] ?? '',
        data['fromPhoto'] ?? '',
      );
    } else {
      // Autres notifs → ouvrir l'onglet Alertes
      onNavigateToAlerts?.call();
    }
  }

  // ─── NavigatorKey (optionnel, assigner depuis main.dart) ─────────────────

  static GlobalKey<NavigatorState>? _navigatorKey;
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  // ─── Flux des notifs in-app ───────────────────────────────────────────────

  /// Stream des dernières 50 notifications de l'utilisateur courant.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchNotifications() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Nombre de notifications non lues.
  Stream<int> watchUnreadCount() {
    final uid = _uid;
    if (uid == null) return Stream.value(0);
    return _db
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  /// Marque une notification comme lue.
  Future<void> markRead(String notifId) async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .doc(notifId)
        .update({'read': true});
  }

  /// Marque toutes les notifications comme lues.
  Future<void> markAllRead() async {
    final uid = _uid;
    if (uid == null) return;
    final snap = await _db
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .where('read', isEqualTo: false)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
