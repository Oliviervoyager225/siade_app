import 'package:flutter/material.dart';
import 'package:siade2/src/core/services/firebase_auth_service.dart';
import 'package:siade2/src/features/home/pages/pages.dart';
import 'package:siade2/src/features/login/pages/pages.dart';
import 'package:siade2/src/features/login/widgets/widgets.dart';
import 'package:provider/provider.dart';
import 'package:siade2/src/providers/providers.dart';
import 'package:siade2/src/core/local/connectivity_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Login extends StatefulWidget {
  Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool rememberMe = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleLogin() => _handleOAuthLogin(
        connexion: () =>
            context.read<UserProvider>().loginWithGoogleHybrid(),
        majChargement: (v) => setState(() => _isGoogleLoading = v),
        erreurParDefaut: 'Erreur Google Sign-In',
      );

  Future<void> _handleAppleLogin() => _handleOAuthLogin(
        connexion: () => context.read<UserProvider>().loginWithAppleHybrid(),
        majChargement: (v) => setState(() => _isAppleLoading = v),
        erreurParDefaut: 'Erreur Sign in with Apple',
      );

  /// Chemin commun aux connexions Google et Apple : seul le fournisseur change.
  Future<void> _handleOAuthLogin({
    required Future<bool> Function() connexion,
    required void Function(bool) majChargement,
    required String erreurParDefaut,
  }) async {
    majChargement(true);
    final success = await connexion();
    if (!mounted) return;
    majChargement(false);

    if (success) {
      // OAuth → session longue (Firebase gère le refresh, on marque 30j)
      final expiry = DateTime.now().add(const Duration(days: 30));
      await const FlutterSecureStorage()
          .write(key: 'session_expires_at', value: expiry.toIso8601String());

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AppLayout()),
      );
    } else {
      final error = context.read<UserProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? erreurParDefaut),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    final success = await context.read<UserProvider>().login(email, password);

    if (mounted) {
      if (success) {
        // Sauvegarder la durée de session selon "Se souvenir de moi"
        final expiry = DateTime.now().add(
          rememberMe ? const Duration(days: 30) : const Duration(hours: 24),
        );
        await const FlutterSecureStorage()
            .write(key: 'session_expires_at', value: expiry.toIso8601String());

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AppLayout()),
        );
      } else {
        final error = context.read<UserProvider>().error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Erreur de connexion'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final isOnline = context.watch<ConnectivityService>().isOnline;
    return Scaffold(
      backgroundColor: isLight ? Color(0xFFE8E8E8) : Color(0xFF0A0E27), // Unified with onboarding
      body: Stack(
        children: [
          // Banner hors-ligne
          if (!isOnline)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  color: Colors.orange.shade700,
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Mode hors-ligne – Connexion locale',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Background image for both modes
          Positioned(
            top: -40,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.40,
            child: Image.asset('assets/images/back.png', fit: BoxFit.contain),
          ),

          // Logo SIADE on robot torso
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25, // Adjusted position
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: 35, // Reduced size
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Light mode background section (Straight borders, lower position)
          if (isLight)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.35, // Moved slightly higher
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFFE0E0E0), // User specified color
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Container(
                  margin: EdgeInsets.only(top: 4), // Thicker border for better visibility
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFE0E0E0), // Start with the requested grey
                        Color(0xFFF5E6F0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.35),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    children: [
                      SizedBox(height: 25),
                      Row(
                        children: [
                          Expanded(
                            child: GradientButton(
                              text: 'Connexion',
                              isActive: true,
                              onTap: () {},
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: OutlineButton(
                              text: 'Inscription',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SignupPage(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 25),

                      CustomTextField(
                        controller: _emailController,
                        icon: Icons.email_outlined,
                        hint: 'E-mail ID',
                      ),
                      SizedBox(height: 18),

                      CustomTextField(
                        controller: _passwordController,
                        icon: Icons.lock_outline,
                        hint: 'Mot de passe',
                        isPassword: true,
                      ),
                      SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      rememberMe = value ?? false;
                                    });
                                  },
                                  fillColor: MaterialStateProperty.all(
                                    Colors.transparent,
                                  ),
                                  checkColor: isLight
                                      ? Color(0xFF60438C)
                                      : Colors.blue,
                                  side: BorderSide(
                                    color: isLight
                                        ? Color(0xFF60438C)
                                        : Colors.blue,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Se souvenir de moi',
                                style: TextStyle(
                                  color: isLight
                                      ? Color(0xFF60438C)
                                      : Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ForgotPasswordPage(),
                                ),
                              );
                            },
                            child: Text(
                              'Mot de passe oublié ?',
                              style: TextStyle(
                                color: isLight ? Color(0xFF60438C) : Colors.blue,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 25),

                      Consumer<UserProvider>(
                        builder: (context, userProvider, child) {
                          if (userProvider.isLoading && !_isGoogleLoading) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          return GradientButton(
                            text: 'Connexion',
                            isActive: true,
                            isFullWidth: true,
                            onTap: _handleLogin,
                          );
                        },
                      ),
                      SizedBox(height: 25),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: isLight
                                  ? Color(0xFF60438C).withOpacity(0.3)
                                  : Colors.white24,
                              indent: 20,
                              endIndent: 10,
                            ),
                          ),
                          Text(
                            'Ou se connecter avec',
                            style: TextStyle(
                              color: isLight
                                  ? Color(0xFF60438C)
                                  : Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: isLight
                                  ? Color(0xFF60438C).withOpacity(0.3)
                                  : Colors.white24,
                              indent: 10,
                              endIndent: 20,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 18),

                      // Règle App Store 4.8 : Sign in with Apple doit être
                      // proposé au même niveau que le service tiers. Les deux
                      // boutons partagent donc la même rangée, la même largeur
                      // et le même style — aucun des deux n'est mis en avant.
                      Row(
                        children: [
                          Expanded(
                            child: OutlineButton(
                              text: 'Google',
                              iconAsset: 'assets/images/google.png',
                              isLoading: _isGoogleLoading,
                              onTap: _handleGoogleLogin,
                            ),
                          ),
                          // Affiché partout où la connexion Apple peut
                          // réellement aboutir : nativement sur iOS, et sur
                          // Android dès qu'un Services ID est fourni au build.
                          if (FirebaseAuthService.appleProposable) ...[
                            SizedBox(width: 12),
                            Expanded(
                              child: OutlineButton(
                                text: 'Apple',
                                iconAsset: 'assets/images/apple.png',
                                // Le logo est une silhouette monochrome :
                                // sans teinte il disparaîtrait sur le fond
                                // clair, où il est déjà presque blanc.
                                iconColor:
                                    isLight ? Colors.black : Colors.white,
                                isLoading: _isAppleLoading,
                                onTap: _handleAppleLogin,
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
