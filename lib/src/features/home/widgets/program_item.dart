import 'package:flutter/material.dart';
import 'package:siade2/src/commons/data/models.dart';
import 'package:siade2/src/features/home/widgets/widgets.dart';
import 'package:siade2/src/theme/theme.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import 'package:siade2/src/providers/providers.dart';

class ProgramItem extends StatefulWidget {
  final Program program;

  const ProgramItem({super.key, required this.program});

  @override
  _ProgramItemState createState() => _ProgramItemState();
}

class _ProgramItemState extends State<ProgramItem> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsPrograms(program: widget.program),
          ),
        );
      },
      child: Stack(
        children: [
          Container(
            width: 90.w,
            height: 330,
            padding: EdgeInsetsGeometry.only(left: 16, bottom: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: widget.program.imageUrl.startsWith('http')
                  ? DecorationImage(
                      image: NetworkImage(widget.program.imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
              gradient: widget.program.imageUrl.startsWith('http')
                  ? null
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1C0052), Color(0xFF060030)],
                    ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!widget.program.imageUrl.startsWith('http'))
                  const Expanded(
                    child: Center(
                      child: Icon(Icons.event_note, color: Colors.white38, size: 80),
                    ),
                  ),
                Text(
                  widget.program.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        if (widget.program.room != null)
                          Text(
                            widget.program.room!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 14.sp,
                            ),
                          ),
                        if (widget.program.formattedStartTime != null)
                          Text(
                            'STARTING ${widget.program.formattedStartTime}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Consumer<FavoritesProvider>(
                      builder: (context, favs, _) {
                        final isFav = favs.isFavoriteProgram(widget.program);
                        return IconButton(
                          onPressed: () => favs.toggleProgram(widget.program),
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.red : Colors.white,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: Container(
              height: 30, // Hauteur de l'ombre
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.25),
                  ],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
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
                  colors: Theme.of(context).brightness == Brightness.light
                      ? [Color(0xFF60438C), Color(0xFF9E87CE)]
                      : [AppColors.primaryBlue, AppColors.primaryRed],
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
          ),

          if (widget.program.speakers.isNotEmpty)
            Positioned(
              left: 10,
              top: 10,
              child: Row(
                children: List.generate(
                  widget.program.speakers.take(3).length,
                  (index) {
                    final speaker = widget.program.speakers.take(3).elementAt(index);
                    return Transform.translate(
                      offset: Offset(-12.0 * index, 0),
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                          image: DecorationImage(
                            image: speaker.imageUrl.startsWith('http')
                                ? NetworkImage(speaker.imageUrl) as ImageProvider
                                : AssetImage(speaker.imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
