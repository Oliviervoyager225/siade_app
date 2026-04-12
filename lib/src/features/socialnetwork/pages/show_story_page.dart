import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:siade2/src/commons/data/models/story.dart';
import 'package:siade2/src/core/services/story_service.dart';
import 'package:siade2/src/utils/utils.dart';

class StoryScreen extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;

  const StoryScreen({
    Key? key,
    required this.stories,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen>
    with SingleTickerProviderStateMixin {
  final StoryService _storyService = StoryService();
  final TextEditingController _messageController = TextEditingController();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  late int _currentIndex;
  List<StoryComment> _comments = [];
  StreamSubscription? _commentsSub;
  bool _isSending = false;
  bool _showComments = false;

  late AnimationController _progressAnim;
  Timer? _storyTimer;
  static const _storyDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _progressAnim =
        AnimationController(vsync: this, duration: _storyDuration);
    _startCurrentStory();
  }

  @override
  void dispose() {
    _progressAnim.dispose();
    _storyTimer?.cancel();
    _commentsSub?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  Story get _current => widget.stories[_currentIndex];

  void _startCurrentStory() {
    _storyTimer?.cancel();
    _commentsSub?.cancel();
    _comments = [];
    if (_current.id != null) {
      _storyService.markAsViewed(_current.id!);
      _commentsSub = _storyService
          .getCommentsStream(_current.id!)
          .listen((c) { if (mounted) setState(() => _comments = c); });
    }
    _progressAnim.reset();
    _progressAnim.forward();
    _storyTimer = Timer(_storyDuration, _goNext);
  }

  void _goNext() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() => _currentIndex++);
      _startCurrentStory();
    } else {
      Navigator.pop(context);
    }
  }

  void _goPrev() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _startCurrentStory();
    }
  }

  void _pauseStory() {
    _storyTimer?.cancel();
    _progressAnim.stop();
  }

  void _resumeStory() {
    final remaining = Duration(
        milliseconds:
            ((_storyDuration.inMilliseconds * (1 - _progressAnim.value))
                .round()));
    _storyTimer = Timer(remaining, _goNext);
    _progressAnim.forward();
  }

  Future<void> _sendComment() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending || _current.id == null) return;
    setState(() => _isSending = true);
    _messageController.clear();
    await _storyService.addComment(_current.id!, text);
    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final story = _current;
    final hasImage = story.imageUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: GestureDetector(
        onTapUp: (d) {
          if (_showComments) return;
          if (d.globalPosition.dx > MediaQuery.of(context).size.width / 2) {
            _goNext();
          } else {
            _goPrev();
          }
        },
        onLongPressStart: (_) => _pauseStory(),
        onLongPressEnd: (_) => _resumeStory(),
        child: Stack(
          children: [
            // ── Fond / image ────────────────────────────────────────────
            Positioned.fill(
              child: hasImage
                  ? Image.network(
                      story.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _gradientBackground(story.userName),
                    )
                  : _gradientBackground(story.userName),
            ),
            // Overlay sombre
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
            ),

            // ── Header: barres + infos utilisateur ──────────────────────
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    child: Row(
                      children:
                          List.generate(widget.stories.length, (i) {
                        return Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 2),
                            child: i < _currentIndex
                                ? _progressBar(1.0)
                                : i == _currentIndex
                                    ? AnimatedBuilder(
                                        animation: _progressAnim,
                                        builder: (_, __) => _progressBar(
                                            _progressAnim.value),
                                      )
                                    : _progressBar(0.0),
                          ),
                        );
                      }),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        _StoryAvatar(
                            imageUrl: story.userAvatar,
                            name: story.userName,
                            radius: 20),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(story.userName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            Text(story.timeAgo,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12)),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.white, size: 22),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Caption centré ─────────────────────────────────────────
            if (story.caption.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    story.caption,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 8)
                      ],
                    ),
                  ),
                ),
              ),

            // ── Zone bas : commentaires + saisie ───────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_showComments && _comments.isNotEmpty)
                    Container(
                      height: 180,
                      margin:
                          const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: _comments.length,
                        reverse: true,
                        itemBuilder: (_, i) {
                          final c =
                              _comments[_comments.length - 1 - i];
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _StoryAvatar(
                                    imageUrl: c.userAvatar,
                                    name: c.userName,
                                    radius: 12),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(children: [
                                      TextSpan(
                                          text: '${c.userName} ',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight:
                                                  FontWeight.bold,
                                              fontSize: 12)),
                                      TextSpan(
                                          text: c.text,
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12)),
                                    ]),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius:
                                    BorderRadius.circular(25),
                                border:
                                    Border.all(color: Colors.white30),
                              ),
                              child: TextField(
                                controller: _messageController,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                                onTap: () {
                                  _pauseStory();
                                  setState(
                                      () => _showComments = true);
                                },
                                onSubmitted: (_) {
                                  _sendComment();
                                  _resumeStory();
                                },
                                decoration: const InputDecoration(
                                  hintText: 'Type your reply here...',
                                  hintStyle: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 14),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              _sendComment();
                              _resumeStory();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF4A148C),
                                      Color(0xFF9E87CE)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight),
                                shape: BoxShape.circle,
                              ),
                              child: _isSending
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : Transform.rotate(
                                      angle: -1.5708,
                                      child: const Icon(Icons.send,
                                          color: Colors.white,
                                          size: 20)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressBar(double value) => ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: value,
          minHeight: 3,
          backgroundColor: Colors.white.withOpacity(0.3),
          valueColor:
              const AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );

  Widget _gradientBackground(String name) {
    final color = avatarColorForInitial(name);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.9), const Color(0xFF0A0E27)],
        ),
      ),
    );
  }
}

// ── Avatar helper ─────────────────────────────────────────────────────────────
class _StoryAvatar extends StatelessWidget {
  final String imageUrl;
  final String name;
  final double radius;
  const _StoryAvatar(
      {required this.imageUrl,
      required this.name,
      required this.radius});

  @override
  Widget build(BuildContext context) {
    final hasUrl = imageUrl.startsWith('http');
    return CircleAvatar(
      radius: radius,
      backgroundColor: avatarColorForInitial(name),
      backgroundImage: hasUrl ? NetworkImage(imageUrl) : null,
      child: !hasUrl
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: radius * 0.7,
                  fontWeight: FontWeight.bold),
            )
          : null,
    );
  }
}
