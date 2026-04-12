import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:siade2/src/features/home/widgets/widgets.dart';
import 'package:siade2/src/theme/theme.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import 'package:siade2/src/providers/providers.dart';
import 'package:siade2/l10n/app_localizations.dart';

class Programs extends StatefulWidget {
  @override
  _ProgramsState createState() => _ProgramsState();
}

class _ProgramsState extends State<Programs> {
  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final listPrograms = dataProvider.programs;

        final displayPrograms = listPrograms;
        final l10n = AppLocalizations.of(context)!;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.program,
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
                          builder: (context) => AllPrograms(programs: displayPrograms),
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
                  : SizedBox(
                      height: 250,
                      child: ListView.separated(
                        separatorBuilder: (context, _) => const SizedBox(width: 10),
                        itemCount: displayPrograms.length,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          final program = displayPrograms[index];
                          final dayLabel = program.dayLabel ?? 'Jour 1';

                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailsPrograms(program: program),
                              ),
                            ),
                            child: Stack(
                            children: [
                              Container(
                                width: 250,
                                height: 250,
                                padding: const EdgeInsets.only(left: 16, bottom: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  image: program.imageUrl.startsWith('http')
                                      ? DecorationImage(
                                          image: NetworkImage(program.imageUrl),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                  gradient: program.imageUrl.startsWith('http')
                                      ? null
                                      : const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [Color(0xFF1C0052), Color(0xFF060030)],
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (!program.imageUrl.startsWith('http'))
                                      Expanded(
                                        child: Center(
                                          child: Image.asset(
                                            'assets/images/programme.png',
                                            height: 120,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      program.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18.sp,
                                      ),
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
                                        Colors.black.withValues(alpha: 0.5),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 10,
                                top: 10,
                                child: Container(
                                  width: 60,
                                  height: 65,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        AppColors.primaryBlue,
                                        AppColors.primaryRed,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                                      const SizedBox(height: 4),
                                      Text(
                                        dayLabel,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
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
