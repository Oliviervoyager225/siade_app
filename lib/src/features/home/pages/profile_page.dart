import 'dart:io';
import 'package:siade2/src/commons/widgets/optimized_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siade2/src/commons/data/models.dart';
import 'package:siade2/src/features/home/pages/pages.dart';
import 'package:siade2/src/features/home/widgets/widgets.dart';
import 'package:siade2/src/theme/colors/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:siade2/src/providers/providers.dart';
import 'package:sizer/sizer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:siade2/src/core/services/post_service.dart';
import 'package:siade2/src/utils/utils.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final double bannerHeight = 200.0;
  final double photoProfileBoxSize = 150.0;

  double get photoProfileSize => photoProfileBoxSize * 0.95;

  double get topBox => bannerHeight - photoProfileBoxSize / 2;
  double get topPhotProfile => bannerHeight - photoProfileSize / 2;

  late TabController _tabController;
  File? _pickedImage;
  bool _isUploading = false;

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    final file = File(picked.path);
    setState(() {
      _pickedImage = file;
      _isUploading = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Utilisateur non connecté');

      // Nom unique avec timestamp → garantit une nouvelle URL à chaque upload
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = FirebaseStorage.instance
          .ref()
          .child('users/$uid/profile_$timestamp.jpg');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      if (mounted) {
        await context.read<UserProvider>().updatePhotoURL(url);
        setState(() {
          _pickedImage = null;
          _isUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pickedImage = null;
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur upload photo : $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      backgroundColor: isLight ? Colors.white : null,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 100.w,
                  height: bannerHeight + 100,
                  color: Colors.transparent,
                ),

                Positioned(
                  top: 0,
                  child: Container(
                    width: 100.w,
                    height: bannerHeight,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("assets/images/profile_banner.jpg"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  left: 30,
                  top: MediaQuery.of(context).padding.top + 12,
                  child: GestureDetector(
                    onTap: () async {
                      final popped = await Navigator.maybePop(context);
                      if (!popped && context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const HomePage()),
                        );
                      }
                    },
                    child: Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: bannerHeight - 60,
                  child: GestureDetector(
                    onTap: _pickAndUploadPhoto,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF07026F), Color(0xFFA01E38)],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: _isUploading
                                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                                : Consumer<UserProvider>(
                                    builder: (context, userProvider, _) {
                                      final user = userProvider.user;
                                      final photoURL = user?['photoURL'] as String?;
                                      final displayName = user?['username'] ?? user?['name'] ?? 'Utilisateur';
                                      
                                      if (_pickedImage != null) {
                                        return Image.file(_pickedImage!, fit: BoxFit.cover);
                                      }
                                      
                                      return OptimizedAvatar(
                                        imageUrl: photoURL,
                                        fallbackText: displayName,
                                        radius: 60,
                                      );
                                    },
                                  ),
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(0, 10),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Edit Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      final user = userProvider.user;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user?['username'] ?? user?['name'] ?? 'Utilisateur',
                            style: TextStyle(
                              color: isLight ? Color(0xFF60438C) : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18.sp,
                            ),
                          ),
                          Text(
                            (user?['poste'] ?? 'Visiteur').toString(),
                            style: TextStyle(
                              color: isLight ? Colors.black54 : AppColors.greySecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  Positioned(
                    right: 25.w,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mail_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 30)),

          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 25.0),
              padding: EdgeInsets.all(20.0),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF60438C), Color(0xFF60438C)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Des profils',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      _RecentInteractedAvatars(),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileInfosPage(),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Image.asset(
                        "assets/images/qr_code.png",
                        height: 60,
                        width: 60,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 30)),

          SliverPersistentHeader(
            pinned: true,
            delegate: SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: 'Posts'),
                  Tab(text: 'Mes activités'),
                  Tab(text: 'sessions suivies'),
                ],
                labelColor: isLight ? Color(0xFF60438C) : AppColors.primarySocialBlue,
                unselectedLabelColor: isLight ? Colors.black45 : Colors.white,
                indicatorColor: isLight ? Color(0xFF60438C) : AppColors.primarySocialBlue,
                indicatorWeight: 3,
                labelStyle: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              isLight: isLight,
            ),
          ),
        ],
        body: Container(
          color: isLight ? Colors.white : null,
          child: TabBarView(
            controller: _tabController,
            children: [
              SingleChildScrollView(child: Feed()),
              _UserActivityTab(),
              _SessionsSuiviesTab(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mes activités tab ─────────────────────────────────────────────────────────

class _UserActivityTab extends StatelessWidget {
  const _UserActivityTab();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isLight = Theme.of(context).brightness == Brightness.light;

    if (uid == null) {
      return Center(
        child: Text(
          'Connectez-vous pour voir vos activités.',
          style: TextStyle(color: isLight ? Colors.black54 : Colors.white54),
        ),
      );
    }

    return StreamBuilder<List<Post>>(
      stream: PostService().getUserInteractedPostsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.dynamic_feed_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  'Aucune activité pour l\'instant.',
                  style: TextStyle(color: isLight ? Colors.black54 : Colors.white54),
                ),
                const SizedBox(height: 6),
                Text(
                  'Les posts que vous aimez, commentez ou partagez\napparaissent ici (10 derniers jours).',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isLight ? Colors.black38 : Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          child: Column(
            children: snapshot.data!
                .map((post) => Column(
                      children: [
                        _ActivityBadge(post: post, uid: uid),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Posts(post: post),
                        ),
                        const Divider(color: AppColors.darkGrey, height: 10),
                      ],
                    ))
                .toList(),
          ),
        );
      },
    );
  }
}

class _ActivityBadge extends StatelessWidget {
  final Post post;
  final String uid;
  const _ActivityBadge({required this.post, required this.uid});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    IconData icon;
    String label;
    Color color;

    if (post.resharedFrom != null && post.userId == uid) {
      icon = Icons.repeat;
      label = 'Republié';
      color = Colors.blue;
    } else if (post.userId == uid) {
      icon = Icons.edit_outlined;
      label = 'Publié';
      color = const Color(0xFF7C4DFF);
    } else {
      icon = Icons.comment_outlined;
      label = 'Commenté';
      color = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 6, bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sessions suivies tab ───────────────────────────────────────────────────────

class _SessionsSuiviesTab extends StatelessWidget {
  const _SessionsSuiviesTab();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Consumer<FavoritesProvider>(
      builder: (context, favs, _) {
        final all = [
          ...favs.favoritePrograms,
          ...favs.favoriteSpeakers,
          ...favs.favoriteExponents,
        ];

        if (all.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite_border, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  'Aucun favori pour l\'instant.',
                  style: TextStyle(color: isLight ? Colors.black54 : Colors.white54),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          itemCount: all.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = all[index];
            final type = item['type'] as String? ?? '';
            final name = (item['title'] ?? item['name'] ?? '') as String;
            final job = (item['job'] ?? item['room'] ?? '') as String;
            final imageUrl = (item['imageUrl'] ?? '') as String;

            IconData typeIcon;
            if (type == 'program') {
              typeIcon = Icons.event_note;
            } else if (type == 'speaker') {
              typeIcon = Icons.mic;
            } else {
              typeIcon = Icons.store;
            }

            return Container(
              decoration: BoxDecoration(
                color: isLight ? Colors.white : Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                boxShadow: isLight
                    ? [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))]
                    : [],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: imageUrl.startsWith('http')
                        ? Image.network(imageUrl, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Icon(typeIcon, size: 28, color: Colors.grey))
                        : imageUrl.isNotEmpty
                            ? Image.asset(imageUrl, fit: BoxFit.cover)
                            : Icon(typeIcon, size: 28, color: Colors.grey),
                  ),
                ),
                title: Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isLight ? Colors.black87 : Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: job.isNotEmpty
                    ? Text(
                        job,
                        style: TextStyle(
                          color: isLight ? Colors.black54 : Colors.white54,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                trailing: Icon(typeIcon, color: Color(0xFF60438C), size: 20),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Recent interacted profiles avatars ────────────────────────────────────────

class _RecentInteractedAvatars extends StatefulWidget {
  @override
  State<_RecentInteractedAvatars> createState() => _RecentInteractedAvatarsState();
}

class _RecentInteractedAvatarsState extends State<_RecentInteractedAvatars> {
  List<_AvatarEntry> _entries = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loaded = true);
      return;
    }

    try {
      final service = PostService();
      final col = service.firestore.collection(service.postsCollection);

      // 1. Posts que j'ai aimés → profil du poster
      //    Pas de orderBy sur un autre champ (évite l'index composite)
      final likedSnap = await col
          .where('likedBy', arrayContains: uid)
          .limit(30)
          .get();

      // 2. Posts que j'ai partagés (simple share) → profil du poster
      final sharedByMeSnap = await col
          .where('sharedBy', arrayContains: uid)
          .limit(30)
          .get();

      // 3. Mes republications (reposts) → profil de l'auteur original
      final repostSnap = await col
          .where('userId', isEqualTo: uid)
          .limit(50)
          .get();

      final map = <String, _AvatarEntry>{};
      final cutoff = DateTime.now().subtract(const Duration(days: 90));

      void _addEntry(String posterId, Map<String, dynamic> d, DateTime date) {
        if (posterId.isEmpty || posterId == uid) return;
        if (date.isBefore(cutoff)) return;
        // Ne remplace que si plus récent
        final existing = map[posterId];
        if (existing == null || date.isAfter(existing.date)) {
          map[posterId] = _AvatarEntry(
            imageUrl: d['imagePoster'] as String? ?? '',
            name: d['namePoster'] as String? ?? '',
            date: date,
          );
        }
      }

      for (final doc in likedSnap.docs) {
        final d = doc.data() as Map<String, dynamic>;
        final date = (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        _addEntry(d['userId'] as String? ?? '', d, date);
      }

      for (final doc in sharedByMeSnap.docs) {
        final d = doc.data() as Map<String, dynamic>;
        final date = (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        _addEntry(d['userId'] as String? ?? '', d, date);
      }

      for (final doc in repostSnap.docs) {
        final d = doc.data() as Map<String, dynamic>;
        final reshared = d['resharedFrom'] as Map<String, dynamic>?;
        if (reshared == null) continue;
        final origId = reshared['originalUserId'] as String? ?? '';
        if (origId.isEmpty || origId == uid) continue;
        final date = (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        if (date.isBefore(cutoff)) continue;
        final existing = map[origId];
        if (existing == null || date.isAfter(existing.date)) {
          map[origId] = _AvatarEntry(
            imageUrl: reshared['originalUserAvatar'] as String? ?? '',
            name: reshared['originalUserName'] as String? ?? '',
            date: date,
          );
        }
      }

      // 4. Favoris speakers & exponents
      if (mounted) {
        final favs = context.read<FavoritesProvider>();
        for (final s in favs.favoriteSpeakers) {
          final key = 'spk_${s['key']}';
          map[key] = _AvatarEntry(
            imageUrl: s['imageUrl'] as String? ?? '',
            name: s['name'] as String? ?? '',
            date: DateTime.now(),
          );
        }
        for (final e in favs.favoriteExponents) {
          final key = 'exp_${e['key']}';
          map[key] = _AvatarEntry(
            imageUrl: e['imageUrl'] as String? ?? '',
            name: e['name'] as String? ?? '',
            date: DateTime.now(),
          );
        }
      }

      // Tri par date décroissante, top 5
      final sorted = map.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      final top5 = sorted.take(5).toList();

      if (mounted) setState(() { _entries = top5; _loaded = true; });
    } catch (e) {
      debugPrint('❌ _RecentInteractedAvatars._load: $e');
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const SizedBox(
        height: 35,
        child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
      );
    }
    if (_entries.isEmpty) {
      return const SizedBox(
        height: 35,
        child: Center(child: Text('—', style: TextStyle(color: Colors.white54, fontSize: 12))),
      );
    }
    return SizedBox(
      height: 35,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _entries.asMap().entries.map((e) {
          final entry = e.value;
          final url = entry.imageUrl;
          return Align(
            widthFactor: 0.7,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: avatarColorForInitial(entry.name),
                backgroundImage: url.startsWith('http') ? NetworkImage(url) : null,
                child: !url.startsWith('http')
                    ? Text(
                        entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AvatarEntry {
  final String imageUrl;
  final String name;
  final DateTime date;
  const _AvatarEntry({required this.imageUrl, required this.name, required this.date});
}

List<String> profiles = [
  "assets/images/profile_1.jpg",
  "assets/images/profile_2.jpg",
  "assets/images/profile_1.jpg",
  "assets/images/profile_2.jpg",
];

class SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isLight;

  SliverTabBarDelegate(this.tabBar, {required this.isLight});

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: isLight ? Colors.white : Colors.black,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
