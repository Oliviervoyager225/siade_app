import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:siade2/src/commons/data/models/chat_message.dart';
import 'package:siade2/src/commons/widgets/moderation_actions.dart';
import 'package:siade2/src/commons/widgets/optimized_image.dart';
import 'package:siade2/src/core/constants/api_constants.dart';
import 'package:siade2/src/core/services/moderation_service.dart';
import 'package:siade2/src/core/network/api_client.dart';
import 'package:siade2/src/core/services/call_service.dart';
import 'package:siade2/src/core/services/chat_service.dart';
import 'package:siade2/src/features/home/pages/call_page.dart';
import 'package:siade2/src/features/home/pages/user_profile_sheet.dart';
import 'package:siade2/src/theme/colors/app_colors.dart';

class ConversationPage extends StatefulWidget {
  final String conversationId;
  final String otherUid;
  final String otherName;
  final String? otherPhotoUrl;

  const ConversationPage({
    super.key,
    required this.conversationId,
    required this.otherUid,
    required this.otherName,
    this.otherPhotoUrl,
  });

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final _msgCtrl = TextEditingController();
  final _scroll = ScrollController();
  final _chat = ChatService();
  final _callSvc = CallService();
  final _apiClient = ApiClient();
  final _moderation = ModerationService();
  final _me = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    // Marque tous les messages comme lus dès l'ouverture de la conversation
    _chat.markConversationRead(widget.conversationId);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Signaler la conversation ou bloquer l'interlocuteur.
  void _ouvrirMenuModeration() {
    final bloque = _moderation.estBloque(widget.otherUid);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141B33),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            if (bloque)
              ListTile(
                leading: const Icon(Icons.lock_open, color: Colors.greenAccent),
                title: Text(
                  'Débloquer ${widget.otherName}',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _moderation.debloquer(widget.otherUid);
                },
              )
            else
              ...ModerationActions.entreesMenu(
                context,
                contenuId: widget.conversationId,
                typeContenu: 'conversation',
                auteurId: widget.otherUid,
                auteurNom: widget.otherName,
                onAvant: () => Navigator.pop(sheetCtx),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    await _chat.sendMessage(widget.conversationId, widget.otherUid, text);
    _scrollToBottom();
  }

  Future<void> _startCall({required bool isVideo}) async {
    // Permissions
    final perms = isVideo
        ? [Permission.camera, Permission.microphone]
        : [Permission.microphone];
    final results = await perms.request();
    final denied = results.values.any((s) =>
        s == PermissionStatus.denied ||
        s == PermissionStatus.permanentlyDenied);
    if (denied) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Permission refusée. Autorisez micro/caméra dans les paramètres.')),
      );
      return;
    }

    // Créer l'appel Firestore
    final result = await _callSvc.createCall(
      calleeId: widget.otherUid,
      calleeName: widget.otherName,
      calleePhoto: widget.otherPhotoUrl,
      type: isVideo ? CallType.video : CallType.audio,
    );
    if (result == null || !mounted) return;

    final (callId, channelName) = result;

    // Notifier l'appelé via FCM (fire & forget)
    final caller = FirebaseAuth.instance.currentUser;
    _apiClient.post(ApiConstants.notificationsCall, {
      'callee_firebase_uid': widget.otherUid,
      'caller_name': caller?.displayName ?? 'Utilisateur',
      'caller_photo': caller?.photoURL ?? '',
      'call_id': callId,
      'channel_name': channelName,
      'call_type': isVideo ? 'video' : 'audio',
    }).ignore();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallPage(
          callId: callId,
          channelName: channelName,
          isVideo: isVideo,
          isCaller: true,
          otherName: widget.otherName,
          otherPhoto: widget.otherPhotoUrl,
        ),
      ),
    );
  }

  // ─── Date helpers ──────────────────────────────────────────────────────────

  String _timeLabel(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return "AUJOURD'HUI";
    if (d == today.subtract(const Duration(days: 1))) return 'HIER';
    const m = [
      'JAN','FÉV','MAR','AVR','MAI','JUN',
      'JUL','AOÛ','SEP','OCT','NOV','DÉC'
    ];
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
  }

  // ─── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Rebâtit l'écran dès qu'un blocage change d'état.
    return ListenableBuilder(
      listenable: _moderation,
      builder: (context, _) => _construire(context),
    );
  }

  Widget _construire(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor:
          isLight ? const Color(0xFFF7F7F7) : const Color(0xFF050026),
      body: Column(
        children: [
          // ── Header ──
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _circleBtn(Icons.arrow_back, isLight,
                      () => Navigator.pop(context)),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => UserProfileSheet.show(
                      context,
                      uid: widget.otherUid,
                      fallbackName: widget.otherName,
                      fallbackPhoto: widget.otherPhotoUrl,
                    ),
                    child: _avatar(widget.otherName, widget.otherPhotoUrl ?? '',
                        radius: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => UserProfileSheet.show(
                        context,
                        uid: widget.otherUid,
                        fallbackName: widget.otherName,
                        fallbackPhoto: widget.otherPhotoUrl,
                      ),
                      child: Text(
                        widget.otherName,
                        style: TextStyle(
                          color:
                              isLight ? const Color(0xFF60438C) : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  _circleBtn(Icons.videocam_outlined, isLight,
                      () => _startCall(isVideo: true)),
                  const SizedBox(width: 8),
                  _circleBtn(Icons.phone_outlined, isLight,
                      () => _startCall(isVideo: false)),
                  const SizedBox(width: 8),
                  _circleBtn(Icons.more_vert, isLight, _ouvrirMenuModeration),
                ],
              ),
            ),
          ),

          Divider(color: AppColors.greySecondary, height: 0.5),

          // ── Interlocuteur bloqué ──
          // Le fil et la saisie disparaissent tant que le blocage est actif.
          if (_moderation.estBloque(widget.otherUid))
            Expanded(child: _panneauBloque(isLight))
          else ...[
          // ── Messages ──
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _chat.watchMessages(widget.conversationId),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'Dites bonjour à ${widget.otherName} 👋',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final msgs =
                    docs.map((d) => ChatMessage.fromDoc(d)).toList();

                _scrollToBottom();

                // Grouper par date
                final widgets = <Widget>[];
                String? lastLabel;
                for (final msg in msgs) {
                  final label = _dateLabel(msg.timestamp);
                  if (label != lastLabel) {
                    widgets.add(_DateLabel(label));
                    lastLabel = label;
                  }
                  widgets.add(_Bubble(
                    msg: msg,
                    isMe: msg.senderId == _me,
                    time: _timeLabel(msg.timestamp),
                    isLight: isLight,
                  ));
                }

                return ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  children: widgets,
                );
              },
            ),
          ),

          // ── Barre de saisie ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: isLight ? const Color(0xFFCDCDCD) : Colors.black,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            isLight ? Colors.white : AppColors.darkGrey,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _msgCtrl,
                        style: TextStyle(
                          color: isLight
                              ? const Color(0xFF60438C)
                              : Colors.white,
                        ),
                        onSubmitted: (_) => _send(),
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          hintText: 'Écrivez votre message...',
                          hintStyle: TextStyle(
                            color: isLight
                                ? const Color(0xFF60438C).withOpacity(0.5)
                                : Colors.grey,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isLight
                              ? [
                                  const Color(0xFF60438C).withOpacity(0.7),
                                  const Color(0xFF60438C),
                                ]
                              : [
                                  AppColors.primaryBlue,
                                  AppColors.primaryRed,
                                ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send,
                          size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ],
        ],
      ),
    );
  }

  Widget _panneauBloque(bool isLight) {
    final couleurTexte = isLight ? const Color(0xFF60438C) : Colors.white;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.block, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Vous avez bloqué ${widget.otherName}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: couleurTexte,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vous ne recevez plus ses messages et il ne peut plus vous '
              'contacter depuis cette conversation.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => _moderation.debloquer(widget.otherUid),
              icon: const Icon(Icons.lock_open),
              label: const Text('Débloquer'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── widget helpers ────────────────────────────────────────────────────────

  Widget _circleBtn(IconData icon, bool isLight, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        width: 34,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isLight ? const Color(0xFF60438C).withOpacity(0.8) : null,
          border: Border.all(
              color: isLight ? Colors.transparent : AppColors.greySecondary),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _avatar(String name, String photo, {required double radius}) {
    return OptimizedAvatar(
      imageUrl: photo.isEmpty ? null : photo,
      fallbackText: name,
      radius: radius,
      backgroundColor: const Color(0xFF60438C),
    );
  }
}

// ─── Sous-widgets ──────────────────────────────────────────────────────────────

class _DateLabel extends StatelessWidget {
  final String label;
  const _DateLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: const TextStyle(
                color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isMe;
  final String time;
  final bool isLight;

  const _Bubble({
    required this.msg,
    required this.isMe,
    required this.time,
    required this.isLight,
  });

  /// Détecte si le texte est uniquement composé d'emoji
  bool get _isEmoji {
    final t = msg.text.trim();
    if (t.isEmpty || t.length > 10) return false;
    return t.runes.every((r) => r > 0x00FF);
  }

  @override
  Widget build(BuildContext context) {
    final align =
        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    if (_isEmoji) {
      return Column(
        crossAxisAlignment: align,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Text(msg.text, style: const TextStyle(fontSize: 30)),
          ),
          _timestamp(),
        ],
      );
    }

    final color = isLight
        ? (isMe ? Colors.black : const Color(0xFF60438C))
        : (isMe ? const Color(0xFF167BF7) : const Color(0xFF2A2940));

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft:
                  isMe ? const Radius.circular(18) : const Radius.circular(4),
              bottomRight:
                  isMe ? const Radius.circular(4) : const Radius.circular(18),
            ),
          ),
          child: Text(
            msg.text,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        _timestamp(),
      ],
    );
  }

  Widget _timestamp() {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
      child: Text(
        time,
        style: TextStyle(
          color: isLight
              ? const Color(0xFF60438C).withOpacity(0.6)
              : Colors.grey,
          fontSize: 10,
        ),
      ),
    );
  }
}
