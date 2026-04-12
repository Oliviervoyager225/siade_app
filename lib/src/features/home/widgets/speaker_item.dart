import 'package:flutter/material.dart';
import 'package:siade2/src/commons/data/models.dart';
import 'package:siade2/src/features/home/widgets/details_speakers.dart';
import 'package:siade2/src/theme/theme.dart';

class SpeakerItem extends StatelessWidget {
  final Speaker speaker;

  const SpeakerItem({super.key, required this.speaker});

  ImageProvider _resolveImage(String url) {
    if (url.startsWith('http')) return NetworkImage(url);
    return AssetImage(url);
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailsSpeakers(speaker: speaker)),
      ),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final pillRadius = w / 2;
          final imageHeight = h * 0.62;
          const nameFontSize = 15.0;
          const jobFontSize = 13.0;

          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // ── Pill background ────────────────────────────────────────
              Container(
                width: w,
                height: h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(pillRadius),
                  border: Border.all(
                    color: isLight ? Colors.transparent : Colors.white,
                    width: 1,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isLight
                        ? [const Color(0xFF60438C), const Color(0xFFF0F0F0)]
                        : [const Color(0xFF040126), const Color(0xFF3A1521)],
                  ),
                ),
                // Bottom padding = image height so text stays in the top zone
                padding: EdgeInsets.fromLTRB(
                  w * 0.08,
                  h * 0.04,
                  w * 0.08,
                  imageHeight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      speaker.name,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      maxLines: 3,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: nameFontSize,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: h * 0.010),
                    Text(
                      speaker.job,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isLight ? Colors.black87 : AppColors.primaryRed,
                        fontWeight: FontWeight.bold,
                        fontSize: jobFontSize,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Speaker photo ───────────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(pillRadius * 0.96),
                child: Image(
                  image: _resolveImage(speaker.imageUrl),
                  width: w * 0.93,
                  height: imageHeight,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: w * 0.93,
                    height: imageHeight,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(pillRadius * 0.96),
                    ),
                    child: const Icon(Icons.person, color: Colors.white54, size: 48),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
