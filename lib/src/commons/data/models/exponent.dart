import 'package:siade2/src/core/constants/api_constants.dart';

class Exponent {
  final String imageUrl;
  final String name;
  final String job;
  final String details;
  final String? slug;
  final String? standNumber;
  final String? bioFile;
  final String? website;
  final String? facebook;
  final String? twitter;
  final String? instagram;
  final String? whatsapp;
  final String? contactEmail;
  final String? contactPhone;
  final List<String> gallery;

  Exponent({
    required this.imageUrl,
    required this.name,
    required this.job,
    required this.details,
    this.slug,
    this.standNumber,
    this.bioFile,
    this.website,
    this.facebook,
    this.twitter,
    this.instagram,
    this.whatsapp,
    this.contactEmail,
    this.contactPhone,
    this.gallery = const [],
  });

  factory Exponent.fromJson(Map<String, dynamic> json) {
    // logo (exhibitors API) ou photo (ancien exposant API)
    String img = (json['logo'] as String?) ?? (json['photo'] as String?) ?? '';
    if (img.isNotEmpty && !img.startsWith('http')) {
      img = '${ApiConstants.baseUrl}$img';
    }

    // bio_file
    String? bioFile = json['bio_file'] as String?;
    if (bioFile != null && bioFile.isNotEmpty && !bioFile.startsWith('http')) {
      bioFile = '${ApiConstants.baseUrl}$bioFile';
    }

    // gallery
    final galleryRaw = json['gallery'] as List<dynamic>? ?? [];
    final gallery = galleryRaw
        .map((g) => (g is Map) ? (g['image'] as String? ?? '') : '')
        .where((url) => url.isNotEmpty)
        .map((url) => url.startsWith('http') ? url : '${ApiConstants.baseUrl}$url')
        .toList();

    return Exponent(
      imageUrl: img.isNotEmpty ? img : 'assets/images/exposant.jpg',
      name: (json['name'] as String?) ?? (json['nom'] as String?) ?? '',
      job: (json['description'] as String?) ?? '',
      details: (json['description'] as String?) ?? '',
      slug: json['slug'] as String?,
      standNumber: json['stand_number'] as String?,
      bioFile: (bioFile != null && bioFile.isNotEmpty) ? bioFile : null,
      website: _nonEmpty(json['website']),
      facebook: _nonEmpty(json['facebook']),
      twitter: _nonEmpty(json['twitter']),
      instagram: _nonEmpty(json['instagram']),
      whatsapp: _nonEmpty(json['whatsapp']),
      contactEmail: _nonEmpty(json['contact_email']),
      contactPhone: _nonEmpty(json['contact_phone']),
      gallery: gallery,
    );
  }

  static String? _nonEmpty(dynamic val) {
    if (val == null) return null;
    final s = val.toString().trim();
    return s.isEmpty ? null : s;
  }
}
