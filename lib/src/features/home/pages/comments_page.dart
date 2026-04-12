import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:siade2/src/core/services/post_service.dart';
import 'package:siade2/src/commons/data/models/posts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:siade2/src/utils/utils.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Ouvre les commentaires comme un bottom sheet style Facebook
// ─────────────────────────────────────────────────────────────────────────────
void showCommentsSheet(BuildContext context, Post post) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CommentsPage(post: post),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Constantes de design
// ─────────────────────────────────────────────────────────────────────────────
const _kDarkBg = Color(0xFF0A0E27);
const _kDarkCard = Color(0xFF1A1F3D);
const _kDarkDivider = Color(0xFF2A2F50);
const _kAccent = Color(0xFF1877F2); // bleu Facebook

const Map<String, String> _reactionEmoji = {
  'like': '👍',
  'love': '❤️',
  'haha': '😂',
  'wow': '😮',
  'sad': '😢',
  'angry': '😡',
};

// ─────────────────────────────────────────────────────────────────────────────
// Widget principal
// ─────────────────────────────────────────────────────────────────────────────
class CommentsPage extends StatefulWidget {
  final Post post;
  const CommentsPage({super.key, required this.post});

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final PostService _postService = PostService();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool isPosting = false;
  bool _hasText = false;
  String _currentUserName = 'Utilisateur';
  String _currentUserAvatar = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _commentController.addListener(() {
      final hasText = _commentController.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  Future<void> _loadCurrentUser() async {
    final uid = _postService.currentUserId;
    if (uid == null) return;
    try {
      final firestore = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'native-db',
      );
      final doc = await firestore.collection('users').doc(uid).get();
      final data = doc.data();
      setState(() {
        _currentUserName = data?['name'] ??
            data?['displayName'] ??
            FirebaseAuth.instance.currentUser?.displayName ??
            'Utilisateur';
        _currentUserAvatar = data?['photo'] ??
            data?['photoURL'] ??
            FirebaseAuth.instance.currentUser?.photoURL ??
            '';
      });
    } catch (_) {
      final authUser = FirebaseAuth.instance.currentUser;
      setState(() {
        _currentUserName = authUser?.displayName ?? 'Utilisateur';
        _currentUserAvatar = authUser?.photoURL ?? '';
      });
    }
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || widget.post.id == null) return;
    setState(() => isPosting = true);
    try {
      await _postService.addComment(postId: widget.post.id!, text: text);
      _commentController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isPosting = false);
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    if (widget.post.id == null || comment.id == null) return;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isLight ? Colors.white : _kDarkCard,
        title: Text('Supprimer ?',
            style: TextStyle(color: isLight ? Colors.black : Colors.white)),
        content: Text('Ce commentaire sera définitivement supprimé.',
            style: TextStyle(
                color: isLight ? Colors.black54 : Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler',
                style: TextStyle(
                    color: isLight ? Colors.black54 : Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _postService.deleteComment(
          commentId: comment.id!, postId: widget.post.id!);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bg = isLight ? Colors.white : _kDarkBg;
    final cardBg = isLight ? const Color(0xFFF0F2F5) : _kDarkCard;
    final textColor = isLight ? const Color(0xFF050505) : Colors.white;
    final subText = isLight ? Colors.black45 : Colors.grey[500]!;
    final divColor = isLight ? Colors.grey[200]! : _kDarkDivider;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH * 0.92,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        children: [
          // ── Drag handle ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isLight ? Colors.grey[300] : Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Titre ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close,
                      color: isLight ? Colors.black54 : Colors.white70,
                      size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'Commentaires',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),

          Divider(color: divColor, height: 1),

          // ── Barre réactions + partages ────────────────────────────────────
          _ReactionsBar(
              post: widget.post,
              isLight: isLight,
              textColor: textColor,
              subText: subText,
              divColor: divColor),

          // ── Filtre "Plus pertinent" ───────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Text('Plus pertinent',
                    style: TextStyle(
                        color: subText,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                Icon(Icons.keyboard_arrow_down, color: subText, size: 18),
              ],
            ),
          ),

          // ── Liste des commentaires ────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<Comment>>(
              stream: _postService.getCommentsStream(widget.post.id!),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Text('Erreur de chargement',
                        style: TextStyle(color: Colors.red[300])),
                  );
                }
                final comments = snap.data ?? [];
                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 52, color: Colors.grey[600]),
                        const SizedBox(height: 12),
                        Text('Aucun commentaire',
                            style:
                                TextStyle(color: subText, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text('Soyez le premier à commenter !',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: comments.length,
                  itemBuilder: (_, i) => _CommentTile(
                    comment: comments[i],
                    isLight: isLight,
                    textColor: textColor,
                    subText: subText,
                    cardBg: cardBg,
                    isOwn: comments[i].userId == currentUserId,
                    onDelete: () => _deleteComment(comments[i]),
                    postService: _postService,
                    currentUserId: currentUserId,
                  ),
                );
              },
            ),
          ),

          Divider(color: divColor, height: 1),

          // ── Input style Facebook ──────────────────────────────────────────
          _CommentInputBar(
            controller: _commentController,
            focusNode: _focusNode,
            isLight: isLight,
            bg: bg,
            cardBg: cardBg,
            textColor: textColor,
            subText: subText,
            currentUserName: _currentUserName,
            currentUserAvatar: _currentUserAvatar,
            hasText: _hasText,
            isPosting: isPosting,
            onSend: _postComment,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Barre réactions et partages
// ─────────────────────────────────────────────────────────────────────────────
class _ReactionsBar extends StatelessWidget {
  final Post post;
  final bool isLight;
  final Color textColor;
  final Color subText;
  final Color divColor;

  const _ReactionsBar({
    required this.post,
    required this.isLight,
    required this.textColor,
    required this.subText,
    required this.divColor,
  });

  @override
  Widget build(BuildContext context) {
    if (post.likes == 0 && post.shares == 0) return const SizedBox();

    // Trouver les 2 émojis les plus utilisés
    final reactionCounts = <String, int>{};
    post.reactions.forEach((_, type) {
      reactionCounts[type] = (reactionCounts[type] ?? 0) + 1;
    });
    final topEmojis = (reactionCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(2)
        .map((e) => _reactionEmoji[e.key] ?? '👍')
        .toList();
    if (topEmojis.isEmpty && post.likes > 0) topEmojis.add('👍');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            // Bulles emoji imbriquées
            SizedBox(
              width: topEmojis.length * 18.0 + 6,
              height: 22,
              child: Stack(
                children: List.generate(topEmojis.length, (i) {
                  return Positioned(
                    left: i * 16.0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _kAccent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isLight ? Colors.white : _kDarkBg,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                          child: Text(topEmojis[i],
                              style: const TextStyle(fontSize: 11))),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 4),
            if (post.likes > 0)
              Text(_formatCount(post.likes),
                  style: TextStyle(color: subText, fontSize: 13)),
          ]),
          if (post.shares > 0)
            Text('${_formatCount(post.shares)} partages',
                style: TextStyle(color: subText, fontSize: 13)),
        ],
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tuile d'un commentaire
// ─────────────────────────────────────────────────────────────────────────────
class _CommentTile extends StatefulWidget {
  final Comment comment;
  final bool isLight;
  final Color textColor;
  final Color subText;
  final Color cardBg;
  final bool isOwn;
  final VoidCallback onDelete;
  final PostService postService;
  final String? currentUserId;

  const _CommentTile({
    required this.comment,
    required this.isLight,
    required this.textColor,
    required this.subText,
    required this.cardBg,
    required this.isOwn,
    required this.onDelete,
    required this.postService,
    required this.currentUserId,
  });

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  bool _hasLiked = false;
  int _likes = 0;

  @override
  void initState() {
    super.initState();
    _likes = widget.comment.likes;
    _hasLiked = widget.currentUserId != null &&
        widget.comment.likedBy.contains(widget.currentUserId);
  }

  Future<void> _toggleLike() async {
    if (widget.comment.id == null) return;
    if (_hasLiked) {
      await widget.postService.unlikeComment(widget.comment.id!);
      setState(() {
        _hasLiked = false;
        _likes = (_likes - 1).clamp(0, 9999999);
      });
    } else {
      await widget.postService.likeComment(widget.comment.id!);
      setState(() {
        _hasLiked = true;
        _likes++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar ───────────────────────────────────────────────────────
          _UserAvatar(
              imageUrl: comment.userAvatar,
              name: comment.userName,
              radius: 18),
          const SizedBox(width: 8),

          // ── Bulle + actions ──────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bulle
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: widget.cardBg,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(comment.userName,
                              style: TextStyle(
                                  color: widget.textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5)),
                          const SizedBox(height: 3),
                          Text(comment.text,
                              style: TextStyle(
                                  color: widget.textColor, fontSize: 14)),
                        ],
                      ),
                    ),
                    // Badge likes du commentaire
                    if (_likes > 0)
                      Positioned(
                        right: 4,
                        bottom: -10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: widget.isLight
                                ? Colors.white
                                : _kDarkBg,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 2,
                                  offset: Offset(0, 1))
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('👍',
                                  style: TextStyle(fontSize: 11)),
                              if (_likes > 1) ...[
                                const SizedBox(width: 2),
                                Text('$_likes',
                                    style: TextStyle(
                                        color: widget.subText,
                                        fontSize: 11)),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                // ── Ligne d'actions ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Row(
                    children: [
                      Text(comment.elapsedTime,
                          style: TextStyle(
                              color: widget.subText, fontSize: 12)),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: _toggleLike,
                        child: Text(
                          'J\'aime',
                          style: TextStyle(
                            color: _hasLiked
                                ? _kAccent
                                : widget.subText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text('Répondre',
                          style: TextStyle(
                              color: widget.subText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      const Spacer(),
                      if (widget.isOwn)
                        GestureDetector(
                          onTap: widget.onDelete,
                          child: Icon(Icons.more_horiz,
                              color: widget.subText, size: 18),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Barre de saisie style Facebook
// ─────────────────────────────────────────────────────────────────────────────
class _CommentInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLight;
  final Color bg;
  final Color cardBg;
  final Color textColor;
  final Color subText;
  final String currentUserName;
  final String currentUserAvatar;
  final bool hasText;
  final bool isPosting;
  final VoidCallback onSend;

  const _CommentInputBar({
    required this.controller,
    required this.focusNode,
    required this.isLight,
    required this.bg,
    required this.cardBg,
    required this.textColor,
    required this.subText,
    required this.currentUserName,
    required this.currentUserAvatar,
    required this.hasText,
    required this.isPosting,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomPad),
      duration: const Duration(milliseconds: 100),
      child: Container(
        color: bg,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar utilisateur courant
            _UserAvatar(
                imageUrl: currentUserAvatar,
                name: currentUserName,
                radius: 18),
            const SizedBox(width: 8),

            // Champ de texte
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(22),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        style: TextStyle(color: textColor, fontSize: 14),
                        maxLines: 5,
                        minLines: 1,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          hintText:
                              'Commenter en tant que $currentUserName…',
                          hintStyle:
                              TextStyle(color: subText, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    // Bouton envoyer (apparaît quand du texte est saisi)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: hasText
                          ? GestureDetector(
                              key: const ValueKey('send'),
                              onTap: isPosting ? null : onSend,
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(left: 6, bottom: 8),
                                child: isPosting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: _kAccent),
                                      )
                                    : const Icon(Icons.send_rounded,
                                        color: _kAccent, size: 22),
                              ),
                            )
                          : const SizedBox(key: ValueKey('empty')),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar générique (URL http ou initiale)
// ─────────────────────────────────────────────────────────────────────────────
class _UserAvatar extends StatelessWidget {
  final String imageUrl;
  final String name;
  final double radius;

  const _UserAvatar(
      {required this.imageUrl, required this.name, required this.radius});

  @override
  Widget build(BuildContext context) {
    final hasUrl = imageUrl.isNotEmpty && imageUrl.startsWith('http');
    return CircleAvatar(
      radius: radius,
      backgroundColor: avatarColorForInitial(name),
      backgroundImage:
          hasUrl ? CachedNetworkImageProvider(imageUrl) : null,
      child: !hasUrl
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            )
          : null,
    );
  }
}

