import 'package:flutter/material.dart';
import 'package:siade2/src/commons/data/models.dart';
import 'package:siade2/src/theme/theme.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import 'package:siade2/src/providers/providers.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailsExponents extends StatefulWidget {
  final Exponent exponent;

  const DetailsExponents({super.key, required this.exponent});

  @override
  _DetailsExponentsState createState() => _DetailsExponentsState();
}

class _DetailsExponentsState extends State<DetailsExponents> {
  Future<void> _launch(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _launchPhone(String? phone) async {
    if (phone == null) return;
    await _launch('tel:$phone');
  }

  Future<void> _launchEmail(String? email) async {
    if (email == null) return;
    await _launch('mailto:$email');
  }

  Future<void> _launchWhatsapp(String? phone) async {
    if (phone == null) return;
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    await _launch('https://wa.me/$cleaned');
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final e = widget.exponent;

    return Scaffold(
      backgroundColor: isLight ? Colors.white : Colors.black,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header image ──────────────────────────────────────────────────
          Stack(
            children: [
              Container(
                alignment: Alignment.topLeft,
                width: double.infinity,
                height: 350,
                padding: EdgeInsets.all(30),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: e.imageUrl.startsWith('http')
                        ? NetworkImage(e.imageUrl) as ImageProvider
                        : AssetImage(e.imageUrl),
                    fit: BoxFit.cover,
                    colorFilter: isLight
                        ? null
                        : ColorFilter.mode(
                            Colors.black.withValues(alpha: 0.6),
                            BlendMode.color,
                          ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isLight
                          ? [Colors.transparent, Color(0xFF60438C)]
                          : [Colors.transparent, Colors.black],
                      stops: isLight ? [0.6, 1.0] : null,
                    ),
                  ),
                ),
              ),

              // Bouton retour
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 30,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 15.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: isLight
                          ? Color(0xFF60438C).withValues(alpha:0.3)
                          : Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),

              // Bouton favori
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                right: 30,
                child: Consumer<FavoritesProvider>(
                  builder: (context, favs, _) {
                    final isFav = favs.isFavoriteExponent(e);
                    return GestureDetector(
                      onTap: () => favs.toggleExponent(e),
                      child: Container(
                        width: 15.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: isLight
                              ? Color(0xFF60438C).withValues(alpha:0.3)
                              : Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.red : Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Badge numéro de stand
              if (e.standNumber != null)
                Positioned(
                  bottom: 16,
                  left: 30,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha:0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.place, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Stand ${e.standNumber}',
                          style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // ── Contenu ───────────────────────────────────────────────────────
          Expanded(
            child: Container(
              decoration: isLight
                  ? BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF60438C), Color(0xFFDEDEDE)],
                      ),
                    )
                  : null,
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),

                    // Nom
                    Text(
                      e.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                      ),
                    ),

                    // Description
                    if (e.details.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Text(
                        e.details,
                        textAlign: TextAlign.justify,
                        style: TextStyle(color: Colors.white, fontSize: 14.sp),
                      ),
                    ],

                    // ── Liens sociaux ────────────────────────────────────────
                    if (_hasSocialLinks(e)) ...[
                      SizedBox(height: 24),
                      _buildSocialLinks(e, isLight),
                    ],

                    // ── Contact ──────────────────────────────────────────────
                    if (e.contactEmail != null || e.contactPhone != null) ...[
                      SizedBox(height: 20),
                      _buildContactRow(e, isLight),
                    ],

                    SizedBox(height: 30),

                    // ── Boutons d'action ─────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Visiter Stand (website)
                        GestureDetector(
                          onTap: () => _launch(e.website),
                          child: isLight
                              ? Container(
                                  width: 25.w,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    gradient: LinearGradient(
                                      colors: [Colors.white, Color(0xFFA8A8A8)],
                                    ),
                                  ),
                                  padding: EdgeInsets.all(1.5),
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Color(0xFFA8A8A8), Colors.white],
                                      ),
                                    ),
                                    child: Text(
                                      'Visiter Stand',
                                      style: TextStyle(color: Color(0xFF60438C), fontSize: 12.sp),
                                    ),
                                  ),
                                )
                              : Container(
                                  alignment: Alignment.center,
                                  width: 25.w,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(color: Colors.white),
                                  ),
                                  child: Text(
                                    'Visiter Stand',
                                    style: TextStyle(color: Colors.white, fontSize: 12.sp),
                                  ),
                                ),
                        ),

                        SizedBox(width: 10),

                        // Télécharger bio_file
                        GestureDetector(
                          onTap: () => _launch(e.bioFile),
                          child: Container(
                            alignment: Alignment.center,
                            width: 45.w,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: isLight
                                    ? [Colors.white, Color(0xFF60438C)]
                                    : [AppColors.primaryRed, AppColors.primaryBlue],
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.download, color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Télécharger',
                                  style: TextStyle(color: Colors.white, fontSize: 13.sp),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ── Galerie photos ────────────────────────────────────────
                    if (e.gallery.isNotEmpty) ...[
                      SizedBox(height: 30),
                      Text(
                        'Galerie',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp,
                        ),
                      ),
                      SizedBox(height: 10),
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: e.gallery.length,
                          separatorBuilder: (_, __) => SizedBox(width: 10),
                          itemBuilder: (_, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              e.gallery[i],
                              width: 160,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 160,
                                height: 120,
                                color: Colors.white12,
                                child: Icon(Icons.image, color: Colors.white30),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasSocialLinks(Exponent e) =>
      e.website != null || e.facebook != null ||
      e.twitter != null || e.instagram != null || e.whatsapp != null;

  Widget _buildSocialLinks(Exponent e, bool isLight) {
    final links = <_SocialLink>[
      if (e.website != null) _SocialLink(Icons.language, e.website!, 'Site web'),
      if (e.facebook != null) _SocialLink(Icons.facebook, e.facebook!, 'Facebook'),
      if (e.twitter != null) _SocialLink(Icons.alternate_email, e.twitter!, 'Twitter/X'),
      if (e.instagram != null) _SocialLink(Icons.camera_alt_outlined, e.instagram!, 'Instagram'),
      if (e.whatsapp != null) _SocialLink(Icons.chat, e.whatsapp!, 'WhatsApp', isWhatsapp: true),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: links.map((l) => GestureDetector(
        onTap: () => l.isWhatsapp ? _launchWhatsapp(l.url) : _launch(l.url),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(l.icon, color: Colors.white, size: 16),
              SizedBox(width: 6),
              Text(l.label, style: TextStyle(color: Colors.white, fontSize: 12.sp)),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildContactRow(Exponent e, bool isLight) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        if (e.contactPhone != null)
          GestureDetector(
            onTap: () => _launchPhone(e.contactPhone),
            child: _contactChip(Icons.phone, e.contactPhone!),
          ),
        if (e.contactEmail != null)
          GestureDetector(
            onTap: () => _launchEmail(e.contactEmail),
            child: _contactChip(Icons.email_outlined, e.contactEmail!),
          ),
      ],
    );
  }

  Widget _contactChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 15),
          SizedBox(width: 6),
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 11.sp)),
        ],
      ),
    );
  }
}

class _SocialLink {
  final IconData icon;
  final String url;
  final String label;
  final bool isWhatsapp;
  const _SocialLink(this.icon, this.url, this.label, {this.isWhatsapp = false});
}
