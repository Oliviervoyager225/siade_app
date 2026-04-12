import 'package:flutter/material.dart';
import 'package:siade2/src/commons/data/models.dart';
import 'package:siade2/src/theme/theme.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:siade2/src/providers/providers.dart';

class DetailsSpeakers extends StatefulWidget {
  final Speaker speaker;

  const DetailsSpeakers({super.key, required this.speaker});

  @override
  _DetailsSpeakersState createState() => _DetailsSpeakersState();
}

class _DetailsSpeakersState extends State<DetailsSpeakers> {
  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      backgroundColor: isLight ? Colors.white : Colors.black, // Dark background for dark mode, White for light (though covered by gradient)
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                alignment: Alignment.topLeft,
                width: double.infinity,
                height: 350,
                padding: EdgeInsets.all(30),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: widget.speaker.imageUrl.startsWith('http')
                        ? NetworkImage(widget.speaker.imageUrl) as ImageProvider
                        : AssetImage(widget.speaker.imageUrl),
                    fit: BoxFit.cover,
                    colorFilter: isLight ? null : ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.6),
                      BlendMode.color,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isLight 
                        ? [
                            Colors.transparent,
                            Color(0xFF60438C),
                          ] 
                        : [Colors.transparent, Colors.black],
                      stops: isLight ? [0.6, 1.0] : null, // Start gradient lower (60%) and end solid at bottom (100%)
                    ),
                  ),
                ),
              ),

              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 30,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 15.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: isLight
                          ? Color(0xFF60438C).withOpacity(0.3)
                          : Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),

              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                right: 30,
                child: Consumer<FavoritesProvider>(
                  builder: (context, favs, _) {
                    final isFav = favs.isFavoriteSpeaker(widget.speaker);
                    return GestureDetector(
                      onTap: () => favs.toggleSpeaker(widget.speaker),
                      child: Container(
                        width: 15.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: isLight
                              ? Color(0xFF60438C).withOpacity(0.3)
                              : Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.red : Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          Expanded( // Wrap content in expanded to handle scrolling/background if needed, but here it's Column
            child: Container(
              // In light mode, use a gradient background to match the "White text on Purple" design
              decoration: isLight 
                  ? BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF60438C), Color(0xFFDEDEDE)], // Purple to Light Grey
                      ),
                    )
                  : null, 
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.speaker.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                      ),
                    ),
                    Text(
                      widget.speaker.job,
                      style: TextStyle(color: Colors.white, fontSize: 16.sp),
                    ),

                    SizedBox(height: 30),

                    Text(
                      widget.speaker.details,
                      textAlign: TextAlign.justify,
                      style: TextStyle(color: Colors.white, fontSize: 16.sp),
                    ),

                    SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: _buildSocialIcons(widget.speaker, isLight),
                    ),

                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Réseaux sociaux ─────────────────────────────────────────────────────────
// La liste des icônes avec leur URL respective provenant du modèle Speaker.
// Les icônes sans URL sont masquées automatiquement.
List<Widget> _buildSocialIcons(Speaker speaker, bool isLight) {
  final socials = [
    {'asset': 'assets/images/linkedIn.png',  'url': speaker.linkedinUrl},
    {'asset': 'assets/images/facebook.png',  'url': speaker.facebookUrl},
    {'asset': 'assets/images/tiktok.png',    'url': speaker.tiktokUrl},
    {'asset': 'assets/images/instagram.png', 'url': speaker.instagramUrl},
    {'asset': 'assets/images/youtube.png',   'url': speaker.youtubeUrl},
  ];

  return socials
      .where((s) => s['url'] != null)
      .map((s) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () async {
                final uri = Uri.tryParse(s['url'] as String);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFF60438C) : AppColors.backgroundDefault,
                  shape: BoxShape.circle,
                  image: DecorationImage(image: AssetImage(s['asset'] as String)),
                ),
              ),
            ),
          ))
      .toList();
}
