import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:siade2/src/commons/data/models.dart';
import 'package:siade2/src/features/home/widgets/widgets.dart';
import 'package:siade2/src/features/home/widgets/details_speakers.dart';
import 'package:siade2/src/theme/theme.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import 'package:siade2/src/providers/providers.dart';
import 'package:siade2/l10n/app_localizations.dart';

class Speakers extends StatefulWidget {
  @override
  _SpeakersState createState() => _SpeakersState();
}

class _SpeakersState extends State<Speakers> {
  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final listSpeakers = dataProvider.speakers;
        final l10n = AppLocalizations.of(context)!;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.speakers,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.light 
                          ? const Color(0xFF180468) 
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AllSpeakers(speakers: listSpeakers),
                        ),
                      );
                    },
                    child: Text(
                      l10n.seeAll,
                      style: TextStyle(color: AppColors.gestureDetectorSeeAll),
                    ),
                  ),
                ],
              ),
              const Gap(20),
              dataProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white, backgroundColor: Colors.transparent))
                  : listSpeakers.isEmpty
                      ? Text(
                          l10n.noData,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.light 
                                ? Colors.black54 
                                : Colors.white70,
                          ),
                        )
                      : SizedBox(
                          height: 149,
                          child: ListView.separated(
                            separatorBuilder: (context, _) => const SizedBox(width: 10),
                            itemCount: listSpeakers.length,
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              final speaker = listSpeakers[index];

                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetailsSpeakers(speaker: speaker),
                                  ),
                                ),
                                child: Stack(
                                children: [
                                  Container(
                                    width: 149,
                                    height: 149,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      image: DecorationImage(
                                        image: speaker.imageUrl.startsWith('http')
                                            ? NetworkImage(speaker.imageUrl)
                                            : AssetImage(speaker.imageUrl) as ImageProvider,
                                        fit: BoxFit.cover,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.5),
                                          blurRadius: 10,
                                          spreadRadius: 0,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withValues(alpha: 0.6),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 16,
                                    right: 8,
                                    bottom: 6,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          speaker.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14.sp,
                                          ),
                                        ),
                                        Text(
                                          speaker.job,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.8),
                                            fontSize: 12.sp,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                ),
                              );
                            },
                          ),
                        ),
            ],
          ),
        );
      },
    );
  }
}
