import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:siade2/src/core/services/agora_service.dart';
import 'package:siade2/src/features/home/widgets/live_reactions_overlay.dart';

class Live extends StatefulWidget {
  final String liveId;
  final String channelName;
  final String hostName;
  final String hostPhotoUrl;

  const Live({
    super.key,
    required this.liveId,
    required this.channelName,
    required this.hostName,
    this.hostPhotoUrl = '',
  });

  @override
  State<Live> createState() => _LiveState();
}

class _LiveState extends State<Live> {
  final _agora = AgoraService();
  final _commentCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  int? _remoteUid;
  bool _isEngineReady = false;
  LiveReactionsController? _reactionsCtrl;

  @override
  void initState() {
    super.initState();
    _joinLive();
  }

  Future<void> _joinLive() async {
    await _agora.initEngine();
    await _agora.incrementViewers(widget.liveId);

    final token = await _agora.fetchToken(channelName: widget.channelName, role: 2);

    await _agora.joinAsAudience(
      channelName: widget.channelName,
      token: token,
      onStreamerJoined: (uid) {
        if (mounted) {
          setState(() => _remoteUid = uid);
        }
      },
      onStreamerLeft: () {
        if (mounted) {
          setState(() => _remoteUid = null);
        }
      },
      onJoined: () {
        if (mounted) setState(() => _isEngineReady = true);
      },
    );
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    _commentCtrl.clear();
    await _agora.sendComment(widget.liveId, text);
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
    // ✅ FIX : Décrémenter les viewers et quitter proprement
    _agora.decrementViewers(widget.liveId).then((_) {
      _agora.disposeEngine(); // leave() + release
    });
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08042A),
      body: Stack(
        children: [
          // ── Remote video stream ──
          Positioned.fill(child: _buildRemoteVideo()),

          // ── Gradient overlay ──
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
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
                    // Host avatar
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF60438C),
                      backgroundImage: widget.hostPhotoUrl.isNotEmpty
                          ? NetworkImage(widget.hostPhotoUrl)
                          : null,
                      child: widget.hostPhotoUrl.isEmpty
                          ? Text(
                              widget.hostName.isNotEmpty
                                  ? widget.hostName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: Colors.white),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.hostName,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
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
                    const SizedBox(width: 6),
                    // Viewer count from Firestore
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instanceFor(
                          app: Firebase.app(),
                          databaseId: 'native-db',
                        )
                          .collection('lives')
                          .doc(widget.liveId)
                          .snapshots(),
                      builder: (ctx, snap) {
                        final count = (snap.data?.data()
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
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: Colors.black45, shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 20),
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

          // ── Comments ──
          Positioned(
            bottom: 80,
            left: 10,
            right: 70,
            height: 200,
            child: StreamBuilder<QuerySnapshot>(
              stream: _agora.watchComments(widget.liveId),
              builder: (ctx, snap) {
                final docs = snap.data?.docs ?? [];
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollCtrl.hasClients) {
                    _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
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
                                    ((d['name'] ?? '?') as String).isNotEmpty
                                        ? (d['name'] as String)[0].toUpperCase()
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
                                    style:
                                        const TextStyle(color: Colors.white70),
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
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                            hintStyle: const TextStyle(color: Colors.white54),
                            border: InputBorder.none,
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
                    if (_reactionsCtrl != null)
                      LiveReactionBar(controller: _reactionsCtrl!),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoteVideo() {
    if (!_isEngineReady) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    if (_remoteUid == null) {
      return Container(
        color: const Color(0xFF08042A),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: const Color(0xFF60438C),
                backgroundImage: widget.hostPhotoUrl.isNotEmpty
                    ? NetworkImage(widget.hostPhotoUrl)
                    : null,
                child: widget.hostPhotoUrl.isEmpty
                    ? Text(
                        widget.hostName.isNotEmpty
                            ? widget.hostName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                widget.hostName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'En attente du streamer...',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _agora.engine,
        canvas: VideoCanvas(uid: _remoteUid),
        connection: RtcConnection(channelId: widget.channelName),
      ),
    );
  }
}

