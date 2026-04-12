import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siade2/src/commons/data/models/caterer.dart';
import 'package:siade2/src/features/home/pages/details_dish.dart';
import 'package:siade2/src/providers/data_provider.dart';
import 'package:siade2/src/theme/theme.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

class RestaurantPage extends StatefulWidget {
  const RestaurantPage({super.key});

  @override
  State<RestaurantPage> createState() => _RestaurantPageState();
}

class _RestaurantPageState extends State<RestaurantPage>
    with SingleTickerProviderStateMixin {
  int _selectedCatererIndex = 0;

  Future<void> _launch(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final caterers = dataProvider.caterers.where((c) => c.isActive).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF050026),
        body: dataProvider.isLoading && caterers.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : caterers.isEmpty
                ? _buildEmpty()
                : NestedScrollView(
                    headerSliverBuilder: (context, _) => [
                      _buildSliverAppBar(context, caterers),
                      _buildCatererSelector(caterers),
                      _buildTabBar(),
                    ],
                    body: TabBarView(
                      children: [
                        _buildDishList(caterers[_selectedCatererIndex].matinDishes),
                        _buildDishList(caterers[_selectedCatererIndex].soirDishes),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.restaurant, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            'Aucun restaurateur disponible',
            style: TextStyle(color: Colors.white54, fontSize: 15.sp),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context, List<Caterer> caterers) {
    final caterer = caterers[_selectedCatererIndex];
    return SliverAppBar(
      elevation: 0,
      expandedHeight: 300,
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
      actions: [
        if (caterer.websiteUrl != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 36),
            child: GestureDetector(
              onTap: () => _launch(caterer.websiteUrl),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.language, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Site web', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Container(
          height: 90,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 25.0),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo
              if (caterer.logoUrl != null)
                ClipOval(
                  child: Image.network(
                    caterer.logoUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _defaultLogo(),
                  ),
                )
              else
                _defaultLogo(),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    caterer.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                  if (caterer.cuisineType != null)
                    Text(
                      caterer.cuisineType!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11.sp,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        background: caterer.logoUrl != null
            ? Image.network(caterer.logoUrl!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Image.asset('assets/images/restau.png', fit: BoxFit.cover))
            : Image.asset('assets/images/restau.png', fit: BoxFit.cover),
      ),
    );
  }

  Widget _defaultLogo() {
    return ClipOval(
      child: Container(
        width: 40,
        height: 40,
        color: Colors.black,
        child: Image.asset('assets/images/star.png', width: 25, height: 25),
      ),
    );
  }

  // Sélecteur horizontal si plusieurs caterers
  SliverToBoxAdapter _buildCatererSelector(List<Caterer> caterers) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (caterers.length > 1) ...[
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: caterers.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final selected = i == _selectedCatererIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCatererIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xff6562FB)
                              : Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: selected ? const Color(0xff6562FB) : Colors.white24,
                          ),
                        ),
                        child: Text(
                          caterers[i].name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Infos contact
            _buildContactRow(caterers[_selectedCatererIndex]),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(Caterer caterer) {
    if (caterer.contactPhone == null && caterer.contactEmail == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 10,
        children: [
          if (caterer.contactPhone != null)
            GestureDetector(
              onTap: () => _launch('tel:${caterer.contactPhone}'),
              child: _chip(Icons.phone, caterer.contactPhone!),
            ),
          if (caterer.contactEmail != null)
            GestureDetector(
              onTap: () => _launch('mailto:${caterer.contactEmail}'),
              child: _chip(Icons.email_outlined, caterer.contactEmail!),
            ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white54, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildTabBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Container(
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TabBar(
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              gradient: RadialGradient(
                radius: 2,
                colors: [
                  const Color(0xff2737CF).withValues(alpha: 0.4),
                  const Color(0xff6562FB),
                ],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Matin'),
              Tab(text: 'Soir'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDishList(List<Dish> dishes) {
    if (dishes.isEmpty) {
      return Center(
        child: Text(
          'Aucun plat disponible',
          style: TextStyle(color: Colors.white38, fontSize: 14.sp),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: dishes.length,
      itemBuilder: (context, index) {
        final dish = dishes[index];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailsDish(dish: dish)),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            height: 120,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dish.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (dish.description.isNotEmpty)
                        Text(
                          dish.description,
                          style: TextStyle(
                            color: AppColors.greySecondary,
                            fontSize: 11.sp,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 8),
                      Text(
                        dish.price.isNotEmpty ? '${dish.price} FCFA' : '',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Photo
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: dish.photoUrl != null
                      ? Image.network(
                          dish.photoUrl!,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/images/plat.png',
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          'assets/images/plat.png',
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
