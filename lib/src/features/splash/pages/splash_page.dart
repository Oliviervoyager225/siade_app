import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siade2/l10n/app_localizations.dart';
import 'package:siade2/src/features/welcome/welcome_page.dart';
import 'package:siade2/src/providers/theme_provider.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';
//import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 4), (timer) {
      if (_currentPage < 2) {
        // Based on onboardingData length
        _onPageChanged(_currentPage + 1);
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      } else {
        _timer?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WelcomePage()),
        );
      }
    });
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDarkMode = themeProvider.isDarkMode;

    // Version sombre (style spatial)
    final List<Map<String, dynamic>> darkOnboardingData = [
      {
        'image': 'assets/images/splash.png',
        'title': l10n.welcomeToSiade,
        'subtitle': l10n.discoverTechEvent,
        'bgColor': Color(0xFF040126),
        'filterColor': Color(0xFF040126),
        'alignment': Alignment(0, -1.7),
        'opacity': 0.83,
      },
      {
        'image': 'assets/images/avatar.png',
        'title': l10n.innovationTitle,
        'subtitle': l10n.innovationSubtitle,
        'alignment': Alignment(0, -0.9),
      },
      {
        'image': 'assets/images/avat.png',
        'title': l10n.networkingTitle,
        'subtitle': l10n.networkingSubtitle,
        'alignment': Alignment(0, -0.9),
      },
    ];

    // Version claire
    final List<Map<String, dynamic>> lightOnboardingData = [
      {
        'image': 'assets/images/splash.png',
        'title': l10n.welcomeToSiade,
        'subtitle': l10n.discoverTechEvent,
        'alignment': Alignment(0, -1.7),
      },
      {
        'image': 'assets/images/Avatar 1.png',
        'title': l10n.innovationTitle,
        'subtitle': l10n.innovationSubtitle,
        'alignment': Alignment.center,
      },
      {
        'image': 'assets/images/Avatar 2.png',
        'title': l10n.networkingTitle,
        'subtitle': l10n.networkingSubtitle,
        'alignment': Alignment.center,
      },
    ];

    final onboardingData = isDarkMode ? darkOnboardingData : lightOnboardingData;

    return Scaffold(
      backgroundColor: isDarkMode ? Color(0xFF040126) : null,
      body: SafeArea(
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          itemCount: onboardingData.length,
          itemBuilder: (context, index) {
            if (isDarkMode) {
              // Mode sombre (style spatial)
              return Stack(
                children: [
                  // ── Fond de base ─────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      image: index == 0
                          ? DecorationImage(
                              image: AssetImage(onboardingData[index]['image']!),
                              fit: BoxFit.none,
                              alignment: onboardingData[index]['alignment'],
                              scale: 1,
                              colorFilter: ColorFilter.mode(
                                onboardingData[index]['filterColor']
                                    .withOpacity(onboardingData[index]['opacity']),
                                BlendMode.srcATop,
                              ),
                            )
                          : null,
                      color: const Color(0xFF040126),
                    ),
                  ),
                  // ── Bulle gradient (pages 2 et 3) ────────────────────────
                  if (index > 0)
                    Positioned(
                      top: 10.h,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 65.w,
                          height: 65.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFFF1493), // Rose vif
                                Color(0xFF00CED1), // Cyan
                              ],
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(3.5),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF040126),
                              ),
                              child: Center(
                                child: Image.asset(
                                  onboardingData[index]['image']!,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 2.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            onboardingData[index]['title']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26.sp,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            onboardingData[index]['subtitle']!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 15.sp,
                            ),
                          ),
                          SizedBox(height: 5.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              onboardingData.length,
                              (i) => Container(
                                width: 2.w,
                                height: 2.w,
                                margin: EdgeInsets.symmetric(horizontal: 1.w),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentPage == i
                                      ? Color(0xff00FAFE)
                                      : Color(0xff00FAFE).withOpacity(0.49),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            "COPYRIGHT SAHANALYTICS",
                            style: TextStyle(
                              color: Color(0XFF60438C),
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            } else {
              // Mode clair (style gradient)
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE8E8E8), Color(0xFFD0D0D0)],
                  ),
                ),
                child: Stack(
                  children: [
                    // Image centrale
                    Positioned(
                      top: 8.h,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 40.h,
                        child: Image.asset(
                          onboardingData[index]['image']!,
                          fit: BoxFit.contain,
                          alignment: onboardingData[index]['alignment'] ?? Alignment.center,
                        ),
                      ),
                    ),
                    // Contenu textuel en bas
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 3.h,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              onboardingData[index]['title']!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF6A4C93),
                                fontSize: 22.sp,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                            ),
                            SizedBox(height: 1.5.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              child: Text(
                                onboardingData[index]['subtitle']!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF9E9E9E),
                                  fontSize: 13.sp,
                                ),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            // Indicateurs de page
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                onboardingData.length,
                                (i) => AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  width: _currentPage == i ? 8.w : 2.w,
                                  height: 2.w,
                                  margin: EdgeInsets.symmetric(horizontal: 1.w),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: _currentPage == i
                                        ? Color(0xFF6A4C93)
                                        : Color(0xFFBDBDBD),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              l10n.copyright,
                              style: TextStyle(
                                color: Color(0xFF6A4C93).withOpacity(0.6),
                                fontSize: 12.sp,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 1.h),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }
}
