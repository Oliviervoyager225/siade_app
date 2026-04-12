import 'package:flutter/material.dart';
import 'package:siade2/src/commons/data/models/caterer.dart';
import 'package:siade2/src/theme/theme.dart';
import 'package:sizer/sizer.dart';

class DetailsDish extends StatelessWidget {
  final Dish dish;

  const DetailsDish({super.key, required this.dish});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050026),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            elevation: 0,
            expandedHeight: 340,
            leadingWidth: 100,
            toolbarHeight: 100,
            leading: Padding(
              padding: const EdgeInsets.all(30.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppColors.greySecondary, width: 0.5),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Container(
                height: 60,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 25.0),
                padding: const EdgeInsets.only(top: 10.0, right: 10.0, left: 10.0),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xff2B2A60)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dish.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                    ),
                    Text(
                      dish.price.isNotEmpty ? '${dish.price} FCFA' : '',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              background: dish.photoUrl != null
                  ? Image.network(
                      dish.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/plat.png',
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset('assets/images/plat.png', fit: BoxFit.cover),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
              padding: const EdgeInsets.all(40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dish.description.isNotEmpty)
                    Text(
                      dish.description,
                      style: TextStyle(color: Colors.white, fontSize: 15.sp, height: 1.6),
                    ),
                  if (dish.availabilitySchedule != null) ...[
                    const SizedBox(height: 20),
                    _infoChip(Icons.schedule, dish.availabilitySchedule!),
                  ],
                  if (dish.date != null) ...[
                    const SizedBox(height: 10),
                    _infoChip(Icons.calendar_today, dish.date!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      ],
    );
  }
}
