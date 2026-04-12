import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:siade2/src/core/services/post_service.dart';
import 'package:siade2/src/commons/data/models/posts.dart';
import 'package:siade2/src/features/home/pages/comments_page.dart';
import 'package:siade2/src/utils/utils.dart';

const _kDarkBg = Color(0xFF0A0E27);
const _kDarkCard = Color(0xFF1A1F3D);
const _kDarkDivider = Color(0xFF2A2F50);
const _kGrey = Color(0xFF8A8FA8);
const _kAccent = Color(0xFF1877F2);

IconData _reactionIconFilled(String? r) {
  switch (r) {
    case 'love': return Icons.favorite;
    case 'haha': return Icons.sentiment_very_satisfied;
    case 'wow': return Icons.sentiment_satisfied;
    case 'sad': return Icons.sentiment_dissatisfied;
    case 'angry': return Icons.mood_bad;
    default: return Icons.thumb_up;
  }
}

IconData _reactionIconOutline(String? r) {
  switch (r) {
    case 'love': return Icons.favorite_border;
    case 'haha': return Icons.sentiment_very_satisfied_outlined;
    case 'wow': return Icons.sentiment_satisfied_outlined;
    case 'sad': return Icons.sentiment_dissatisfied_outlined;
    case 'angry': return Icons.mood_bad_outlined;
    default: return Icons.thumb_up_outlined;
  }
}

Color _reactionActiveColor(String? r) {
  switch (r) {
    case 'love': return Colors.red;
    case 'haha': return const Color(0xFFF7B500);
    case 'wow': return const Color(0xFFF7B500);
    case 'sad': return const Color(0xFF4A90E2);
    case 'angry': return const Color(0xFFE05A00);
    default: return Colors.red;
  }
}

class Posts extends StatefulWidget {
  final Post post;
  const Posts({super.key, required this.post});
  @override
  State<Posts> createState() => _PostsState();
}

class _PostsState extends State<Posts> with SingleTickerProviderStateMixin {
  late Post post;
  final PostService _postService = PostService();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  bool _isLiked = false;
  String? _myReaction;
  bool _isSaved = false;
  bool _isProcessing = false;

  OverlayEntry? _pickerOverlay;
  final _likeKey = GlobalKey();
  final _pickerKey = GlobalKey();
  final _hoveredNotifier = ValueNotifier<String?>(null);

  late AnimationController _pickerAnim;
  late Animation<double> _pickerScale;

  final PageController _pageCtrl = PageController();
  int _imgIndex = 0;

  @override
  void initState() {
    super.initState();
    post = widget.post;
    _isLiked = _uid != null && post.likedBy.contains(_uid);
    _myReaction = _uid != null ? post.reactions[_uid] : null;
    _isSaved = post.isSaved;
    _pickerAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _pickerScale = CurvedAnimation(parent: _pickerAnim, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(Posts oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync depuis le stream Firestore si aucune action locale en cours
    if (!_isProcessing && widget.post.id == oldWidget.post.id) {
      final incoming = widget.post;
      setState(() {
        post        = incoming;
        _isLiked    = _uid != null && incoming.likedBy.contains(_uid);
        _myReaction = _uid != null ? incoming.reactions[_uid] : null;
        _isSaved    = incoming.isSaved;
      });
    }
  }

  @override
  void dispose() {
    _pickerOverlay?.remove();
    _pickerOverlay = null;
    _hoveredNotifier.dispose();
    _pickerAnim.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _showPicker() {
    if (_pickerOverlay != null) return;
    // Capture la position du bouton avant de créer l'overlay
    final box = _likeKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;
    // Picker width ≈ 6 * 44 + 20 padding = 284
    final left = (pos.dx - 8).clamp(0.0, screenWidth - 290.0);
    final top = pos.dy - 78;

    _pickerAnim.forward();

    _pickerOverlay = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // Barrière transparente — ferme le picker si on tape ailleurs
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closePicker,
            ),
          ),
          // Picker positionné au-dessus du bouton
          Positioned(
            left: left,
            top: top,
            child: Material(
              color: Colors.transparent,
              child: ScaleTransition(
                scale: _pickerScale,
                alignment: Alignment.bottomLeft,
                child: ValueListenableBuilder<String?>(
                  valueListenable: _hoveredNotifier,
                  builder: (_, hovered, __) => _ReactionPicker(
                    key: _pickerKey,
                    onPick: _pickReaction,
                    current: _myReaction,
                    hovered: hovered,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_pickerOverlay!);
  }

  void _closePicker() {
    _pickerAnim.reverse().then((_) {
      _pickerOverlay?.remove();
      _pickerOverlay = null;
      _hoveredNotifier.value = null;
    });
  }

  void _updateHover(Offset globalPosition) {
    if (_pickerOverlay == null) return;
    final box = _pickerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final origin = box.localToGlobal(Offset.zero);
    final size = box.size;
    final inBounds = globalPosition.dx >= origin.dx &&
        globalPosition.dx <= origin.dx + size.width &&
        globalPosition.dy >= origin.dy &&
        globalPosition.dy <= origin.dy + size.height;
    if (!inBounds) {
      if (_hoveredNotifier.value != null) _hoveredNotifier.value = null;
      return;
    }
    const reactions = ['like', 'love', 'haha', 'wow', 'sad', 'angry'];
    final localX = globalPosition.dx - origin.dx;
    final idx = (localX / (size.width / reactions.length)).floor().clamp(0, reactions.length - 1);
    final hovered = reactions[idx];
    if (_hoveredNotifier.value != hovered) _hoveredNotifier.value = hovered;
  }

  Future<void> _tapLike() async {
    if (_isProcessing) return;
    // Si le picker est visible, on le ferme
    if (_pickerOverlay != null) { _closePicker(); return; }
    // Si déjà réagi → retire la réaction (un seul tap = unlike)
    if (_isLiked) {
      setState(() => _isProcessing = true);
      await _postService.removeReaction(post.id!);
      setState(() {
        _isLiked = false;
        _myReaction = null;
        post.likes = (post.likes - 1).clamp(0, 999999);
        post.likedBy.remove(_uid);
        if (_uid != null) post.reactions.remove(_uid);
        _isProcessing = false;
      });
    } else {
      // Pas encore réagi → like immédiat (👍), comme Facebook
      // L'appui long ouvre le picker de réactions (déjà géré par onLongPress)
      await _pickReaction('like');
    }
  }

  Future<void> _pickReaction(String reaction) async {
    _closePicker();
    if (_isProcessing || _uid == null) return;
    setState(() => _isProcessing = true);
    if (_myReaction == reaction) {
      await _postService.removeReaction(post.id!);
      setState(() {
        _isLiked = false;
        _myReaction = null;
        post.likes = (post.likes - 1).clamp(0, 999999);
        post.likedBy.remove(_uid);
        post.reactions.remove(_uid);
      });
    } else {
      await _postService.reactToPost(post.id!, reaction);
      setState(() {
        final wasLiked = _isLiked;
        _isLiked = true;
        _myReaction = reaction;
        if (!wasLiked) {
          post.likes++;
          if (!post.likedBy.contains(_uid)) post.likedBy.add(_uid);
        }
        post.reactions[_uid] = reaction;
      });
    }
    setState(() => _isProcessing = false);
  }

  Future<void> _toggleSave() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    if (_isSaved) {
      await _postService.unsavePost(post.id!);
    } else {
      await _postService.savePost(post.id!);
    }
    setState(() { _isSaved = !_isSaved; _isProcessing = false; });
  }

  void _openMenu(BuildContext context) {
    final isOwner = _uid == post.userId;
    showModalBottomSheet(
      context: context,
      backgroundColor: _kDarkCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const _Handle(),
          ListTile(
            leading: const Icon(Icons.repeat, color: Colors.white),
            title: const Text('Partager sur votre fil', style: TextStyle(color: Colors.white)),
            onTap: () { Navigator.pop(context); _openRepostSheet(context); },
          ),
          ListTile(
            leading: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border, color: Colors.white),
            title: Text(_isSaved ? 'Retirer des favoris' : 'Enregistrer', style: const TextStyle(color: Colors.white)),
            onTap: () { Navigator.pop(context); _toggleSave(); },
          ),
          if (isOwner)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Supprimer', style: TextStyle(color: Colors.redAccent)),
              onTap: () { Navigator.pop(context); _askDelete(context); },
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _openRepostSheet(BuildContext context) {
    // Étape 1 : menu de choix (comme Facebook)
    showModalBottomSheet(
      context: context,
      backgroundColor: _kDarkCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (menuCtx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Handle(),
          const SizedBox(height: 4),
          // Option 1 : Partager maintenant (sans commentaire)
          ListTile(
            leading: const Icon(Icons.repeat_rounded, color: Colors.white),
            title: const Text('Partager maintenant',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: const Text('Partagez immédiatement sur votre fil',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            onTap: () async {
              Navigator.pop(menuCtx);
              await _postService.sharePost(post.id!);
              setState(() => post.shares++);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post partagé !')));
              }
            },
          ),
          const Divider(color: Colors.white12, height: 1),
          // Option 2 : Écrire un post (avec texte)
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: Colors.white),
            title: const Text('Écrire un post',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: const Text('Ajoutez quelque chose avant de partager',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            onTap: () {
              Navigator.pop(menuCtx);
              _openWritePostSheet(context);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _openWritePostSheet(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kDarkCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const _Handle(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Partager sur votre fil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: ctrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Dites quelque chose...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                filled: true,
                fillColor: _kDarkBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _OriginalCard(post: post),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _kAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _postService.repostPost(originalPostId: post.id!, comment: ctrl.text.trim().isEmpty ? null : ctrl.text.trim());
                  setState(() => post.shares++);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post partagé !')));
                  }
                },
                child: const Text('Partager', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  void _askDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kDarkCard,
        title: const Text('Supprimer ce post ?', style: TextStyle(color: Colors.white)),
        content: const Text('Cette action est irréversible.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler', style: TextStyle(color: Colors.white70))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _postService.deletePost(post.id!);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post supprimé')));
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: _kDarkCard,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildHeader(context),
        if (post.resharedFrom != null) _buildRepostBanner(),
        if (post.postLegend.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(post.postLegend, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
          ),
        if (post.postImages.isNotEmpty) _buildImages(),
        if (post.resharedFrom != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: _OriginalCard(resharedData: post.resharedFrom!),
          ),
        _buildActionBar(context),
      ]),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 4),
      child: Row(children: [
        _PostAvatar(imageUrl: post.imagePoster, name: post.namePoster),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(post.namePoster, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            Text(post.elapsedTime, style: const TextStyle(color: _kGrey, fontSize: 12)),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.more_horiz, color: Colors.white70),
          onPressed: () => _openMenu(context),
        ),
      ]),
    );
  }

  Widget _buildRepostBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(children: const [
        Icon(Icons.repeat, size: 13, color: _kGrey),
        SizedBox(width: 4),
        Text('A partagé une publication', style: TextStyle(color: _kGrey, fontSize: 12)),
      ]),
    );
  }

  Widget _buildImages() {
    final imgs = post.postImages;
    if (imgs.length == 1) return _NetImage(url: imgs[0], height: 260);
    return Stack(children: [
      SizedBox(
        height: 260,
        child: PageView.builder(
          controller: _pageCtrl,
          itemCount: imgs.length,
          onPageChanged: (i) => setState(() => _imgIndex = i),
          itemBuilder: (_, i) => _NetImage(url: imgs[i], height: 260),
        ),
      ),
      Positioned(
        bottom: 8, right: 12,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
          child: Text('${_imgIndex + 1}/${imgs.length}', style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ),
    ]);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Format compact : 1 200 → 1.2K, 1 200 000 → 1.2M
  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(n % 1000000 == 0 ? 0 : 1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
    return '$n';
  }

  // ── Barre d'actions (UI originale + compteurs temps réel) ────────────────
  Widget _buildActionBar(BuildContext context) {
    final activeIcon  = _isLiked ? _reactionIconFilled(_myReaction)  : _reactionIconOutline(null);
    final activeColor = _isLiked ? _reactionActiveColor(_myReaction) : _kGrey;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(children: [
            // ── J'aime (tap = picker / appui long + slide = sélection directe) ─
            GestureDetector(
              key: _likeKey,
              onLongPress: _showPicker,
              onLongPressMoveUpdate: (d) => _updateHover(d.globalPosition),
              onLongPressEnd: (d) {
                final hovered = _hoveredNotifier.value;
                if (hovered != null) {
                  _pickReaction(hovered);
                }
              },
              child: InkWell(
                onTap: _tapLike,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(activeIcon, color: activeColor, size: 22),
                ),
              ),
            ),
            if (post.likes > 0) ...[
              const SizedBox(width: 2),
              Text(_fmt(post.likes), style: const TextStyle(color: _kGrey, fontSize: 13)),
            ],
            const Spacer(),
            // ── Commentaires ──────────────────────────────────────────────
            InkWell(
              onTap: () => showCommentsSheet(context, post),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.chat_bubble_outline, color: _kGrey, size: 20),
                  if (post.commentsNumber > 0) ...[
                    const SizedBox(width: 4),
                    Text(_fmt(post.commentsNumber), style: const TextStyle(color: _kGrey, fontSize: 13)),
                  ],
                ]),
              ),
            ),
            const SizedBox(width: 8),
            // ── Partager ──────────────────────────────────────────────────
            InkWell(
              onTap: () => _openRepostSheet(context),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.upload_outlined, color: _kGrey, size: 20),
                  if (post.shares > 0) ...[
                    const SizedBox(width: 4),
                    Text(_fmt(post.shares), style: const TextStyle(color: _kGrey, fontSize: 13)),
                  ],
                ]),
              ),
            ),
            const SizedBox(width: 8),
            // ── Enregistrer ───────────────────────────────────────────────
            InkWell(
              onTap: _toggleSave,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  _isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: _isSaved ? _kAccent : _kGrey,
                  size: 20,
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

class _ReactionPicker extends StatelessWidget {
  final void Function(String) onPick;
  final String? current;
  final String? hovered;
  const _ReactionPicker({super.key, required this.onPick, this.current, this.hovered});

  static const _reactions = ['like', 'love', 'haha', 'wow', 'sad', 'angry'];
  static const _emojis   = ['👍',   '❤️',   '😂',   '😮',   '😢',   '😡'];
  static const _labels   = ['J\'aime', 'J\'adore', 'Haha', 'Wow', 'Triste', 'Grrr'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3D),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))],
        border: Border.all(color: _kDarkDivider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_reactions.length, (i) {
          final r = _reactions[i];
          final emoji = _emojis[i];
          final label = _labels[i];
          final isHighlighted = hovered == r || (hovered == null && current == r);
          return GestureDetector(
            onTap: () => onPick(r),
            child: SizedBox(
              width: 44,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: isHighlighted ? 1.5 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    child: AnimatedPadding(
                      padding: EdgeInsets.only(bottom: isHighlighted ? 6 : 0),
                      duration: const Duration(milliseconds: 150),
                      child: Text(emoji, style: const TextStyle(fontSize: 26)),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: isHighlighted ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: Text(
                      label,
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _PostAvatar extends StatelessWidget {
  final String imageUrl;
  final String name;
  const _PostAvatar({required this.imageUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('http')) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: CachedNetworkImageProvider(imageUrl),
        backgroundColor: _kDarkDivider,
      );
    }
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 20,
      backgroundColor: avatarColorForInitial(name),
      child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}

class _OriginalCard extends StatelessWidget {
  final Post? post;
  final Map<String, dynamic>? resharedData;
  const _OriginalCard({this.post, this.resharedData});

  @override
  Widget build(BuildContext context) {
    final name = post?.namePoster ?? (resharedData?['originalUserName'] as String? ?? '');
    final avatar = post?.imagePoster ?? (resharedData?['originalUserAvatar'] as String? ?? '');
    final text = post?.postLegend ?? (resharedData?['originalLegend'] as String? ?? '');
    final imgs = post?.postImages ?? List<String>.from(resharedData?['originalImages'] as List? ?? []);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _kDarkDivider),
        borderRadius: BorderRadius.circular(10),
        color: _kDarkBg,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            _PostAvatar(imageUrl: avatar, name: name),
            const SizedBox(width: 8),
            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
        ),
        if (text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        if (imgs.isNotEmpty)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
            child: _NetImage(url: imgs[0], height: 150),
          ),
      ]),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Container(
          width: 36, height: 4,
          decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2)),
        ),
      ),
    );
  }
}

class _NetImage extends StatelessWidget {
  final String url;
  final double height;
  const _NetImage({required this.url, required this.height});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(height: height, color: _kDarkDivider),
      errorWidget: (_, __, ___) => Container(
        height: height, color: _kDarkDivider,
        child: const Icon(Icons.broken_image, color: Colors.white30),
      ),
    );
  }
}
