import 'package:flutter/material.dart';
import 'package:siade2/src/commons/data/models.dart';
import 'package:siade2/src/features/home/widgets/widgets.dart';
import 'package:siade2/src/theme/theme.dart';
import 'package:sizer/sizer.dart';

class ExponentItem extends StatefulWidget {
  final Exponent exponent;

  const ExponentItem({super.key, required this.exponent});

  @override
  _ExponentItemState createState() => _ExponentItemState();
}

class _ExponentItemState extends State<ExponentItem> {
  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsExponents(exponent: widget.exponent),
          ),
        );
      },
      child: Container(
        // width: 40.w,
        padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0), // Reduced vertical padding
        decoration: BoxDecoration(
          color: isLight ? Color(0xFF60438C) : Color(0xff1F0D68), // Purple in Light, Dark Blue in Dark
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: widget.exponent.imageUrl.startsWith('http')
                      ? NetworkImage(widget.exponent.imageUrl) as ImageProvider
                      : AssetImage(widget.exponent.imageUrl),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.exponent.job.isNotEmpty
                  ? widget.exponent.job
                  : 'Exposant SIADE 2026',
              style: const TextStyle(color: Colors.white, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    height: 30, // Reduced height slightly
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Visiter Stand',
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 8, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 30, // Reduced height
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: isLight 
                            ? [Colors.white.withValues(alpha: 0.4), Color(0xFF472181)] 
                            : [AppColors.primaryRed, AppColors.primaryBlue],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Text(
                      'Telecharger',
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 8, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
