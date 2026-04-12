import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:siade2/src/theme/theme.dart';
import '../../../../gen/assets.gen.dart';

class CarouselImages extends StatefulWidget {
  @override
  _CarouselImagesState createState() => _CarouselImagesState();
}

class _CarouselImagesState extends State<CarouselImages> {
  final List items = [
    Assets.images.carousel1.image(fit: BoxFit.fill),
    Assets.images.carousel2.image(fit: BoxFit.fill),
    Assets.images.carousel3.image(fit: BoxFit.fill),
    Assets.images.carousel4.image(fit: BoxFit.fill),
    Assets.images.carousel5.image(fit: BoxFit.fill),
  ];

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Column(
      children: [
        CarouselSlider.builder(
          options: CarouselOptions(
            height: 230,
            // viewportFraction: 0.75,
            enlargeCenterPage: true,
            enlargeFactor: 0.2,
            autoPlay: true,
            autoPlayInterval: Duration(seconds: 3),
            autoPlayCurve: Curves.fastOutSlowIn,
            pauseAutoPlayOnTouch: true,
            enableInfiniteScroll: true,
            scrollDirection: Axis.horizontal,
            reverse: false,
            clipBehavior: Clip.antiAlias,
            // enlargeStrategy: CenterPageEnlargeStrategy.scae,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          itemCount: items.length,
          itemBuilder: (context, index, realIndex) {
            final item = items[index];

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: item,
              ),
            );
          },
        ),

        Gap(20),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(items.length, (index) {
            bool isActive = _currentIndex == index;

            return GestureDetector(
              onTap: () {},
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 10 : 8,
                height: isActive ? 10 : 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primaryCarouselBullet
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(isActive ? 5 : 4),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
