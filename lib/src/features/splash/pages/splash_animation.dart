import 'package:flutter/material.dart';
import 'package:siade2/src/features/splash/pages/splash_page.dart';
import 'dart:async';

class SplashAnimation extends StatefulWidget {
  const SplashAnimation({super.key});

  @override
  State<SplashAnimation> createState() => _SplashAnimationState();
}

class _SplashAnimationState extends State<SplashAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sScaleAnimation;
  late Animation<double> _sOpacityAnimation;
  late Animation<double> _iadeOpacityAnimation;
  late Animation<double> _iadeSlideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Animation pour le "S" - plus rapide et plus prononcée
    _sScaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
      ),
    );

    _sOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // Animation pour le "IADE" - apparaît après le S
    _iadeOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.8, curve: Curves.easeIn),
      ),
    );

    _iadeSlideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();

    // Navigation après l'animation complète
    Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const SplashPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      backgroundColor: isLight ? const Color(0xFFE8E8E8) : const Color(0xFF0A0E27),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Le "S" animé
                Opacity(
                  opacity: _sOpacityAnimation.value,
                  child: Transform.scale(
                    scale: _sScaleAnimation.value,
                    child: _buildGradientText('S', fontSize: 120),
                  ),
                ),
                
                // Le "IADE" qui se dévoile
                Transform.translate(
                  offset: Offset(_iadeSlideAnimation.value, 0),
                  child: Opacity(
                    opacity: _iadeOpacityAnimation.value,
                    child: _buildGradientText('IADE', fontSize: 120),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGradientText(String text, {required double fontSize}) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF60438C),
          Colors.white,
        ],
      ).createShader(bounds),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: text == 'S' ? 0 : -3,
          height: 1.0,
        ),
      ),
    );
  }
}
