import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:siade2/src/commons/widgets/optimized_image.dart';
import 'package:siade2/src/theme/colors/app_colors.dart';

class UserProfileSheet extends StatefulWidget {
  final String uid;
  final String fallbackName;
  final String? fallbackPhoto;

  const UserProfileSheet({
    super.key,
    required this.uid,
    required this.fallbackName,
    this.fallbackPhoto,
  });

  /// Affiche le bottom sheet de profil. Appeler avec le context actuel.
  static Future<void> show(
    BuildContext context, {
    required String uid,
    required String fallbackName,
    String? fallbackPhoto,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UserProfileSheet(
        uid: uid,
        fallbackName: fallbackName,
        fallbackPhoto: fallbackPhoto,
      ),
    );
  }

  @override
  State<UserProfileSheet> createState() => _UserProfileSheetState();
}

class _UserProfileSheetState extends State<UserProfileSheet> {
  final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'native-db',
  );

  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final doc = await _db.collection('users').doc(widget.uid).get();
    if (mounted) {
      setState(() {
        _user = doc.data();
        _loading = false;
      });
    }
  }

  String _lastSeenText(bool isOnline) {
    if (isOnline) return 'En ligne';
    final ts = _user?['lastSeen'] as Timestamp?;
    if (ts == null) return 'Hors ligne';
    final dt = ts.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final time = DateFormat('HH:mm').format(dt);
    if (d == today) return "Vu aujourd'hui à $time";
    if (d == today.subtract(const Duration(days: 1))) return 'Vu hier à $time';
    return 'Vu le ${DateFormat('d MMM', 'fr').format(dt)} à $time';
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bgColor = isLight ? Colors.white : const Color(0xFF0E0B2E);
    final textColor = isLight ? Colors.black87 : Colors.white;
    final subColor = isLight ? Colors.black45 : Colors.white54;

    final user = _user;
    final firstName = user?['firstName'] as String? ?? '';
    final lastName = user?['lastName'] as String? ?? '';
    final displayName = user?['displayName'] as String? ?? widget.fallbackName;
    final fullName = (firstName.isNotEmpty || lastName.isNotEmpty)
        ? '$firstName $lastName'.trim()
        : displayName;
    final poste = user?['poste'] as String? ?? '';
    final organisation = user?['organisation'] as String? ?? '';
    final photoURL = user?['photoURL'] as String? ?? widget.fallbackPhoto ?? '';
    final bio = user?['bio'] as String? ??
        user?['description'] as String? ?? '';
    final isOnline = user?['isOnline'] as bool? ?? false;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.88,
      expand: false,
      builder: (ctx, controller) => Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: _loading
            ? const Padding(
                padding: EdgeInsets.only(top: 64),
                child: Center(child: CircularProgressIndicator()),
              )
            : ListView(
                controller: controller,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                children: [
                  // ── Poignée ──────────────────────────────────────────────
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 28),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: subColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // ── Avatar + indicateur en ligne ─────────────────────────
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isOnline
                                  ? Colors.green
                                  : const Color(0xFF60438C),
                              width: 2.5,
                            ),
                          ),
                          child: OptimizedAvatar(
                            imageUrl: photoURL.isEmpty ? null : photoURL,
                            fallbackText: fullName,
                            radius: 52,
                            backgroundColor: const Color(0xFF60438C),
                          ),
                        ),
                        if (isOnline)
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: bgColor, width: 2.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ── Nom complet ──────────────────────────────────────────
                  Center(
                    child: Text(
                      fullName,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Statut de connexion ──────────────────────────────────
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOnline ? Colors.green : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _lastSeenText(isOnline),
                          style: TextStyle(
                            color: isOnline ? Colors.green : subColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Séparateur ───────────────────────────────────────────
                  Divider(
                    color: isLight
                        ? Colors.black12
                        : Colors.white.withOpacity(0.08),
                    height: 1,
                  ),

                  const SizedBox(height: 20),

                  // ── Infos ────────────────────────────────────────────────
                  if (poste.isNotEmpty) ...[
                    _InfoRow(
                      icon: Icons.work_outline_rounded,
                      label: 'Profession',
                      value: poste,
                      textColor: textColor,
                      subColor: subColor,
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (organisation.isNotEmpty) ...[
                    _InfoRow(
                      icon: Icons.business_outlined,
                      label: 'Organisation',
                      value: organisation,
                      textColor: textColor,
                      subColor: subColor,
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (bio.isNotEmpty) ...[
                    _InfoRow(
                      icon: Icons.info_outline_rounded,
                      label: 'À propos',
                      value: bio,
                      textColor: textColor,
                      subColor: subColor,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Message si aucun détail disponible au-delà du nom
                  if (poste.isEmpty && organisation.isEmpty && bio.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Aucune information supplémentaire disponible.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: subColor,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

// ─── Ligne d'information ──────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color textColor;
  final Color subColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF60438C).withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF60438C), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: subColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
