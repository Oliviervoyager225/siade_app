import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:siade2/src/core/services/notification_service.dart';
import 'package:siade2/src/features/home/pages/live.dart';
import 'package:siade2/src/theme/colors/app_colors.dart';
import 'package:siade2/l10n/app_localizations.dart';

class AlertPage extends StatefulWidget {
  const AlertPage({super.key});

  @override
  State<AlertPage> createState() => _AlertPageState();
}

class _AlertPageState extends State<AlertPage> {
  final _notifSvc = NotificationService();

  @override
  void initState() {
    super.initState();
    // Marquer tout comme lu quand la page est ouverte
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _notifSvc.markAllRead());
  }

  // ─── Titre de la section date ─────────────────────────────────────────────

  String _dateSection(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final l10n = AppLocalizations.of(context)!;
    if (d == today) return l10n.today.toUpperCase();
    if (d == today.subtract(const Duration(days: 1))) return l10n.yesterday.toUpperCase();
    return DateFormat('d MMMM yyyy', Localizations.localeOf(context).languageCode).format(dt);
  }

  String _timeLabel(Timestamp? ts) {
    if (ts == null) return '';
    return DateFormat('HH:mm').format(ts.toDate());
  }

  // ─── Navigation vers le live ──────────────────────────────────────────────

  Future<void> _goToLive(
      BuildContext ctx, Map<String, dynamic> data, String notifId) async {
    await _notifSvc.markRead(notifId);
    final liveId = data['liveId'] as String? ?? '';
    if (liveId.isEmpty) return;

    // Vérifier que le live est encore actif
    final doc = await FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'native-db',
    ).collection('lives').doc(liveId).get();

    if (!doc.exists || doc.data()?['isLive'] != true) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(ctx)!.liveEnded),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final liveData = doc.data()!;
    if (ctx.mounted) {
      Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (_) => Live(
            liveId: liveId,
            channelName: liveData['channelName'] as String? ?? liveId,
            hostName: liveData['hostName'] as String? ?? '',
            hostPhotoUrl: liveData['hostPhotoUrl'] as String? ?? '',
          ),
        ),
      );
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isLight ? Colors.white : null,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _notifSvc.watchNotifications(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];

          return CustomScrollView(
            slivers: [
              // ── Titre ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 8),
                  child: Row(
                    children: [
                      Text(
                        l10n.alerts,
                        style: TextStyle(
                          color:
                              isLight ? const Color(0xFF60438C) : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      if (docs.isNotEmpty) ...[
                        const Spacer(),
                        TextButton(
                          onPressed: _notifSvc.markAllRead,
                          child: Text(
                            l10n.markAllRead,
                            style: TextStyle(
                                color: isLight
                                    ? const Color(0xFF60438C)
                                    : AppColors.primaryBlue,
                                fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              if (docs.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_none,
                            size: 64,
                            color: isLight
                                ? const Color(0xFF60438C).withOpacity(0.3)
                                : Colors.white30),
                        const SizedBox(height: 12),
                        Text(
                          l10n.noData,
                          style: TextStyle(
                              color: isLight ? Colors.black45 : Colors.white38,
                              fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final doc = docs[i];
                      final data = doc.data();
                      final ts = data['createdAt'] as Timestamp?;
                      final isRead = data['read'] as bool? ?? false;
                      final fromName = data['fromName'] as String? ?? '';
                      final fromPhoto = data['fromPhoto'] as String? ?? '';
                      final body = data['body'] as String? ?? '';
                      final type = data['type'] as String? ?? '';

                      // Séparateur de date si première notif du jour
                      final showDateHeader = i == 0 ||
                          _dateSection(ts) !=
                              _dateSection(docs[i - 1]
                                  .data()['createdAt'] as Timestamp?);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showDateHeader)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
                              child: Text(
                                _dateSection(ts),
                                style: TextStyle(
                                  color: isLight
                                      ? Colors.black38
                                      : AppColors.greySecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          Material(
                            color: isRead
                                ? Colors.transparent
                                : (isLight
                                    ? const Color(0xFF60438C).withOpacity(0.07)
                                    : Colors.white.withOpacity(0.05)),
                            child: InkWell(
                              onTap: type == 'live'
                                  ? () => _goToLive(ctx, data, doc.id)
                                  : () => _notifSvc.markRead(doc.id),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ── Avatar + icône type ──
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        CircleAvatar(
                                          radius: 26,
                                          backgroundImage: fromPhoto.isNotEmpty
                                              ? NetworkImage(fromPhoto)
                                              : null,
                                          backgroundColor: const Color(0xFF60438C),
                                          child: fromPhoto.isEmpty
                                              ? Text(
                                                  fromName.isNotEmpty
                                                      ? fromName[0]
                                                          .toUpperCase()
                                                      : '?',
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18),
                                                )
                                              : null,
                                        ),
                                        Positioned(
                                          bottom: -2,
                                          right: -4,
                                          child: Container(
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: type == 'live'
                                                  ? Colors.red
                                                  : const Color(0xFF60438C),
                                              border: Border.all(
                                                  color: isLight
                                                      ? Colors.white
                                                      : const Color(0xFF050026),
                                                  width: 1.5),
                                            ),
                                            child: Icon(
                                              type == 'live'
                                                  ? Icons.live_tv
                                                  : Icons.notifications,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 14),

                                    // ── Texte ──
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          RichText(
                                            text: TextSpan(
                                              style: TextStyle(
                                                color: isLight
                                                    ? Colors.black87
                                                    : Colors.white,
                                                fontSize: 14,
                                                height: 1.4,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: fromName,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                const TextSpan(text: ' '),
                                                TextSpan(
                                                    text: type == 'live'
                                                        ? ' ${l10n.isLiveNow}'
                                                        : ' $body',
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              if (type == 'live')
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                      right: 8),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red
                                                        .withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        width: 6,
                                                        height: 6,
                                                        decoration:
                                                            const BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        l10n.live.toUpperCase(),
                                                        style: const TextStyle(
                                                          color: Colors.red,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              Text(
                                                _timeLabel(ts),
                                                style: TextStyle(
                                                  color: isLight
                                                      ? Colors.black38
                                                      : Colors.white38,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // ── Point non lu ──
                                    if (!isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(top: 6),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.red,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Divider(
                              color: isLight
                                  ? Colors.black12
                                  : AppColors.greySecondary,
                              height: 0.5,
                              indent: 72),
                        ],
                      );
                    },
                    childCount: docs.length,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
