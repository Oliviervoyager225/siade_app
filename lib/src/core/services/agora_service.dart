import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:siade2/src/core/constants/api_constants.dart';
import 'package:siade2/src/core/network/api_client.dart';
import 'agora_token_builder.dart';

const String kAgoraAppId = '52d589a829974813817265517619f360';

class AgoraService {
  static final AgoraService _i = AgoraService._();
  factory AgoraService() => _i;
  AgoraService._();

  RtcEngine? _engine;
  final _apiClient = ApiClient();
  final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'native-db',
  );
  final _auth = FirebaseAuth.instance;

  int? remoteUid;
  bool isJoined = false;
  RtcEngineEventHandler? _currentHandler;

  // ─── Initialisation ────────────────────────────────────────────────────────

  Future<void> initEngine() async {
    // Éviter de réinitialiser si déjà initialisé
    if (_engine != null) {
      debugPrint('⚠️  Agora engine déjà initialisé');
      return;
    }

    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: kAgoraAppId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));
      await _engine!.enableVideo();
      await _engine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 720, height: 1280),
          frameRate: 15,
          bitrate: 1000,
        ),
      );
      debugPrint('✅ Agora engine initialisé avec succès');
    } catch (e) {
      debugPrint('❌ Erreur initialisation Agora: $e');
      rethrow;
    }
  }

  /// Démarre la prévisualisation caméra AVANT de rejoindre un channel.
  Future<void> startPreview() async {
    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine!.startPreview();
  }

  RtcEngine get engine => _engine!;

  // ─── Broadcaster (streamer) ────────────────────────────────────────────────

  Future<void> joinAsBroadcaster({
    required String channelName,
    required String token,
    void Function(int uid)? onUserJoined,
    void Function()? onUserLeft,
    void Function()? onJoined,
    void Function(ErrorCodeType err, String msg)? onError,
  }) async {
    // Quitter le channel précédent si déjà connecté (évite l'erreur -17)
    if (isJoined) {
      await _engine!.leaveChannel();
      isJoined = false;
    }

    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    // Nettoyer l'ancien handler avant d'en enregistrer un nouveau
    if (_currentHandler != null) {
      _engine!.unregisterEventHandler(_currentHandler!);
    }
    _currentHandler = RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        isJoined = true;
        onJoined?.call();
        debugPrint('✅ Agora Broadcaster joined: ${connection.channelId}');
      },
      onUserJoined: (connection, uid, elapsed) {
        remoteUid = uid;
        onUserJoined?.call(uid);
      },
      onUserOffline: (connection, uid, reason) {
        remoteUid = null;
        onUserLeft?.call();
      },
      onError: (err, msg) {
        debugPrint('❌ Agora error: $err - $msg');
        onError?.call(err, msg);
      },
    );
    _engine!.registerEventHandler(_currentHandler!);

    await _engine!.joinChannel(
      token: token,
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
      ),
    );
  }

  // ─── Audience (spectateur) ─────────────────────────────────────────────────

  Future<void> joinAsAudience({
    required String channelName,
    required String token,
    void Function(int uid)? onStreamerJoined,
    void Function()? onStreamerLeft,
    void Function()? onJoined,
  }) async {
    // Quitter le channel précédent si déjà connecté (évite l'erreur -17)
    if (isJoined) {
      await _engine!.leaveChannel();
      isJoined = false;
    }

    await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);

    // Nettoyer l'ancien handler avant d'en enregistrer un nouveau
    if (_currentHandler != null) {
      _engine!.unregisterEventHandler(_currentHandler!);
    }
    _currentHandler = RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        isJoined = true;
        onJoined?.call();
      },
      onUserJoined: (connection, uid, elapsed) {
        remoteUid = uid;
        onStreamerJoined?.call(uid);
      },
      onUserOffline: (connection, uid, reason) {
        remoteUid = null;
        onStreamerLeft?.call();
      },
      onError: (err, msg) => debugPrint('❌ Agora error: $err - $msg'),
    );
    _engine!.registerEventHandler(_currentHandler!);

    await _engine!.joinChannel(
      token: token,
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleAudience,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        publishCameraTrack: false,
        publishMicrophoneTrack: false,
      ),
    );
  }

  Future<void> switchCamera() => _engine!.switchCamera();

  Future<void> muteLocalAudio(bool mute) =>
      _engine!.muteLocalAudioStream(mute);

  Future<void> muteLocalVideo(bool mute) =>
      _engine!.muteLocalVideoStream(mute);

  Future<void> setSpeakerOn(bool on) =>
      _engine!.setEnableSpeakerphone(on);

  // ─── Appel P2P (audio / vidéo) ────────────────────────────────────────────

  /// Rejoint un channel en mode communication P2P (appel 1-à-1).
  /// [enableVideo] : true = appel vidéo, false = appel audio uniquement.
  Future<void> joinForCall({
    required String channelName,
    required String token,
    required bool enableVideo,
    void Function(int uid)? onRemoteJoined,
    void Function()? onRemoteLeft,
    void Function()? onJoined,
    void Function(ErrorCodeType err, String msg)? onError,
  }) async {
    if (enableVideo) {
      await _engine!.enableVideo();
    } else {
      await _engine!.disableVideo();
    }

    if (isJoined) {
      await _engine!.leaveChannel();
      isJoined = false;
    }

    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    if (_currentHandler != null) {
      _engine!.unregisterEventHandler(_currentHandler!);
    }
    _currentHandler = RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        isJoined = true;
        onJoined?.call();
        debugPrint('✅ Agora P2P joined: ${connection.channelId}');
      },
      onUserJoined: (connection, uid, elapsed) {
        remoteUid = uid;
        onRemoteJoined?.call(uid);
      },
      onUserOffline: (connection, uid, reason) {
        remoteUid = null;
        onRemoteLeft?.call();
      },
      onError: (err, msg) {
        debugPrint('❌ Agora P2P error: $err – $msg');
        onError?.call(err, msg);
      },
    );
    _engine!.registerEventHandler(_currentHandler!);

    await _engine!.joinChannel(
      token: token,
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
      ),
    );
  }

  Future<void> leave() async {
    if (_engine == null) {
      debugPrint('⚠️  Agora engine déjà null, skip leave');
      return;
    }
    try {
      if (_currentHandler != null) {
        _engine!.unregisterEventHandler(_currentHandler!);
        _currentHandler = null;
      }
      await _engine?.leaveChannel();
      isJoined = false;
      remoteUid = null;
      debugPrint('✅ Agora: Channel quitté avec succès');
    } catch (e) {
      debugPrint('❌ Erreur lors du leave channel: $e');
    }
  }

  Future<void> disposeEngine() async {
    if (_engine == null) {
      debugPrint('⚠️  Agora engine déjà dispose');
      return;
    }
    try {
      await leave();
      await _engine?.release();
      _engine = null;
      debugPrint('✅ Agora engine libéré avec succès');
    } catch (e) {
      debugPrint('❌ Erreur lors du dispose engine: $e');
    }
  }

  // ─── Token generation ─────────────────────────────────────────────────────

  /// Génère un token Agora AccessToken2 localement.
  /// [role] : 1 = broadcaster, 2 = audience
  Future<String> fetchToken({
    required String channelName,
    required int role,
  }) async {
    final token = buildAgoraToken(
      appId: kAgoraAppId,
      channelName: channelName,
      uid: 0,
      role: role,
      expireSeconds: 3600,
    );
    debugPrint('✅ Agora token généré localement pour: $channelName (role: $role)');
    return token;
  }

  // ─── Firestore — gestion des lives ────────────────────────────────────────

  Future<String> createLive({required String title}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Non connecté');

    final ref = _db.collection('lives').doc();
    await ref.set({
      'hostUid': user.uid,
      'hostName': user.displayName ?? 'Streamer',
      'hostPhotoUrl': user.photoURL ?? '',
      'title': title,
      'channelName': ref.id,
      'isLive': true,
      'viewerCount': 0,
      'startedAt': FieldValue.serverTimestamp(),
    });

    // Notifier tous les autres utilisateurs (fire & forget)
    unawaited(_notifyAllUsersLiveStarted(ref.id, user));

    return ref.id;
  }

  /// Notifie tous les utilisateurs qu'un live a démarré :
  /// 1. Push FCM via Django backend (app fermée/arrière-plan)
  /// 2. Ecriture Firestore (AlertPage temps réel)
  Future<void> _notifyAllUsersLiveStarted(String liveId, User user) async {
    final hostName = user.displayName ?? 'Streamer';
    final hostPhoto = user.photoURL ?? '';

    // 1. Push FCM via Django (gère aussi Firestore côté backend)
    try {
      await _apiClient.post(ApiConstants.notificationsLive, {
        'live_id': liveId,
        'channel_name': liveId,
        'host_name': hostName,
        'host_photo': hostPhoto,
      });
      debugPrint('✅ [Live] Push FCM envoyé via Django');
    } catch (e) {
      debugPrint('⚠️  [Live] Erreur push Django: $e');
    }

    // 2. Firestore batch pour les utilisateurs connectés (temps réel AlertPage)
    try {
      final usersSnap = await _db.collection('users').get();
      final otherUids = usersSnap.docs
          .map((d) => d.id)
          .where((uid) => uid != user.uid)
          .toList();

      if (otherUids.isEmpty) return;

      const batchSize = 500;
      for (var i = 0; i < otherUids.length; i += batchSize) {
        final batch = _db.batch();
        for (final uid in otherUids.skip(i).take(batchSize)) {
          final ref = _db.collection('notifications').doc(uid).collection('items').doc();
          batch.set(ref, {
            'type': 'live',
            'fromUid': user.uid,
            'fromName': hostName,
            'fromPhoto': hostPhoto,
            'liveId': liveId,
            'body': '$hostName est en live !',
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      }
      debugPrint('✅ [Live] Firestore notifs écrites pour ${otherUids.length} users');
    } catch (e) {
      debugPrint('⚠️  [Live] Erreur Firestore: $e');
    }
  }

  Future<void> endLive(String liveId) async {
    await _db.collection('lives').doc(liveId).update({
      'isLive': false,
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Supprime définitivement un live (hôte uniquement).
  Future<void> deleteLive(String liveId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final doc = await _db.collection('lives').doc(liveId).get();
    if (doc.data()?['hostUid'] != user.uid) return; // sécurité
    // Supprimer les commentaires
    final comments = await _db
        .collection('lives')
        .doc(liveId)
        .collection('comments')
        .get();
    final batch = _db.batch();
    for (final c in comments.docs) {
      batch.delete(c.reference);
    }
    batch.delete(_db.collection('lives').doc(liveId));
    await batch.commit();
  }

  Future<void> incrementViewers(String liveId) async {
    await _db.collection('lives').doc(liveId).update(
        {'viewerCount': FieldValue.increment(1)});
  }

  Future<void> decrementViewers(String liveId) async {
    await _db.collection('lives').doc(liveId).update(
        {'viewerCount': FieldValue.increment(-1)});
  }

  // ─── Firestore — chat du live ──────────────────────────────────────────────

  Stream<QuerySnapshot> watchComments(String liveId) {
    return _db
        .collection('lives')
        .doc(liveId)
        .collection('comments')
        .orderBy('timestamp')
        .limitToLast(50)
        .snapshots();
  }

  Future<void> sendComment(String liveId, String text) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db
        .collection('lives')
        .doc(liveId)
        .collection('comments')
        .add({
      'uid': user.uid,
      'name': user.displayName ?? 'Utilisateur',
      'photoUrl': user.photoURL ?? '',
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ─── Firestore — liste des lives actifs ───────────────────────────────────

  Stream<QuerySnapshot> watchActiveLives() {
    return _db
        .collection('lives')
        .where('isLive', isEqualTo: true)
        .orderBy('startedAt', descending: true)
        .snapshots();
  }
}
