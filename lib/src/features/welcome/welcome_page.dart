import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siade2/l10n/app_localizations.dart';
import 'package:siade2/src/features/login/pages/login.dart';
import 'package:siade2/src/providers/theme_provider.dart';
import 'package:sizer/sizer.dart';
//import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDarkMode = themeProvider.isDarkMode;

    if (isDarkMode) {
      // Version sombre (style spatial)
      return Scaffold(
        backgroundColor: Color(0xFF040126),
        body: SafeArea(
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/threeavatar.png'),
                    fit: BoxFit.none,
                    alignment: Alignment(0, -0.9),
                    scale: 1,
                  ),
                  color: Color(0xFF040126),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 5.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.readyToStart,
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
                        l10n.joinSiadeNow,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 15.sp,
                        ),
                      ),
                      SizedBox(height: 5.h),
                      Container(
                        width: 160,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF180468), Color(0xFFD2044E)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Container(
                          margin: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Color(0xFF180468).withOpacity(0.60),
                            borderRadius: BorderRadius.circular(23),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(23),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Login(),
                                  ),
                                );
                              },
                              child: Center(
                                child: Text(
                                  'Découvrir',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
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
          ),
        ),
      );
    } else {
      // Version claire (style gradient)
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE8E8E8), Color(0xFFD0D0D0)],
            ),
          ),
          child: SafeArea(
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
                      'assets/images/Avatar 3.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
                // Contenu en bas
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.readyToStart,
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
                            l10n.joinSiadeNow,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                        SizedBox(height: 3.h),
                        // Bouton Sign up avec bordure gradient
                        Container(
                          width: 160,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFF1493), Color(0xFF00CED1)],
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Container(
                            margin: EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(27.5),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(27.5),
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Login(),
                                    ),
                                  );
                                },
                                child: Center(
                                  child: ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: [
                                        Color(0xFFFF1493),
                                        Color(0xFF6A4C93),
                                      ],
                                    ).createShader(bounds),
                                    child: Text(
                                      l10n.signUp,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
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
          ),
        ),
      );
    }
  }
}
