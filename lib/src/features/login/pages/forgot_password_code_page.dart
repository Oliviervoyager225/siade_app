import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:siade2/src/features/login/pages/forgot_password_new_password_page.dart';
import 'package:siade2/src/providers/providers.dart';
import 'package:siade2/src/features/login/widgets/widgets.dart';

class ForgotPasswordCodePage extends StatefulWidget {
  final String email;
  const ForgotPasswordCodePage({super.key, required this.email});

  @override
  State<ForgotPasswordCodePage> createState() => _ForgotPasswordCodePageState();
}

class _ForgotPasswordCodePageState extends State<ForgotPasswordCodePage> with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showEmailSent = true;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    // Hide email sent message after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showEmailSent = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleCodeInput(int index, String value) {
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }

    setState(() {
      _progress = _controllers.where((c) => c.text.isNotEmpty).length / 4.0;
    });

    // Check if all fields are filled
    if (_controllers.every((controller) => controller.text.isNotEmpty)) {
      _verifyCode();
    }
  }

  void _handleBackspace(int index) {
    if (index > 0 && _controllers[index].text.isEmpty) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verifyCode() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length < 4) return;

    final success = await context.read<UserProvider>().verifyResetCode(widget.email, code);

    if (!mounted) return;
    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ForgotPasswordNewPasswordPage(
            email: widget.email,
            code: code,
          ),
        ),
      );
    } else {
      final error = context.read<UserProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Code incorrect'),
          backgroundColor: Colors.red,
        ),
      );
      // Vider les champs
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
      setState(() => _progress = 0.0);
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
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.20),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        // Email sent animation
                        if (_showEmailSent)
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF7B61A8),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    Icons.mail_outline,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                                Text(
                                  'Nous avons envoyé un e-mail à',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF7B61A8).withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  widget.email,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF000000),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'avec des instructions pour réinitialiser votre mot de passe.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF7B61A8).withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 50),
                              ],
                            ),
                          ),

                        if (!_showEmailSent) ...[
                          Text(
                            'Réinitialiser le mot de passe',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF7B61A8),
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                          Text(
                            'Vérifier',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF7B61A8),
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 30),
                        ],

                        Text(
                          'Veuillez saisir le code que nous vous avons envoyé par e-mail',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF7B61A8).withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 40),

                        // Code input fields
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(4, (index) {
                            return Container(
                              width: 65,
                              height: 65,
                              decoration: BoxDecoration(
                                color: Color(0xFFF5E6F0).withOpacity(0.5),
                                border: Border.all(
                                  color: Color(0xFFD4C4E8),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: TextField(
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                maxLength: 1,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  border: InputBorder.none,
                                ),
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                onChanged: (value) => _handleCodeInput(index, value),
                                onTap: () {
                                  _controllers[index].selection = TextSelection.fromPosition(
                                    TextPosition(offset: _controllers[index].text.length),
                                  );
                                },
                              ),
                            );
                          }),
                        ),
                        SizedBox(height: 25),

                        // Resend code
                        Column(
                          children: [
                            Text(
                              "Vous n'avez pas reçu le code ?",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF7B61A8).withOpacity(0.7),
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 5),
                            TextButton(
                              onPressed: () {
                                context.read<UserProvider>().sendPasswordResetEmail(widget.email);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Nouveau code envoyé !')),
                                );
                              },
                              child: Text(
                                "Renvoyer le code",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF7B61A8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 30),

                        // Progress indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '1 sur 2',
                              style: TextStyle(
                                color: Color(0xFF7B61A8).withOpacity(0.7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Container(
                          height: 6,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Color(0xFFE0D4ED),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: AnimatedFractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _progress,
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(0xFF7B61A8),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 40),

                        Container(
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
                              onTap: _verifyCode,
                              child: Center(
                                child: Consumer<UserProvider>(
                                  builder: (context, userProvider, _) {
                                    if (userProvider.isLoading) {
                                      return const SizedBox(
                                        width: 24, height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2,
                                        ),
                                      );
                                    }
                                    return const Text(
                                      'Continuer',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
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
