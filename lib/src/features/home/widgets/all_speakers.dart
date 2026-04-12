import 'package:flutter/material.dart';
import 'package:siade2/gen/assets.gen.dart';
import 'package:siade2/src/commons/data/models.dart';
import 'package:siade2/src/features/home/pages/pages.dart';
import 'package:siade2/src/features/home/widgets/widgets.dart';
import 'package:sizer/sizer.dart';

class AllSpeakers extends StatefulWidget {
  final List<Speaker> speakers;

  const AllSpeakers({super.key, required this.speakers});

  @override
  _AllSpeakersState createState() => _AllSpeakersState();
}

class _AllSpeakersState extends State<AllSpeakers> {
  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final screenWidth = MediaQuery.of(context).size.width;
    // 2 columns on phones, 3 on tablets/large screens
    final colCount = screenWidth >= 600 ? 3 : 2;
    // Lower ratio = taller cards → more room for long names / job titles
    final childAspectRatio = screenWidth >= 600 ? 0.46 : 0.43;
    return Scaffold(
      backgroundColor: isLight ? Colors.white : null,
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 20,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLight ? Color(0xFF60438C) : Colors.black, // Purple button in light mode
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),

                isLight 
                    ? Image.asset('assets/images/logo23.png', height: 20) // Manually load asset to bypass gen issue
                    : Assets.images.logo.image(height: 20),
              ],
            ),

            Container(
              width: 100.w,
              height: 125,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.0),
                gradient: LinearGradient(
                  colors: isLight 
                      ? [Color(0xFF60438C), Colors.white] // Purple to white gradient
                      : [Color(0xff305481), Color(0xff08082D)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                spacing: 10,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Nos Intervenants',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),

                  Text(
                    'Des experts et leaders qui façonnent l\'avenir',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 14.sp),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: colCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 20,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: widget.speakers.length,
                  itemBuilder: (context, index) {
                    final speaker = widget.speakers[index];
                    return SpeakerItem(speaker: speaker);
                  }
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
