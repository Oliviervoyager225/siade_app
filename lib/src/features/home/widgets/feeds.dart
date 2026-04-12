import 'package:flutter/material.dart';
import 'package:siade2/src/features/home/widgets/widgets.dart';
import 'package:siade2/src/theme/colors/app_colors.dart';
import 'package:siade2/src/core/services/post_service.dart';
import 'package:siade2/src/features/socialnetwork/pages/create_post_page.dart';
import '../../../commons/data/models.dart';

class FeedRefresh extends StatefulWidget {
  const FeedRefresh({super.key});

  @override
  State<FeedRefresh> createState() => FeedRefreshState();
}

class FeedRefreshState extends State<FeedRefresh> {
  // Changer cette clé force la reconstruction du StreamBuilder → nouveau stream
  Key _streamKey = UniqueKey();

  void refresh() {
    setState(() => _streamKey = UniqueKey());
  }

  @override
  Widget build(BuildContext context) => Feed(key: _streamKey);
}

class Feed extends StatefulWidget {
  const Feed({super.key});

  @override
  State<Feed> createState() => _FeedState();
}

class _FeedState extends State<Feed> {
  final PostService _postService = PostService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Post>>(
      stream: _postService.getPostsStream(),
      builder: (context, snapshot) {
        // État de chargement
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Gestion des erreurs
        if (snapshot.hasError) {
          final err = snapshot.error.toString();
          return Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    err,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        // Aucun post disponible
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreatePostScreen(),
                  ),
                );
              },
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.post_add, size: 48, color: Colors.grey),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Aucune publication',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Soyez le premier à publier!',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF60438C), Color(0xFFF62E8E)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Créer un post',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Affichage des posts
        final posts = snapshot.data!;
        return Column(
          children: posts.map((post) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Posts(post: post),
                ),
                const Divider(color: AppColors.darkGrey, height: 10),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}
