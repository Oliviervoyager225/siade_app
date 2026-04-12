import 'package:flutter/material.dart';
import 'package:siade2/src/commons/widgets/optimized_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';
import 'package:siade2/l10n/app_localizations.dart';
import 'package:siade2/src/features/home/widgets/widgets.dart';
import 'package:siade2/src/features/socialnetwork/pages/create_post_page.dart';
import '../../../../gen/assets.gen.dart';
import 'package:provider/provider.dart';
import 'package:siade2/src/providers/providers.dart';
import 'package:sizer/sizer.dart';
//import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _feedKey = GlobalKey<FeedRefreshState>();

  @override
  void initState() {
    super.initState();
    // Charger les données dès l'ouverture de l'app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataProvider>().loadAllData();
    });
  }

  Future<void> _onRefresh() async {
    context.read<DataProvider>().loadAllData();
    _feedKey.currentState?.refresh();
    // Petite pause pour que l'indicateur soit visible
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: isLight ? Colors.white : null,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: const Color(0xFF60438C),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
          spacing: 20.0,
          children: [
            Gap(15),
            Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo SIADE
                  Image.asset(
                    isLight ? 'assets/images/logo23.png' : 'assets/images/logosiade.png',
                    height: 18,
                    fit: BoxFit.contain,
                    color: isLight ? const Color(0xFF180468) : null,
                  ),
                  Row(
                    children: [
                      Assets.images.language.image(
                        width: 18,
                        height: 18,
                        color: isLight ? Color(0xFF180468) : null,
                      ),
                      PopupMenuButton<String>(
                        onSelected: (String code) {
                          localeProvider.setLocale(Locale(code));
                        },
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: isLight ? Color(0xFF180468) : Colors.white70,
                        ),
                        iconSize: 20,
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'fr', child: Text(l10n.french)),
                          PopupMenuItem(value: 'en', child: Text(l10n.english)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            CarouselImages(),
            Speakers(),
            Exponents(),
            Programs(),
            News(),
            _PostCreationBar(),
            FeedRefresh(key: _feedKey),
          ],
        ),
        ),
      ),
    );
  }
}

// ─── Barre de création de post ────────────────────────────────────────────────

class _PostCreationBar extends StatelessWidget {
  const _PostCreationBar();

  void _openCreate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreatePostScreen()),
    );
  }



  /// Calcule les initiales depuis les données utilisateur ou l'email.
  String _buildInitials(Map<String, dynamic>? userData, String email) {
    final firstName = (userData?['first_name'] ?? '').toString().trim();
    if (firstName.isNotEmpty) return firstName[0].toUpperCase();

    final lastName = (userData?['last_name'] ?? '').toString().trim();
    if (lastName.isNotEmpty) return lastName[0].toUpperCase();

    final displayName = (userData?['displayName'] ?? '').toString().trim();
    if (displayName.isNotEmpty) return displayName[0].toUpperCase();

    final local = email.split('@').first;
    if (local.isNotEmpty) return local[0].toUpperCase();

    return '?';
  }
  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final l10n = AppLocalizations.of(context)!;

    // Récupérer les données utilisateur depuis UserProvider (fonctionne Django + Firebase)
    final userProvider = context.watch<UserProvider>();
    final userData = userProvider.user;

    // Photo de profil : UserProvider d'abord (réactif), sinon Firebase Auth cache
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final photoUrl = (userData?['photoURL'] ?? userData?['photo'] ?? firebaseUser?.photoURL ?? '').toString();

    // Initiales depuis prénom+nom, sinon depuis l'email (ex: olivier.dakouri → OD)
    final initials = _buildInitials(userData, userData?['email']?.toString() ?? firebaseUser?.email ?? '');

    final bgColor = isLight ? const Color(0xFFF0EEF8) : const Color(0xFF150B3A);
    final borderColor = isLight ? const Color(0xFF60438C).withValues(alpha: 0.15) : Colors.white12;
    final hintColor = isLight ? const Color(0xFF60438C).withValues(alpha: 0.5) : Colors.white38;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => _openCreate(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: borderColor),
            boxShadow: isLight
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))]
                : null,
          ),
          child: Row(
            children: [
              // Avatar utilisateur connecté
              OptimizedAvatar(
                radius: 18,
                imageUrl: photoUrl,
                fallbackText: initials,
              ),
              const SizedBox(width: 10),
              // Texte placeholder
              Expanded(
                child: Text(
                  l10n.whatOnYourMind,
                  style: TextStyle(
                    color: hintColor,
                    fontSize: 16.sp,
                  ),
                ),
              ),
              // Bouton image
              GestureDetector(
                onTap: () => _openCreate(context),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xffD4007A).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.image_outlined,
                    color: Color(0xffD4007A),
                    size: 20,
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
