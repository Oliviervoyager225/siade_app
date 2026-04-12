import 'package:flutter/material.dart';
import 'package:siade2/src/commons/data/models.dart';
import 'package:siade2/src/theme/theme.dart';
import 'package:sizer/sizer.dart';
import 'package:siade2/src/commons/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:siade2/src/providers/providers.dart';

class DetailsPrograms extends StatefulWidget {
  final Program program;

  const DetailsPrograms({super.key, required this.program});

  @override
  _DetailsProgramsState createState() => _DetailsProgramsState();
}

class _DetailsProgramsState extends State<DetailsPrograms> {
  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      backgroundColor: isLight ? Colors.white : Colors.black,
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
                    image: widget.program.imageUrl.startsWith('http')
                        ? NetworkImage(widget.program.imageUrl) as ImageProvider
                        : AssetImage(widget.program.imageUrl),
                    fit: BoxFit.cover,
                    colorFilter: isLight 
                        ? null 
                        : ColorFilter.mode(
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
                          ? [Colors.transparent, Color(0xFF60438C)]
                          : [Colors.transparent, Colors.black],
                      stops: isLight ? [0.6, 1.0] : null,
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
                    final isFav = favs.isFavoriteProgram(widget.program);
                    return GestureDetector(
                      onTap: () => favs.toggleProgram(widget.program),
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

          Expanded(
            child: Container(
              decoration: isLight
                  ? BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF60438C), Color(0xFFDEDEDE)],
                      ),
                    )
                  : null,
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.program.room != null && widget.program.room!.isNotEmpty)
                                Text(
                                  widget.program.room!,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 13.sp,
                                  ),
                                ),
                              Text(
                                widget.program.title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                ),
                              ),
                              if (widget.program.formattedStartTime != null)
                                Text(
                                  'STARTING ${widget.program.formattedStartTime}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 13.sp,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 60,
                          height: 65,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: isLight
                                  ? [Color(0xFF60438C), Color(0xFF9E87CE)]
                                  : [
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
                                widget.program.dayLabel ?? 'Jour 1',
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
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.program.details,
                      overflow: TextOverflow.visible,
                      textAlign: TextAlign.justify,
                      style: TextStyle(color: Colors.white, fontSize: 16.sp),
                    ),
                    if (widget.program.speakers.isNotEmpty) ...[
                      SizedBox(height: 30),
                      Text(
                        "Intervenants",
                        style: TextStyle(color: Colors.white, fontSize: 13.sp),
                      ),
                      SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 3.2,
                        ),
                        itemCount: widget.program.speakers.length,
                        itemBuilder: (context, index) {
                          final speaker = widget.program.speakers[index];
                          final displayName = speaker.name.replaceAll('\n', ' ');
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  image: DecorationImage(
                                    image: speaker.imageUrl.startsWith('http')
                                        ? NetworkImage(speaker.imageUrl) as ImageProvider
                                        : AssetImage(speaker.imageUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              SizedBox(width: 5),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      speaker.job,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                    Text(
                                      displayName.length > 12
                                          ? '${displayName.substring(0, 12)}...'
                                          : displayName,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
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
