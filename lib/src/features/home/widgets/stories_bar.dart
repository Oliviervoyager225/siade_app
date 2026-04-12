import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:siade2/src/commons/data/models/story.dart';
import 'package:siade2/src/core/services/story_service.dart';
import 'package:siade2/src/features/socialnetwork/pages/page.dart';
import 'package:siade2/src/features/socialnetwork/pages/create_post_page.dart';
import 'package:siade2/src/providers/providers.dart';
import 'package:siade2/src/utils/utils.dart';

/// Barre de stories horizontale — 10 stories les plus récentes,
/// priorité : propre story, utilisateurs avec qui on a interagi.
class StoriesBar extends StatefulWidget {
  const StoriesBar({super.key});

  @override
  State<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends State<StoriesBar> {
  final StoryService _service = StoryService();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  List<Story> _stories = [];
  bool _hasMyStory = false;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _loadStories() async {
    if (_uid == null) return;

    // Récupérer les IDs avec qui l'utilisateur a interagi
    final Set<String> priorityIds = {};
    try {
      final db = _service.firestore;
      final postsSnap = await db
          .collection('posts')
          .where('likedBy', arrayContains: _uid)
          .limit(30)
          .get();
      for (final d in postsSnap.docs) {
        final uid = (d.data()['userId'] as String?) ?? '';
        if (uid.isNotEmpty && uid != _uid) priorityIds.add(uid);
      }
      final sharedSnap = await db
          .collection('posts')
          .where('userId', isEqualTo: _uid)
          .limit(30)
          .get();
      for (final d in sharedSnap.docs) {
        final src = d.data()['resharedFrom'] as Map<String, dynamic>?;
        final uid = (src?['originalUserId'] as String?) ?? '';
        if (uid.isNotEmpty && uid != _uid) priorityIds.add(uid);
      }
    } catch (_) {}

    // Favoris → leurs userId
    if (mounted) {
      final favProv = context.read<FavoritesProvider>();
      for (final s in favProv.favoriteSpeakers) {
        final k = s['key'] as String? ?? '';
        if (k.isNotEmpty) priorityIds.add(k);
      }
    }

    _sub = _service
        .getStoriesStream(priorityUserIds: priorityIds)
        .listen((stories) {
      if (!mounted) return;
      setState(() {
        _stories = stories;
        _hasMyStory = stories.any((s) => s.userId == _uid);
      });
    });
  }

  void _openStory(int index) {
    Navigator.push(context,
        MaterialPageRoute(
            builder: (_) =>
                StoryScreen(stories: _stories, initialIndex: index)));
  }

  void _openCreate() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => CreatePostScreen(initialStoryMode: true)));
  }

  @override
  Widget build(BuildContext context) {
    // S'il n'y a pas de stories ET que je n'ai pas de story → on affiche quand même la case "créer"
    final userProvider = context.watch<UserProvider>();
    final userData = userProvider.user;

    return SizedBox(
      height: 90,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _stories.isEmpty
            ? 1
            : (_hasMyStory ? _stories.length : _stories.length + 1),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          // Carte "Créer une story" (toujours en 1ère position si pas de story perso)
          if (!_hasMyStory && index == 0) {
            return _CreateStoryCard(
              userData: userData,
              onTap: _openCreate,
            );
          }
          final storyIndex = _hasMyStory ? index : index - 1;
          final story = _stories[storyIndex];
          final isMe = story.userId == _uid;
          return _StoryCard(
            story: story,
            isMe: isMe,
            onTap: () => _openStory(storyIndex),
          );
        },
      ),
    );
  }
}

// ── Carte "Créer une story" style Facebook ────────────────────────────────────
class _CreateStoryCard extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final VoidCallback onTap;
  const _CreateStoryCard({required this.userData, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final photoUrl =
        (userData?['photoURL'] ?? userData?['photo'] ?? '').toString().trim();
    final firstName =
        (userData?['first_name'] ?? '').toString().trim();
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';
    final bgColor = avatarColorForInitial(firstName.isNotEmpty ? firstName : (userData?['username'] ?? '').toString());

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Avatar utilisateur
                CircleAvatar(
                  radius: 28,
                  backgroundColor: bgColor,
                  foregroundImage:
                      photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  onForegroundImageError:
                      photoUrl.isNotEmpty ? (_, __) {} : null,
                  child: Text(initial,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ),
                // Bouton "+"  — dégradé violet
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: isLight ? Colors.white : const Color(0xFF0A0E27),
                          width: 2),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4A148C), Color(0xFF9E87CE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.add,
                        color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Créer',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isLight
                    ? const Color(0xFF180468)
                    : Colors.white70,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Carte d'une story existante ───────────────────────────────────────────────
class _StoryCard extends StatelessWidget {
  final Story story;
  final bool isMe;
  final VoidCallback onTap;
  const _StoryCard(
      {required this.story, required this.isMe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final hasImage = story.imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Miniature de la story (image ou fond coloré)
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasImage
                        ? null
                        : LinearGradient(
                            colors: [
                              avatarColorForInitial(story.userName),
                              const Color(0xFF0A0E27)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    image: hasImage
                        ? DecorationImage(
                            image: NetworkImage(story.imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: !hasImage
                      ? Center(
                          child: Text(
                            story.userName.isNotEmpty
                                ? story.userName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                        )
                      : null,
                ),
                // Anneau de bordure dégradé violet
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: CustomPaint(
                      painter: _GradientRingPainter(
                        colors: const [Color(0xFF4A148C), Color(0xFF9E87CE)],
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                ),
                // Avatar auteur (coin bas gauche)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: isLight
                              ? Colors.white
                              : const Color(0xFF0A0E27),
                          width: 1.5),
                    ),
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor:
                          avatarColorForInitial(story.userName),
                      backgroundImage: story.userAvatar.startsWith('http')
                          ? NetworkImage(story.userAvatar)
                          : null,
                      child: !story.userAvatar.startsWith('http')
                          ? Text(
                              story.userName.isNotEmpty
                                  ? story.userName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isMe
                  ? 'Ma story'
                  : story.userName.split(' ').first,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isLight
                    ? const Color(0xFF180468)
                    : Colors.white70,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Peintre d'anneau dégradé ──────────────────────────────────────────────────
class _GradientRingPainter extends CustomPainter {
  final List<Color> colors;
  final double strokeWidth;
  const _GradientRingPainter(
      {required this.colors, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = SweepGradient(colors: colors);
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_GradientRingPainter old) => false;
}
