import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:siade2/src/core/services/agora_service.dart';
import 'package:siade2/src/features/home/pages/live.dart';
import 'package:siade2/src/features/home/pages/live_broadcaster_page.dart';

class LivesListPage extends StatefulWidget {
  const LivesListPage({super.key});

  @override
  State<LivesListPage> createState() => _LivesListPageState();
}

class _LivesListPageState extends State<LivesListPage> {
  final _agora = AgoraService();
  final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'native-db',
  );
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await _db.collection('users').doc(uid).get();
    if (mounted) {
      setState(() => _isAdmin = doc.data()?['isAdmin'] == true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: isLight ? Colors.white : const Color(0xFF08042A),
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 34,
                      width: 34,
                      decoration: BoxDecoration(
                        color: isLight
                            ? const Color(0xFF60438C).withValues(alpha: 0.8)
                            : null,
                        border: Border.all(
                            color: isLight
                                ? Colors.transparent
                                : Colors.white24,
                            width: 2),
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.arrow_back, color: Colors.white, size: 16),
                    ),
                  ),
                  Text(
                    'LIVES',
                    style: TextStyle(
                      color: isLight
                          ? const Color(0xFF60438C).withValues(alpha: 0.8)
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  // Bouton lancer un live (admins seulement)
                  if (_isAdmin)
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LiveBroadcasterPage()),
                      ),
                      child: Container(
                        height: 34,
                        width: 34,
                        decoration: const BoxDecoration(
                          color: Color(0xffD4007A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.live_tv,
                            color: Colors.white, size: 18),
                      ),
                    )
                  else
                    const SizedBox(width: 34),
                ],
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _agora.watchActiveLives(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final docs = snap.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.live_tv,
                            size: 64,
                            color: isLight
                                ? const Color(0xFF60438C).withValues(alpha: 0.3)
                                : Colors.white24),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun live en cours.',
                          style: TextStyle(
                            color: isLight
                                ? const Color(0xFF60438C).withValues(alpha: 0.6)
                                : Colors.white54,
                            fontSize: 16,
                          ),
                        ),
                        if (_isAdmin) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Soyez le premier à démarrer un live !',
                            style: TextStyle(
                              color: isLight
                                  ? const Color(0xFF60438C).withValues(alpha: 0.4)
                                  : Colors.white38,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LiveBroadcasterPage()),
                            ),
                            icon: const Icon(Icons.live_tv),
                            label: const Text('Démarrer un Live'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffD4007A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final liveId = docs[i].id;
                    final channelName = data['channelName'] as String? ?? liveId;
                    final hostName = data['hostName'] as String? ?? 'Streamer';
                    final hostPhotoUrl = data['hostPhotoUrl'] as String? ?? '';
                    final title = data['title'] as String? ?? 'Live';
                    final viewerCount = data['viewerCount'] as int? ?? 0;

                    final isOwner = FirebaseAuth.instance.currentUser?.uid ==
                        data['hostUid'];

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Live(
                            liveId: liveId,
                            channelName: channelName,
                            hostName: hostName,
                            hostPhotoUrl: hostPhotoUrl,
                          ),
                        ),
                      ),
                      onLongPress: isOwner
                          ? () => _confirmDelete(context, _agora, liveId)
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isLight
                              ? const Color(0xFF60438C).withValues(alpha: 0.08)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isLight
                                ? const Color(0xFF60438C).withValues(alpha: 0.2)
                                : Colors.white12,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Host avatar centered
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 36,
                                    backgroundColor:
                                        const Color(0xFF60438C),
                                    backgroundImage: hostPhotoUrl.isNotEmpty
                                        ? NetworkImage(hostPhotoUrl)
                                        : null,
                                    child: hostPhotoUrl.isEmpty
                                        ? Text(
                                            hostName.isNotEmpty
                                                ? hostName[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    hostName,
                                    style: TextStyle(
                                      color: isLight
                                          ? const Color(0xFF60438C)
                                          : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    title,
                                    style: TextStyle(
                                      color: isLight
                                          ? const Color(0xFF60438C)
                                              .withValues(alpha: 0.6)
                                          : Colors.white54,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            // LIVE badge top-left
                            Positioned(
                              top: 10,
                              left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xffD4007A),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('LIVE',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                            // Viewer count top-right
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.visibility,
                                        color: Colors.white, size: 10),
                                    const SizedBox(width: 2),
                                    Text('$viewerCount',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10)),
                                  ],
                                ),
                              ),
                            ),
                            // Bouton supprimer (propriétaire uniquement)
                            if (isOwner)
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => _confirmDelete(
                                      context, _agora, liveId),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.85),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.delete,
                                        color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, AgoraService agora, String liveId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce live ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await agora.endLive(liveId);
      await agora.deleteLive(liveId);
    }
  }
}

