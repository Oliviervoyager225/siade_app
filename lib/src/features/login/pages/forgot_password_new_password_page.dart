import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siade2/src/features/login/pages/forgot_password_success_page.dart';
import 'package:siade2/src/providers/providers.dart';

class ForgotPasswordNewPasswordPage extends StatefulWidget {
  final String email;
  final String code;
  const ForgotPasswordNewPasswordPage({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  State<ForgotPasswordNewPasswordPage> createState() =>
      _ForgotPasswordNewPasswordPageState();
}

class _ForgotPasswordNewPasswordPageState
    extends State<ForgotPasswordNewPasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (password.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Le mot de passe doit contenir au moins 6 caractères')),
      );
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Les mots de passe ne correspondent pas')),
      );
      return;
    }

    final success = await context.read<UserProvider>().resetPasswordWithCode(
          widget.email,
          widget.code,
          password,
        );

    if (mounted) {
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ForgotPasswordSuccessPage(),
          ),
        );
      } else {
        final error = context.read<UserProvider>().error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Erreur lors de la réinitialisation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      backgroundColor:
          isLight ? const Color(0xFFE8E8E8) : const Color(0xFF0A0E27),
      body: Stack(
        children: [
          Positioned(
            top: -40,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.40,
            child: Image.asset('assets/images/back.png', fit: BoxFit.contain),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset('assets/images/logo.png',
                  height: 35, fit: BoxFit.contain),
            ),
          ),
          if (isLight)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.35,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE8E8E8), Color(0xFFF5E6F0)],
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back,
                          color: isLight
                              ? const Color(0xFF7B61A8)
                              : Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.20),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        const Text(
                          'Nouveau mot de passe',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF7B61A8),
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Champ mot de passe
                        Container(
                          height: 55,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5E6F0).withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: const Color(0xFFE0D4ED)),
                          ),
                          child: TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Nouveau mot de passe',
                              hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 14),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 17),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: const Color(0xFF7B61A8),
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Champ confirmation
                        Container(
                          height: 55,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5E6F0).withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: const Color(0xFFE0D4ED)),
                          ),
                          child: TextField(
                            controller: _confirmController,
                            obscureText: _obscureConfirm,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Confirmer le mot de passe',
                              hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 14),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 17),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: const Color(0xFF7B61A8),
                                ),
                                onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Progression 2/2
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '2 sur 2',
                              style: TextStyle(
                                color: const Color(0xFF7B61A8)
                                    .withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 6,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0D4ED),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 1.0,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Color(0xFF7B61A8),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(3)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Consumer<UserProvider>(
                          builder: (context, userProvider, _) {
                            if (userProvider.isLoading) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF7B61A8)),
                                ),
                              );
                            }
                            return Container(
                              width: double.infinity,
                              height: 55,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF8B6FB8),
                                    Color(0xFF7B61A8)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7B61A8)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(30),
                                  onTap: _handleReset,
                                  child: const Center(
                                    child: Text(
                                      'Réinitialiser le mot de passe',
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
                        const SizedBox(height: 30),
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
