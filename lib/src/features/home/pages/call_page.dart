import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:siade2/src/core/services/agora_service.dart';
import 'package:siade2/src/core/services/call_service.dart';

/// Page d'appel audio/vidéo 1:1 via Agora + signalisation Firebase Firestore.
class CallPage extends StatefulWidget {
  final String callId;
  final String channelName;
  final bool isVideo;

  /// true = l'utilisateur courant est l'appelant
  final bool isCaller;
  final String otherName;
  final String? otherPhoto;

  const CallPage({
    super.key,
    required this.callId,
    required this.channelName,
    required this.isVideo,
    required this.isCaller,
    required this.otherName,
    this.otherPhoto,
  });

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final _agora = AgoraService();
  final _callSvc = CallService();

  int? _remoteUid;
  bool _localJoined = false;
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isSpeakerOn = true;
  bool _ended = false;

  Duration _duration = Duration.zero;
  Timer? _durationTimer;
  Timer? _missedTimer;
  StreamSubscription<String?>? _statusSub;

  // ─── Init ─────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _watchCallStatus();
    _initCall();

    // Auto-manqué après 45 s sans réponse (côté appelant uniquement)
    if (widget.isCaller) {
      _missedTimer = Timer(const Duration(seconds: 45), () {
        if (_remoteUid == null && mounted && !_ended) {
          _endCall(newStatus: 'missed');
        }
      });
    }
  }

  // ─── Permissions + Agora ──────────────────────────────────────────────────

  Future<void> _initCall() async {
    // Demande de permissions
    final perms = widget.isVideo
        ? [Permission.camera, Permission.microphone]
        : [Permission.microphone];
    await perms.request();

    try {
      await _agora.initEngine();
      final token = await _agora.fetchToken(
        channelName: widget.channelName,
        role: 1,
      );
      await _agora.joinForCall(
        channelName: widget.channelName,
        token: token,
        enableVideo: widget.isVideo,
        onJoined: () {
          if (mounted) setState(() => _localJoined = true);
        },
        onRemoteJoined: (uid) {
          if (!mounted) return;
          setState(() => _remoteUid = uid);
          _startDurationTimer();
          // L'appelé confirme la connexion active
          if (!widget.isCaller) {
            _callSvc.acceptCall(widget.callId);
          }
        },
        onRemoteLeft: () {
          if (mounted) setState(() => _remoteUid = null);
          _endCall(updateFirestore: false);
        },
        onError: (err, msg) {
          debugPrint('❌ CallPage Agora error: $err – $msg');
        },
      );
    } catch (e) {
      debugPrint('❌ CallPage _initCall error: $e');
      if (mounted) _endCall();
    }
  }

  // ─── Surveillance statut Firestore ────────────────────────────────────────

  void _watchCallStatus() {
    _statusSub = _callSvc.watchCallStatus(widget.callId).listen((status) {
      if (!mounted || _ended) return;
      if (status == 'ended' || status == 'rejected' || status == 'missed') {
        if (status == 'rejected' && widget.isCaller) {
          _showBanner('Appel refusé');
        }
        _endCall(updateFirestore: false);
      }
    });
  }

  // ─── Minuteur durée ───────────────────────────────────────────────────────

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _duration += const Duration(seconds: 1));
    });
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0
        ? '${d.inHours.toString().padLeft(2, '0')}:$m:$s'
        : '$m:$s';
  }

  String get _statusLabel {
    if (_ended) return 'Appel terminé';
    if (_remoteUid != null) return _formatDuration(_duration);
    return widget.isCaller ? 'En train d\'appeler...' : 'Connexion...';
  }

  // ─── Terminer l'appel ─────────────────────────────────────────────────────

  Future<void> _endCall({
    String newStatus = 'ended',
    bool updateFirestore = true,
  }) async {
    if (_ended) return;
    setState(() => _ended = true);
    _durationTimer?.cancel();
    _missedTimer?.cancel();
    _statusSub?.cancel();
    await _agora.leave();
    if (updateFirestore) await _callSvc.endCall(widget.callId);
    if (mounted) Navigator.of(context).pop();
  }

  void _showBanner(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  // ─── Dispose ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _durationTimer?.cancel();
    _missedTimer?.cancel();
    _statusSub?.cancel();
    if (!_ended) {
      _agora.leave();
      _callSvc.endCall(widget.callId);
    }
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _endCall();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: widget.isVideo ? _buildVideoCall() : _buildAudioCall(),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // VIDEO CALL
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildVideoCall() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Vidéo distante (plein écran) ou écran d'attente ──
        if (_remoteUid != null)
          AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: _agora.engine,
              canvas: VideoCanvas(uid: _remoteUid!),
              connection: RtcConnection(channelId: widget.channelName),
            ),
          )
        else
          _WaitingScreen(name: widget.otherName, photo: widget.otherPhoto,
              label: _statusLabel),

        // ── Preview local (coin haut-droit, PiP) ──
        if (_localJoined && !_isVideoOff)
          Positioned(
            top: 56,
            right: 16,
            width: 96,
            height: 136,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: _agora.engine,
                  canvas: const VideoCanvas(uid: 0),
                ),
              ),
            ),
          ),

        // ── Info en haut ──
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 6, color: Colors.black87)],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _statusLabel,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Contrôles en bas ──
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            top: false,
            child: _buildControls(isVideo: true),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // AUDIO CALL
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildAudioCall() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C0052), Color(0xFF050026)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            _AvatarCircle(
              name: widget.otherName,
              photo: widget.otherPhoto,
              radius: 62,
            ),
            const SizedBox(height: 20),
            Text(
              widget.otherName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.phone,
                  color: _remoteUid != null
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFFB74D),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  _statusLabel,
                  style: TextStyle(
                    color: _remoteUid != null
                        ? const Color(0xFF4CAF50)
                        : Colors.white60,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Spacer(flex: 3),
            _buildControls(isVideo: false),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // CONTRÔLES
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildControls({required bool isVideo}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Micro
          _ControlBtn(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            label: _isMuted ? 'Muet' : 'Micro',
            bg: _isMuted ? Colors.red.shade700 : Colors.white24,
            onTap: () async {
              setState(() => _isMuted = !_isMuted);
              await _agora.muteLocalAudio(_isMuted);
            },
          ),

          if (isVideo) ...[
            // Caméra
            _ControlBtn(
              icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
              label: _isVideoOff ? 'Caméra off' : 'Caméra',
              bg: _isVideoOff ? Colors.red.shade700 : Colors.white24,
              onTap: () async {
                setState(() => _isVideoOff = !_isVideoOff);
                await _agora.muteLocalVideo(_isVideoOff);
              },
            ),
            // Retourner caméra
            _ControlBtn(
              icon: Icons.flip_camera_ios_outlined,
              label: 'Retourner',
              bg: Colors.white24,
              onTap: () => _agora.switchCamera(),
            ),
          ] else ...[
            // Haut-parleur (audio uniquement)
            _ControlBtn(
              icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
              label: 'HP',
              bg: _isSpeakerOn ? const Color(0xFF60438C) : Colors.white24,
              onTap: () async {
                setState(() => _isSpeakerOn = !_isSpeakerOn);
                await _agora.setSpeakerOn(_isSpeakerOn);
              },
            ),
          ],

          // Raccrocher
          _ControlBtn(
            icon: Icons.call_end,
            label: 'Terminer',
            bg: Colors.red.shade600,
            size: 62,
            onTap: () => _endCall(),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// WIDGETS HELPERS
// ════════════════════════════════════════════════════════════════════════════

class _WaitingScreen extends StatelessWidget {
  final String name;
  final String? photo;
  final String label;
  const _WaitingScreen(
      {required this.name, required this.photo, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1C0052),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AvatarCircle(name: name, photo: photo, radius: 62),
            const SizedBox(height: 16),
            Text(name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(label,
                style:
                    const TextStyle(color: Colors.white60, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final String name;
  final String? photo;
  final double radius;
  const _AvatarCircle(
      {required this.name, required this.photo, required this.radius});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photo != null && photo!.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF60438C),
      backgroundImage: hasPhoto ? NetworkImage(photo!) : null,
      child: hasPhoto
          ? null
          : Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                  fontSize: radius * 0.65,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final VoidCallback onTap;
  final double size;

  const _ControlBtn({
    required this.icon,
    required this.label,
    required this.bg,
    required this.onTap,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
            child: Icon(icon, color: Colors.white, size: size * 0.44),
          ),
          const SizedBox(height: 5),
          Text(label,
              style:
                  const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// OVERLAY APPEL ENTRANT — utilisé dans AppLayout
// ════════════════════════════════════════════════════════════════════════════

class IncomingCallOverlay extends StatelessWidget {
  final String callId;
  final String channelName;
  final String callerName;
  final String callerPhoto;
  final bool isVideo;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const IncomingCallOverlay({
    super.key,
    required this.callId,
    required this.channelName,
    required this.callerName,
    required this.callerPhoto,
    required this.isVideo,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1C0052), Color(0xFF050026)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: const Color(0xFF60438C).withOpacity(0.5), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Type d'appel
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF60438C).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isVideo ? Icons.videocam : Icons.phone,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isVideo ? 'Appel vidéo entrant' : 'Appel audio entrant',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Avatar
                _AvatarCircle(
                    name: callerName, photo: callerPhoto, radius: 50),
                const SizedBox(height: 16),
                Text(
                  callerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                // Boutons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Rejeter
                    _CallActionBtn(
                      icon: Icons.call_end,
                      label: 'Refuser',
                      color: Colors.red.shade600,
                      onTap: onReject,
                    ),
                    // Accepter
                    _CallActionBtn(
                      icon: isVideo ? Icons.videocam : Icons.phone,
                      label: 'Accepter',
                      color: const Color(0xFF4CAF50),
                      onTap: onAccept,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CallActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _CallActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style:
                  const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}
