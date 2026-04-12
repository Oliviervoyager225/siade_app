import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:siade2/src/features/home/widgets/all_news.dart';
import 'package:siade2/src/theme/theme.dart';
import 'package:sizer/sizer.dart';
import 'package:siade2/src/commons/data/models/story.dart';
import 'package:siade2/src/core/services/story_service.dart';
import 'package:siade2/src/core/services/post_service.dart';
import 'package:siade2/src/features/socialnetwork/pages/page.dart';
import 'package:siade2/src/features/socialnetwork/pages/create_post_page.dart';
import 'package:provider/provider.dart';
import 'package:siade2/src/providers/providers.dart';
import 'package:siade2/src/utils/utils.dart';
import 'package:siade2/l10n/app_localizations.dart';

class News extends StatefulWidget {
  @override
  _NewsState createState() => _NewsState();
}

class _NewsState extends State<News> {
  List<Story> _myStories = [];
  List<Story> _otherStories = [];
  Set<String> _interactedIds = {};

  StreamSubscription? _myStoriesSub;
  StreamSubscription? _interactedSub;
  StreamSubscription? _storiesSub;

  @override
  void initState() {
    super.initState();
    // Toutes mes stories actives
    _myStoriesSub = StoryService().getMyStoriesStream().listen((stories) {
      if (mounted) setState(() => _myStories = stories);
    });
    // IDs des utilisateurs avec qui j'ai interagi → puis leurs stories
    _interactedSub = PostService().getInteractedUserIdsStream().listen((ids) {
      if (!mounted) return;
      _interactedIds = ids;
      _refreshStoriesStream();
    });
  }

  void _refreshStoriesStream() {
    _storiesSub?.cancel();
    _storiesSub = StoryService()
        .getStoriesStream(priorityUserIds: _interactedIds)
        .listen((stories) {
      if (!mounted) return;
      final myUid = StoryService().currentUserId;
      setState(() {
        _otherStories = stories
            .where((s) =>
                s.userId != myUid &&
                _interactedIds.contains(s.userId))
            .take(10)
            .toList();
      });
    });
  }

  @override
  void dispose() {
    _myStoriesSub?.cancel();
    _interactedSub?.cancel();
    _storiesSub?.cancel();
    super.dispose();
  }

  void _openStoryOrCreate(BuildContext context) {
    if (_myStories.isNotEmpty) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  StoryScreen(stories: _myStories, initialIndex: 0)));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => CreatePostScreen(initialStoryMode: true)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = context.watch<UserProvider>().user;
    final totalCount = 1 + _otherStories.length;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.news,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFF180468)
                      : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => AllNews())),
                child: Text(
                  l10n.seeAll,
                  style: TextStyle(color: AppColors.gestureDetectorSeeAll),
                ),
              ),
            ],
          ),
          const Gap(20),
          SizedBox(
            height: 140,
            child: ListView.separated(
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemCount: totalCount,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                // ── Slot 0 : Ma Story ─────────────────────────────────────
                if (index == 0) {
                  return _MyStoryNewsCard(
                    stories: _myStories,
                    userData: userData,
                    onTap: () => _openStoryOrCreate(context),
                  );
                }
                // ── Slots 1..n : stories des utilisateurs interagis ───────
                final story = _otherStories[index - 1];
                return _OtherStoryCard(
                  story: story,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            StoryScreen(stories: [story], initialIndex: 0)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Carte story d'un autre utilisateur ───────────────────────────────────────
class _OtherStoryCard extends StatelessWidget {
  final Story story;
  final VoidCallback onTap;
  const _OtherStoryCard({required this.story, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasImage = story.imageUrl.isNotEmpty;
    final avatarUrl = story.userAvatar;
    final name = story.userName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final bgColor = avatarColorForInitial(name);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: hasImage
              ? DecorationImage(
                  image: NetworkImage(story.imageUrl), fit: BoxFit.cover)
              : null,
          gradient: hasImage
              ? null
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF040126), Color(0xFF07026F)],
                ),
          boxShadow: const [
            BoxShadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 5)),
          ],
        ),
        child: Stack(
          children: [
            // Dégradé bas uniquement
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC000000)],
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
              ),
            ),
            // Label temps restant (ex : "19h")
            if (story.timeRemaining.isNotEmpty)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    story.timeRemaining,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            // Avatar + nom en bas
            Positioned(
              bottom: 6,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: CustomPaint(
                      painter: _GradientRingPainter(
                        colors: const [Color(0xFF4A148C), Color(0xFF9E87CE)],
                        strokeWidth: 2.5,
                        progress: story.expiryProgress,
                      ),
                      child: Center(
                        child: CircleAvatar(
                          radius: 19,
                          backgroundColor: bgColor,
                          foregroundImage: avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : null,
                          onForegroundImageError:
                              avatarUrl.isNotEmpty ? (_, __) {} : null,
                          child: Text(initial,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name.split(' ').first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Première carte "Ma story" dans la section Actualités ─────────────────────
class _MyStoryNewsCard extends StatelessWidget {
  final List<Story> stories;
  final Map<String, dynamic>? userData;
  final VoidCallback onTap;
  const _MyStoryNewsCard(
      {required this.stories, required this.userData, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasStories = stories.isNotEmpty;
    final firstStory = hasStories ? stories.first : null;
    final hasStoryImage = firstStory != null && firstStory.imageUrl.isNotEmpty;

    final photoUrl =
        (userData?['photoURL'] ?? userData?['photo'] ?? '').toString().trim();
    final firstName = (userData?['first_name'] ?? '').toString().trim();
    final nameForColor = firstName.isNotEmpty
        ? firstName
        : (userData?['username'] ?? '').toString();
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';
    final bgColor = avatarColorForInitial(nameForColor);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 100,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: hasStoryImage
                  ? DecorationImage(
                      image: NetworkImage(firstStory!.imageUrl),
                      fit: BoxFit.cover)
                  : null,
              gradient: hasStoryImage
                  ? null
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF040126), Color(0xFF07026F)],
                    ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 58,
                  height: 58,
                  child: CustomPaint(
                    painter: _GradientRingPainter(
                      colors: const [Color(0xFF4A148C), Color(0xFF9E87CE)],
                      strokeWidth: hasStories ? 2.5 : 1.5,
                      progress: hasStories ? stories.first.expiryProgress : 1.0,
                    ),
                    child: Center(
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: bgColor,
                        foregroundImage: photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : null,
                        onForegroundImageError:
                            photoUrl.isNotEmpty ? (_, __) {} : null,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.of(context)!.myStory,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Badge compteur si plusieurs stories
          if (stories.length > 1)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF9E87CE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${stories.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Painter anneau dégradé avec progression 24h ─────────────────────────────
class _GradientRingPainter extends CustomPainter {
  final List<Color> colors;
  final double strokeWidth;
  /// 1.0 = story vient d'être créée (anneau complet), 0.0 = expirée
  final double progress;
  const _GradientRingPainter(
      {required this.colors,
      required this.strokeWidth,
      this.progress = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Fond gris translucide (toujours complet)
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0x33FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (progress <= 0.0) return;

    // Arc coloré = fraction du temps restant
    final sweepAngle = progress * 2 * math.pi;
    final gradient = SweepGradient(
      colors: colors,
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + sweepAngle,
      tileMode: TileMode.clamp,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweepAngle,
      false,
      Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_GradientRingPainter old) =>
      old.colors != colors ||
      old.strokeWidth != strokeWidth ||
      old.progress != progress;
}
