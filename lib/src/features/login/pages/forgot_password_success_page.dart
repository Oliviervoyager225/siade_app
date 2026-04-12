import 'package:flutter/material.dart';
import 'package:siade2/src/features/login/pages/login.dart';
import 'package:siade2/src/features/login/widgets/widgets.dart';
import 'package:sizer/sizer.dart';

class ForgotPasswordSuccessPage extends StatefulWidget {
  final String? email;
  const ForgotPasswordSuccessPage({super.key, this.email});

  @override
  State<ForgotPasswordSuccessPage> createState() => _ForgotPasswordSuccessPageState();
}

class _ForgotPasswordSuccessPageState extends State<ForgotPasswordSuccessPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      backgroundColor: isLight ? Color(0xFFE8E8E8) : Color(0xFF0A0E27),
      body: Stack(
        children: [
          // Background image
          Positioned(
            top: -40,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.40,
            child: Image.asset('assets/images/back.png', fit: BoxFit.contain),
          ),

          // Logo SIADE
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: 35,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Light mode background
          if (isLight)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.35,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFE8E8E8),
                      Color(0xFFF5E6F0),
                    ],
                  ),
                ),
              ),
            ),

          SafeArea(
            child: Column(
              children: [
                // Back button
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: isLight ? Color(0xFF7B61A8) : Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        children: [
                          Text(
                            'Mot de passe réinitialisé !',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF7B61A8),
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 40),

                          // Success animation
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                color: Color(0xFFD4C4E8),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                size: 70,
                                color: Color(0xFF7B61A8),
                              ),
                            ),
                          ),
                          SizedBox(height: 50),

                          // Success message
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              children: [
                                Text(
                                  'Succès !',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'Votre mot de passe a été réinitialisé avec succès.\n\nVous pouvez maintenant vous connecter avec votre nouveau mot de passe.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 14,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 70),

                          // Login button
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Container(
                              width: double.infinity,
                              height: 55,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF8B6FB8), Color(0xFF7B61A8)],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF7B61A8).withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(30),
                                  onTap: () {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(builder: (context) => Login()),
                                      (route) => false,
                                    );
                                  },
                                  child: Center(
                                    child: Text(
                                      'Se connecter',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
