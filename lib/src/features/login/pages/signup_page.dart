import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:siade2/src/features/login/widgets/widgets.dart';
import 'package:provider/provider.dart';
import 'package:siade2/src/providers/providers.dart';
import 'package:siade2/src/providers/user_provider.dart';

class SignupPage extends StatefulWidget {
  SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _organisationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  String _selectedFunction = 'ETUDIANT';

  /// Acceptation explicite des conditions, exigée par la règle 1.2 de
  /// l'App Store dès lors que l'app diffuse du contenu publié par ses
  /// utilisateurs. Sans cette case, l'inscription est refusée.
  bool _conditionsAcceptees = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _organisationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final organisation = _organisationController.text.trim();
    final phone = _phoneController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty || organisation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
      );
      return;
    }

    if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format d\'email invalide')),
      );
      return;
    }

    if (!_conditionsAcceptees) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vous devez accepter les conditions d\'utilisation pour créer '
            'un compte',
          ),
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le mot de passe doit contenir au moins 6 caractères')),
      );
      return;
    }

    final userData = {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'username': email,
      'password': password,
      'phone': phone,
      'poste': _selectedFunction,
      'organisation': organisation,
    };

    final result = await context.read<UserProvider>().signupFirebase(userData);

    if (mounted) {
      switch (result) {
        case SignupResult.success:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Inscription réussie ! Connectez-vous.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
          break;

        case SignupResult.savedOffline:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                '✅ Inscription réussie !',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
          Navigator.pop(context);
          break;

        case SignupResult.failure:
          final error = context.read<UserProvider>().error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Erreur lors de l\'inscription'),
              backgroundColor: Colors.red,
            ),
          );
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      backgroundColor: isLight ? Color(0xFFE8E8E8) : Color(0xFF0A0E27),
      body: Stack(
        children: [
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

          // Light gray section at bottom (Straight borders, lower position)
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
                            child: OutlineButton(
                              text: 'Connexion',
                              onTap: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: GradientButton(
                              text: 'Inscription',
                              isActive: true,
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 25),

                      CustomTextField(
                        controller: _firstNameController,
                        icon: Icons.person_outline,
                        hint: 'Nom',
                      ),
                      SizedBox(height: 18),

                      CustomTextField(
                        controller: _lastNameController,
                        icon: Icons.person_outline,
                        hint: 'Prénom',
                      ),
                      SizedBox(height: 18),

                      CustomTextField(
                        controller: _emailController,
                        icon: Icons.email_outlined,
                        hint: 'Email',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 18),

                      CustomTextField(
                        controller: _passwordController,
                        icon: Icons.lock_outline,
                        hint: 'Mot de passe',
                        isPassword: true,
                      ),
                      SizedBox(height: 18),

                      // --- Nouveau sélecteur de Fonction / Poste ---
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        decoration: BoxDecoration(
                          color: isLight ? Colors.white.withOpacity(0.5) : Colors.white12,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isLight ? Color(0xFFE0D4ED) : Colors.white24,
                            width: 1,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButtonFormField<String>(
                            value: _selectedFunction,
                            icon: Icon(Icons.keyboard_arrow_down, color: Color(0xFF7B61A8)),
                            decoration: InputDecoration(
                              icon: Icon(Icons.badge_outlined, color: Color(0xFF7B61A8).withOpacity(0.7)),
                              border: InputBorder.none,
                              hintText: 'Choisir votre profil',
                            ),
                            items: [
                              {'label': 'Étudiant', 'value': 'ETUDIANT'},
                              {'label': 'Professionnel', 'value': 'PROFESSIONNEL'},
                              {'label': 'Exposant', 'value': 'EXPOSANT'},
                              {'label': 'Visiteur', 'value': 'VISITEUR'},
                              {'label': 'Autre', 'value': 'AUTRE'},
                            ].map((choice) {
                              return DropdownMenuItem<String>(
                                value: choice['value']!,
                                child: Text(choice['label']!),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedFunction = value!;
                              });
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 18),

                      CustomTextField(
                        controller: _organisationController,
                        icon: Icons.business_outlined,
                        hint: 'Organisation / Établissement',
                      ),
                      SizedBox(height: 18),

                      CustomTextField(
                        controller: _phoneController,
                        icon: Icons.phone_outlined,
                        hint: 'Numéro de téléphone (Optionnel)',
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 18),

                      _construireAcceptationConditions(isLight),
                      SizedBox(height: 18),

                      Consumer<UserProvider>(
                        builder: (context, userProvider, child) {
                          if (userProvider.isLoading) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          return Container(
                            width: double.infinity,
                            height: 55,
                            decoration: BoxDecoration(
                              color: isLight ? Colors.white : Color(0xff2563EB),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: isLight ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ] : null,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: _handleSignup,
                                child: Center(
                                  child: Text(
                                    'S\'inscrire',
                                    style: TextStyle(
                                      color: isLight ? Color(0xFFB8A0D0) : Colors.white,
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
        ],
      ),
    );
  }

  /// Case d'acceptation avec engagement explicite de ne rien publier
  /// d'offensant, et liens vers les conditions et la politique.
  Widget _construireAcceptationConditions(bool isLight) {
    final couleur = isLight ? const Color(0xFF60438C) : Colors.white70;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: _conditionsAcceptees,
            onChanged: (v) =>
                setState(() => _conditionsAcceptees = v ?? false),
            side: BorderSide(color: couleur),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'J\'accepte les ',
                style: TextStyle(color: couleur, fontSize: 13),
              ),
              GestureDetector(
                onTap: () => _ouvrirLien('https://siade.online/condition.html'),
                child: Text(
                  'conditions d\'utilisation',
                  style: TextStyle(
                    color: couleur,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                ' et la ',
                style: TextStyle(color: couleur, fontSize: 13),
              ),
              GestureDetector(
                onTap: () =>
                    _ouvrirLien('https://siade.online/confidentialite.html'),
                child: Text(
                  'politique de confidentialité',
                  style: TextStyle(
                    color: couleur,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '. Je m\'engage à ne publier aucun contenu offensant, '
                'et je comprends qu\'un tel contenu est retiré et son auteur '
                'exclu sans délai.',
                style: TextStyle(color: couleur, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _ouvrirLien(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[SignupPage] Ouverture de $url impossible: $e');
    }
  }
}
