import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:siade2/src/commons/widgets/optimized_image.dart';
import 'package:siade2/src/features/home/pages/blocked_users_page.dart';
import 'package:provider/provider.dart';
import 'package:siade2/l10n/app_localizations.dart';
import 'package:siade2/src/features/home/pages/pages.dart';
import 'package:siade2/src/features/socialnetwork/pages/page.dart';
import 'package:siade2/src/features/maps/pages/maps_page.dart';
import 'package:siade2/src/providers/providers.dart';
import 'package:siade2/src/theme/colors/app_colors.dart';
import 'package:siade2/src/features/welcome/welcome_page.dart';

import '../../../../gen/assets.gen.dart';

//import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CustomDrawer extends StatefulWidget {
  final VoidCallback onGoHome;

  const CustomDrawer({super.key, required this.onGoHome});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  bool _languageExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLanguage = localeProvider.locale?.languageCode == 'en'
        ? l10n.english
        : l10n.french;

    return Scaffold(
      backgroundColor: isLight
          ? const Color(0xFFEAEAEA)
          : const Color(0xFF0F0026),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(35),
            color: isLight
                ? Colors.white
                : const Color(0xFF1E1B3A).withOpacity(0.5),
            boxShadow: isLight
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 30.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Profile Header ---
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    final user = userProvider.user;
                    return Row(
                      children: [
                        OptimizedAvatar(
                          imageUrl: user?['photoURL'] ?? user?['photo'],
                          fallbackText: _getDisplayName(user),
                          radius: 30,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getDisplayName(user),
                                style: TextStyle(
                                  color: isLight
                                      ? const Color(0xFF423B69)
                                      : Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getSubtitle(user),
                                style: TextStyle(
                                  color: isLight ? Colors.black45 : Colors.grey,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onGoHome,
                          child: Container(
                            height: 32,
                            width: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isLight
                                  ? const Color(0xFFF0F4FF)
                                  : Colors.white10,
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Color(0xffAB638C),
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 40),

                // --- Menu Content ---
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // --- Langue Dropdown ---
                        GestureDetector(
                          onTap: () => setState(
                            () => _languageExpanded = !_languageExpanded,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              color: const Color(0xFF423B69),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                            child: Row(
                              children: [
                                Assets.images.language.image(
                                  width: 24,
                                  height: 24,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  l10n.language,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  _languageExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (_languageExpanded) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Column(
                              children: [
                                _buildLanguageOption(
                                  l10n.english,
                                  'en',
                                  isLight,
                                  localeProvider,
                                ),
                                _buildLanguageOption(
                                  l10n.french,
                                  'fr',
                                  isLight,
                                  localeProvider,
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 25),

                        // --- Section Thème ---
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isLight
                                ? Colors.transparent
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Provider.of<ThemeProvider>(
                                          context,
                                        ).isDarkMode
                                        ? Icons.dark_mode
                                        : Icons.light_mode,
                                    color: isLight
                                        ? const Color(0xFF423B69)
                                        : Colors.white,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    l10n.darkMode,
                                    style: TextStyle(
                                      color: isLight
                                          ? const Color(
                                              0xFF423B69,
                                            ).withOpacity(0.8)
                                          : Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Switch(
                                value: Provider.of<ThemeProvider>(
                                  context,
                                ).isDarkMode,
                                onChanged: (_) {
                                  Provider.of<ThemeProvider>(
                                    context,
                                    listen: false,
                                  ).toggleTheme();
                                },
                                activeColor: const Color(0xffAB638C),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 15),

                        // --- Other Menu items ---
                        _buildMenuItem(
                          Assets.images.gallery.image(
                            width: 22,
                            height: 22,
                            color: isLight
                                ? const Color(0xFF423B69)
                                : Colors.white,
                          ),
                          l10n.gallery,
                          isLight,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GalleryPage(),
                            ),
                          ),
                        ),
                        _buildMenuItem(
                          Assets.images.location.image(
                            width: 22,
                            height: 22,
                            color: isLight
                                ? const Color(0xFF423B69)
                                : Colors.white,
                          ),
                          l10n.location,
                          isLight,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MapsNavigationScreen(),
                            ),
                          ),
                        ),
                        _buildMenuItem(
                          Assets.images.live.image(
                            width: 22,
                            height: 22,
                            color: isLight
                                ? const Color(0xFF423B69)
                                : Colors.white,
                          ),
                          l10n.live,
                          isLight,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LivesListPage(),
                            ),
                          ),
                        ),
                        _buildMenuItem(
                          Assets.images.restaurant.image(
                            width: 22,
                            height: 22,
                            color: isLight
                                ? const Color(0xFF423B69)
                                : Colors.white,
                          ),
                          l10n.restaurant,
                          isLight,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RestaurantPage(),
                            ),
                          ),
                        ),
                        // Sécurité et confidentialité : Apple attend un accès
                        // à ces trois écrans depuis l'app elle-même.
                        _buildMenuItem(
                          Icon(
                            Icons.block,
                            color: isLight
                                ? const Color(0xFF423B69)
                                : Colors.white,
                            size: 22,
                          ),
                          'Comptes bloqués',
                          isLight,
                          () => ouvrirComptesBloques(context),
                        ),
                        _buildMenuItem(
                          Icon(
                            Icons.privacy_tip_outlined,
                            color: isLight
                                ? const Color(0xFF423B69)
                                : Colors.white,
                            size: 22,
                          ),
                          'Confidentialité',
                          isLight,
                          () => _ouvrirLien(
                              'https://siade.online/confidentialite.html'),
                        ),
                        _buildMenuItem(
                          Icon(
                            Icons.description_outlined,
                            color: isLight
                                ? const Color(0xFF423B69)
                                : Colors.white,
                            size: 22,
                          ),
                          'Conditions d\'utilisation',
                          isLight,
                          () => _ouvrirLien(
                              'https://siade.online/condition.html'),
                        ),
                        _buildMenuItem(
                          const Icon(
                            Icons.logout,
                            color: Colors.redAccent,
                            size: 22,
                          ),
                          l10n.logout,
                          isLight,
                          () async {
                            await context.read<UserProvider>().logout();
                            if (mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WelcomePage(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // --- SIADE Logo at bottom ---
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                        children: [
                          TextSpan(
                            text: 'SI',
                            style: TextStyle(
                              color: isLight
                                  ? Colors.grey[400]
                                  : Colors.white24,
                            ),
                          ),
                          const TextSpan(
                            text: 'A',
                            style: TextStyle(color: Color(0xFF64B5F6)),
                          ),
                          TextSpan(
                            text: 'DE',
                            style: TextStyle(
                              color: isLight
                                  ? Colors.grey[400]
                                  : Colors.white24,
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
        ),
      ),
    );
  }

  // ── Avatar color by letter ────────────────────────────────────────────────
  static const List<Color> _letterColors = [
    Color(0xFF1565C0), Color(0xFF6A1B9A), Color(0xFF00838F), Color(0xFFAD1457),
    Color(0xFF2E7D32), Color(0xFFE65100), Color(0xFF4527A0), Color(0xFF00695C),
    Color(0xFFC62828), Color(0xFF37474F), Color(0xFFD84315), Color(0xFF1B5E20),
    Color(0xFF880E4F), Color(0xFF0D47A1), Color(0xFF4A148C), Color(0xFF006064),
    Color(0xFFBF360C), Color(0xFF1A237E), Color(0xFF558B2F), Color(0xFF827717),
    Color(0xFF4E342E), Color(0xFF01579B), Color(0xFF33691E), Color(0xFF6D4C41),
    Color(0xFF283593), Color(0xFF004D40),
  ];

  Color _avatarColor(String initial) {
    if (initial.isEmpty || initial == '?') return const Color(0xFF423B69);
    final idx = initial.toUpperCase().codeUnitAt(0) - 'A'.codeUnitAt(0);
    if (idx < 0 || idx >= _letterColors.length) return const Color(0xFF423B69);
    return _letterColors[idx];
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _getDisplayName(Map<String, dynamic>? user) {
    if (user == null) return 'Utilisateur';
    final first = (user['first_name'] ?? '').toString().trim();
    final last = (user['last_name'] ?? '').toString().trim();
    if (first.isNotEmpty) return last.isNotEmpty ? '$first $last' : first;
    final username = (user['username'] ?? user['name'] ?? '').toString().trim();
    if (username.isNotEmpty && !username.contains('@')) return username;
    if (username.contains('@')) return username.split('@').first;
    return 'Utilisateur';
  }

  String _getSubtitle(Map<String, dynamic>? user) {
    final poste = (user?['poste'] ?? '').toString().trim();
    return poste.isNotEmpty ? poste.toUpperCase() : 'VISITEUR';
  }

  String _getInitial(Map<String, dynamic>? user) {
    if (user == null) return '?';
    final first = (user['first_name'] ?? '').toString().trim();
    if (first.isNotEmpty) return first[0].toUpperCase();
    final username = (user['username'] ?? user['name'] ?? '').toString().trim();
    if (username.isNotEmpty && !username.contains('@')) return username[0].toUpperCase();
    if (username.contains('@')) {
      final local = username.split('@').first;
      if (local.isNotEmpty) return local[0].toUpperCase();
    }
    return '?';
  }


  Widget _buildLanguageOption(
    String label,
    String langCode,
    bool isLight,
    LocaleProvider localeProvider,
  ) {
    final bool isSelected = localeProvider.locale?.languageCode == langCode;
    return GestureDetector(
      onTap: () {
        localeProvider.setLocale(Locale(langCode));
        setState(() {
          _languageExpanded = false;
        });
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 6, left: 10, right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isLight ? const Color(0xFF635A8E) : Colors.white10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isLight
                      ? const Color(0xFF423B69).withOpacity(0.7)
                      : Colors.grey),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Future<void> _ouvrirLien(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[CustomDrawer] Ouverture de $url impossible: $e');
    }
  }

  Widget _buildMenuItem(
    Widget icon,
    String label,
    bool isLight,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        child: Row(
          children: [
            SizedBox(width: 32, child: Center(child: icon)),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: isLight
                    ? const Color(0xFF423B69).withOpacity(0.8)
                    : Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
