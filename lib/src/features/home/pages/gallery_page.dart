import 'package:flutter/material.dart';
import 'package:siade2/gen/assets.gen.dart';
import 'package:siade2/src/core/constants/api_constants.dart';
import 'package:siade2/src/core/network/api_client.dart';
import 'package:siade2/src/features/home/pages/pages.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({Key? key}) : super(key: key);

  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final _api = ApiClient();
  List<_GalleryItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGallery();
  }

  Future<void> _loadGallery() async {
    try {
      final response = await _api.get(ApiConstants.gallery);
      final results = response.data['results'] as List<dynamic>? ?? [];
      final items = results
          .where((e) => e['show_on_frontend'] == true)
          .map((e) => _GalleryItem(
                url: e['file'] as String? ?? '',
                title: e['title'] as String? ?? '',
                type: e['media_type'] as String? ?? 'IMAGE',
              ))
          .toList();
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      backgroundColor: isLight ? Colors.white : null,
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 10,
              elevation: 0,
              leadingWidth: 30,
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 16,
                  width: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLight
                        ? const Color(0xFF60438C).withValues(alpha: 0.3)
                        : Colors.black,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
                ),
              ),
              actions: [
                isLight
                    ? Image.asset('assets/images/logo23.png', height: 20)
                    : Assets.images.logo.image(height: 20)
              ],
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 100.w,
                    height: 125,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30.0),
                      gradient: LinearGradient(
                        colors: isLight
                            ? [const Color(0xFF60438C), const Color(0xFF9E87CE)]
                            : [const Color(0xff305481), const Color(0xff08082D)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Galerie SIADE 2026',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Photos et vidéos de l\'événement',
                          style: TextStyle(color: Colors.white, fontSize: 14.sp),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_items.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 64,
                        color: isLight
                            ? const Color(0xFF60438C).withValues(alpha: 0.3)
                            : Colors.white24,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Aucun média disponible',
                        style: TextStyle(
                          color: isLight
                              ? const Color(0xFF60438C).withValues(alpha: 0.5)
                              : Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  childCount: _items.length,
                  (context, index) {
                    final item = _items[index];
                    final isVideo = item.type == 'VIDEO';
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => isVideo
                              ? PreviewVideo(url: item.url)
                              : PreviewImage(image: item.url),
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.grey.shade800,
                              image: DecorationImage(
                                image: NetworkImage(item.url),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          if (isVideo)
                            const Center(
                              child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 40),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                gridDelegate: SliverQuiltedGridDelegate(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  pattern: const [
                    QuiltedGridTile(1, 2),
                    QuiltedGridTile(1, 1),
                    QuiltedGridTile(2, 1),
                    QuiltedGridTile(1, 1),
                    QuiltedGridTile(1, 1),
                    QuiltedGridTile(1, 1),
                    QuiltedGridTile(2, 1),
                    QuiltedGridTile(1, 1),
                    QuiltedGridTile(2, 1),
                    QuiltedGridTile(1, 1),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GalleryItem {
  final String url;
  final String title;
  final String type;
  const _GalleryItem({required this.url, required this.title, required this.type});
}
