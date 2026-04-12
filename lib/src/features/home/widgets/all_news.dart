import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:siade2/src/features/home/widgets/widgets.dart'; // Pour Feed, Posts, etc.
import 'package:siade2/src/theme/theme.dart';
import 'package:sizer/sizer.dart';
import 'package:siade2/src/commons/data/models.dart';
import 'package:provider/provider.dart';
import 'package:siade2/src/providers/providers.dart';
import '../../../../gen/assets.gen.dart';

class AllNews extends StatefulWidget {
  @override
  _AllNewsState createState() => _AllNewsState();
}

class _AllNewsState extends State<AllNews> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final listArticles = dataProvider.articles;

        return SafeArea(
          child: Scaffold(
            backgroundColor: isLight ? Colors.white : null,
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: 20.0,
                    left: 20.0,
                    right: 20.0,
                    bottom: 10.0,
                  ),
                  child: Column(
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
                                color: isLight
                                    ? const Color(0xFF60438C).withOpacity(0.3)
                                    : Colors.black,
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                          isLight
                              ? Image.asset('assets/images/logo23.png', height: 20)
                              : Assets.images.logo.image(height: 20),
                        ],
                      ),
                      const Gap(20),
                      SizedBox(
                        height: 140,
                        child: dataProvider.isLoading 
                          ? const Center(child: CircularProgressIndicator())
                          : listArticles.isEmpty
                              ? const Center(child: Text("Aucun média trouvé"))
                              : ListView.separated(
                                  separatorBuilder: (context, _) => const SizedBox(width: 10),
                                  itemCount: listArticles.length,
                                  scrollDirection: Axis.horizontal,
                                  itemBuilder: (context, index) {
                                    final article = listArticles[index];

                                    return Stack(
                                      children: [
                                        Container(
                                          width: 100,
                                          height: 140,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(16),
                                            image: DecorationImage(
                                              image: article.imageUrl.startsWith('http')
                                                  ? NetworkImage(article.imageUrl)
                                                  : AssetImage(article.imageUrl) as ImageProvider,
                                              fit: BoxFit.cover,
                                            ),
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
                                                  Colors.black.withOpacity(0.5),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                      ),
                      const Gap(20),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemCount: exponentCaterogies.length,
                          itemBuilder: (context, index) {
                            final category = exponentCaterogies[index];
                            bool isSelected = selectedIndex == index;

                            return GestureDetector(
                              onTap: () => setState(() => selectedIndex = index),
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected ? Colors.transparent : (isLight ? const Color(0xFF60438C) : Colors.white),
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: isSelected
                                      ? LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: isLight
                                              ? [const Color(0xFF60438C), const Color(0xFF60438C)]
                                              : [AppColors.primaryBlue, AppColors.primaryRed],
                                        )
                                      : null,
                                ),
                                child: Text(
                                  category.name,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : (isLight ? const Color(0xFF60438C) : Colors.white),
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    child: Feed(),
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
