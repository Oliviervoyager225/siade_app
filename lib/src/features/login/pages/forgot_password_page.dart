import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siade2/src/features/login/pages/forgot_password_code_page.dart';
import 'package:siade2/src/features/login/widgets/widgets.dart';
import 'package:siade2/src/providers/providers.dart';
import 'package:sizer/sizer.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez saisir votre adresse e-mail')),
      );
      return;
    }

    final success = await context.read<UserProvider>().sendPasswordResetEmail(email);

    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ForgotPasswordCodePage(email: email),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<UserProvider>().error ?? 'Erreur lors de l\'envoi')),
      );
    }
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

          // Logo SIADE on robot torso
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

          // Light mode background section
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
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.28),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        Text(
                          'Réinitialiser le mot de passe',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF7B61A8),
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.12),
                        Text(
                          'Nous vous enverrons par e-mail un code pour réinitialiser votre mot de passe.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF6B8CFF),
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 30),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: 5, bottom: 8),
                            child: Text(
                              'Email',
                              style: TextStyle(
                                color: Color(0xFF7B61A8).withOpacity(0.7),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          height: 55,
                          decoration: BoxDecoration(
                            color: Color(0xFFF5E6F0).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Color(0xFFE0D4ED),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _emailController,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Exemple@gmail.com',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 17),
                            ),
                          ),
                        ),
                        SizedBox(height: 50),
                        Consumer<UserProvider>(
                          builder: (context, userProvider, child) {
                            if (userProvider.isLoading) {
                              return Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7B61A8)),
                                ),
                              );
                            }
                            return Container(
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
                                  onTap: _handleSendEmail,
                                  child: Center(
                                    child: Text(
                                      'Envoyer',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 30),
                      ],
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
