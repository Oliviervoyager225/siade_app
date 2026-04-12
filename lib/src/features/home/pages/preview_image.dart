import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

class PreviewImage extends StatefulWidget {
  final String image;
  const PreviewImage({super.key, required this.image});

  @override
  State<PreviewImage> createState() => _PreviewImageState();
}

class _PreviewImageState extends State<PreviewImage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Expanded(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(widget.image),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 30,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),

            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 30,
              child: GestureDetector(
                onTap: () {},
                child: Icon(
                  Icons.favorite_border,
                  color: Colors.white,
                  size: 40,
                  // fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
