import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:siade2/src/core/services/agora_service.dart';
import 'package:siade2/src/features/home/widgets/live_reactions_overlay.dart';

class LiveBroadcasterPage extends StatefulWidget {
  const LiveBroadcasterPage({super.key});

  @override
  State<LiveBroadcasterPage> createState() => _LiveBroadcasterPageState();
}

class _LiveBroadcasterPageState extends State<LiveBroadcasterPage> {
  final _agora = AgoraService();
  final _commentCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  bool _isLive = false;
  bool _isMuted = false;
  bool _isCameraFront = true;
  bool _isEngineReady = false;
  bool _isStarting = false;

  String? _liveId;
  LiveReactionsController? _reactionsCtrl;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    await [Permission.camera, Permission.microphone].request();
    await _agora.initEngine();
    // Démarrer la préview caméra immédiatement (avant le live)
    await _agora.startPreview();
    if (mounted) setState(() => _isEngineReady = true);
  }

  Future<void> _startLive() async {
    setState(() => _isStarting = true);
    try {
      // Create Firestore live document
      final liveId = await _agora.createLive(title: 'Mon Live');
      _liveId = liveId;

      // Fetch secure token from Cloud Function
      final token = await _agora.fetchToken(channelName: liveId, role: 1);
      debugPrint('🔑 Token généré (premiers 20 chars): ${token.substring(0, 20)}...');

      bool joined = false;
      await _agora.joinAsBroadcaster(
        channelName: liveId,
        token: token,
        onJoined: () {
          joined = true;
          if (mounted) setState(() => _isLive = true);
        },
        onError: (err, msg) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Agora erreur ${err.index}: $msg'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 6),
              ),
            );
          }
        },
      );

      // Attendre 10s max que onJoined soit appelé
      for (int i = 0; i < 100 && !joined; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (!joined && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Timeout: Agora n\'a pas répondu (vérifier token / réseau)'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Future<void> _stopLive() async {
    if (_liveId != null) await _agora.endLive(_liveId!);
    await _agora.leave();
    if (mounted) {
      setState(() {
        _isLive = false;
        _liveId = null;
      });
    }
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _liveId == null) return;
    _commentCtrl.clear();
    await _agora.sendComment(_liveId!, text);
    await Future.delayed(const Duration(milliseconds: 100));
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _scrollCtrl.dispose();
    // ✅ FIX : Ne dispose l'engine QUE si le live n'est PAS actif
    // Si le live est actif, on laisse tourner (arrêt manuel uniquement)
    if (!_isLive) {
      _agora.disposeEngine();
    } else {
      // Si on sort de la page pendant un live, on l'arrête proprement
      _stopLive().then((_) => _agora.disposeEngine());
    }
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08042A),
      body: Stack(
        children: [
          // ── Camera preview ──
          Positioned.fill(child: _buildCameraPreview()),

          // ── Gradient overlay ──
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // ── Top bar ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Close
                    GestureDetector(
                      onTap: () {
                        if (_isLive) {
                          final nav = Navigator.of(context);
                          _stopLive().then((_) {
                            if (mounted) nav.pop();
                          });
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // LIVE badge
                    if (_isLive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xffD4007A),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('LIVE',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    if (_isLive) const SizedBox(width: 6),
                    // Viewer count
                    if (_isLive && _liveId != null)
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instanceFor(
                            app: Firebase.app(),
                            databaseId: 'native-db',
                          )
                            .collection('lives')
                            .doc(_liveId)
                            .snapshots(),
                        builder: (ctx, snap) {
                          final count =
                              (snap.data?.data()
                                      as Map<String, dynamic>?)?['viewerCount']
                                  as int? ??
                              0;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.visibility,
                                    color: Colors.white, size: 12),
                                const SizedBox(width: 3),
                                Text('$count',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 11)),
                              ],
                            ),
                          );
                        },
                      ),
                    const Spacer(),
                    // Switch camera
                    GestureDetector(
                      onTap: () async {
                        await _agora.switchCamera();
                        setState(() => _isCameraFront = !_isCameraFront);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.black45, shape: BoxShape.circle),
                        child: const Icon(Icons.cameraswitch,
                            color: Colors.white, size: 22),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Mute
                    GestureDetector(
                      onTap: () async {
                        await _agora.muteLocalAudio(!_isMuted);
                        setState(() => _isMuted = !_isMuted);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.black45, shape: BoxShape.circle),
                        child: Icon(
                          _isMuted ? Icons.mic_off : Icons.mic,
                          color: _isMuted ? Colors.red : Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Réactions style Facebook ──
          Positioned.fill(
            child: LiveReactionsOverlay(
              onControllerReady: (ctrl) => _reactionsCtrl = ctrl,
            ),
          ),

          // ── Comments (only shown when live) ──
          if (_isLive && _liveId != null)
            Positioned(
              bottom: 80,
              left: 10,
              right: 70,
              height: 200,
              child: StreamBuilder<QuerySnapshot>(
                stream: _agora.watchComments(_liveId!),
                builder: (ctx, snap) {
                  final docs = snap.data?.docs ?? [];
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollCtrl.hasClients) {
                      _scrollCtrl.jumpTo(
                          _scrollCtrl.position.maxScrollExtent);
                    }
                  });
                  return ListView.builder(
                    controller: _scrollCtrl,
                    itemCount: docs.length,
                    itemBuilder: (ctx, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: const Color(0xFF60438C),
                              backgroundImage: (d['photoUrl'] ?? '').isNotEmpty
                                  ? NetworkImage(d['photoUrl'])
                                  : null,
                              child: (d['photoUrl'] ?? '').isEmpty
                                  ? Text(
                                      ((d['name'] ?? '?') as String)
                                          .isNotEmpty
                                          ? (d['name'] as String)[0]
                                              .toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.white),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(fontSize: 13),
                                  children: [
                                    TextSpan(
                                      text: '${d['name']}  ',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                    TextSpan(
                                      text: d['text'] ?? '',
                                      style: const TextStyle(
                                          color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

          // ── Bottom bar ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: _isLive
                    ? Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: TextField(
                                controller: _commentCtrl,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _sendComment(),
                                decoration: InputDecoration(
                                  hintText: 'Commentaire...',
                                  hintStyle: const TextStyle(
                                      color: Colors.white54),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.send,
                                        color: Colors.white70, size: 20),
                                    onPressed: _sendComment,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Bouton réactions
                          if (_reactionsCtrl != null)
                            LiveReactionBar(controller: _reactionsCtrl!),
                          const SizedBox(width: 8),
                          // Stop live button
                          GestureDetector(
                            onTap: _stopLive,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.stop,
                                  color: Colors.white, size: 24),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: ElevatedButton.icon(
                          onPressed:
                              (_isEngineReady && !_isStarting) ? _startLive : null,
                          icon: _isStarting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.live_tv),
                          label: Text(
                              _isStarting ? 'Démarrage...' : 'Démarrer le Live'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffD4007A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isEngineReady) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _agora.engine,
        canvas: const VideoCanvas(uid: 0),
      ),
    );
  }
}
