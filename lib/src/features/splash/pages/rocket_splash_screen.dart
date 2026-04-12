import 'package:flutter/material.dart';
import 'package:siade2/src/features/splash/widgets/rocket_exhaust.dart';
import 'package:siade2/src/features/splash/pages/splash_page.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:siade2/src/features/home/pages/pages.dart';
import 'package:siade2/src/providers/user_provider.dart';

class RocketSplashScreen extends StatefulWidget {
  const RocketSplashScreen({Key? key}) : super(key: key);

  @override
  _RocketSplashScreenState createState() => _RocketSplashScreenState();
}

class _RocketSplashScreenState extends State<RocketSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _riseToLaunchStationAnimation;
  late Animation<double> _liftOffFromLaunchStationAnimation;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isVisible = false;
        });
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) _checkSessionAndNavigate();
        });
      }
    });

    _riseToLaunchStationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    ));

    _liftOffFromLaunchStationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeInCirc),
    ));

    _controller.forward(from: 0);
  }

  Future<void> _checkSessionAndNavigate() async {
    final storage = const FlutterSecureStorage();
    Widget destination = const SplashPage();

    try {
      // Vérification Firebase (Google ou Email/Password via Firebase)
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        // Forcer le refresh du token pour vérifier qu'il est toujours valide
        await firebaseUser.getIdToken(true);
        destination = AppLayout();
      } else {
        // Vérification session Django locale
        final expiresAt = await storage.read(key: 'session_expires_at');
        final accessToken = await storage.read(key: 'access_token');
        if (expiresAt != null && accessToken != null) {
          final expiry = DateTime.tryParse(expiresAt);
          if (expiry != null && DateTime.now().isBefore(expiry)) {
            destination = AppLayout();
          } else {
            // Session expirée → nettoyer
            await storage.delete(key: 'access_token');
            await storage.delete(key: 'refresh_token');
            await storage.delete(key: 'session_expires_at');
          }
        }
      }
    } catch (_) {
      // Token Firebase invalide ou erreur réseau → onboarding
      destination = const SplashPage();
    }

    if (mounted) {
      if (destination is AppLayout) {
        await context.read<UserProvider>().restoreSession();
      }
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => destination,
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final imageSize = isTablet ? 200.0 : 100.0;

    return Scaffold(
      backgroundColor: const Color(0xFF040126),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: const Color(0xFF040126),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return RocketExhaustWidget(
                launchProgress: _liftOffFromLaunchStationAnimation.value > 0
                    ? ((screenHeight * 2) *
                            _liftOffFromLaunchStationAnimation.value +
                        screenHeight / 4)
                    : screenHeight / 4 * _riseToLaunchStationAnimation.value,
              );
            },
          ),
          // ── Rideau sombre montant de bas en haut ──────────────────────────
          // Couvre progressivement la fumée au fur et à mesure que la fusée monte.
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final rocketPos = _liftOffFromLaunchStationAnimation.value > 0
                  ? ((screenHeight * 2) *
                          _liftOffFromLaunchStationAnimation.value +
                      screenHeight / 4)
                  : screenHeight / 4 * _riseToLaunchStationAnimation.value;

              // La hauteur du rideau suit la fusée avec un décalage vers le bas
              // pour que l'obscurité semble "avaler" la trainée derrière elle.
              final darkHeight =
                  (rocketPos - screenHeight * 0.30).clamp(0.0, screenHeight);

              if (darkHeight <= 0) return const SizedBox.shrink();

              return Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: darkHeight,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color(0xFF040126), // bas : plein opaque
                        Color(0xFF040126), // milieu : toujours opaque
                        Color(0x00040126), // haut : fondu transparent
                      ],
                      stops: [0.0, 0.65, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),
          // ── Fondu plein écran → #040126 en fin d'animation ──────────────
          // Quand la fusée est à 70% de sa montée, l'écran entier bascule
          // progressivement vers #040126 jusqu'à opacité totale à 100%.
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final liftOff = _liftOffFromLaunchStationAnimation.value;
              // fade-in sur les derniers 30% du liftoff
              final fadeOpacity = ((liftOff - 0.65) / 0.35).clamp(0.0, 1.0);
              if (fadeOpacity <= 0) return const SizedBox.shrink();
              return Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Color.fromRGBO(4, 1, 38, fadeOpacity),
                  ),
                ),
              );
            },
          ),
          // ── Logo SIADE centré — apparaît quand l'écran est sombre ────────
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final liftOff = _liftOffFromLaunchStationAnimation.value;
              // Le logo monte en opacité seulement sur les 8% finaux (0.92→1.0)
              final logoOpacity = ((liftOff - 0.92) / 0.08).clamp(0.0, 1.0);
              if (logoOpacity <= 0) return const SizedBox.shrink();
              return Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: logoOpacity,
                    child: Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: screenWidth * 0.50,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (_isVisible)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Positioned(
                  left: 0,
                  right: 0,
                  bottom: _liftOffFromLaunchStationAnimation.value > 0
                      ? ((screenHeight * 2) *
                              _liftOffFromLaunchStationAnimation.value +
                          screenHeight / 4)
                      : screenHeight / 4 * _riseToLaunchStationAnimation.value,
                  child: Center(
                    child: Image.asset(
                      'assets/images/robo siade.png',
                      width: imageSize,
                      height: imageSize,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
