
import 'package:siade2/src/core/constants/api_constants.dart';

class Speaker {
  final String imageUrl;
  final String name;
  final String job;
  final String details;
  final String? linkedinUrl;
  final String? facebookUrl;
  final String? tiktokUrl;
  final String? instagramUrl;
  final String? youtubeUrl;

  Speaker({
    required this.imageUrl,
    required this.name,
    required this.job,
    required this.details,
    this.linkedinUrl,
    this.facebookUrl,
    this.tiktokUrl,
    this.instagramUrl,
    this.youtubeUrl,
  });

  factory Speaker.fromJson(Map<String, dynamic> json) {
    // On construit le nom complet à partir de first_name et last_name de l'API
    final firstName = json['first_name'] ?? '';
    final lastName = json['last_name'] ?? '';
    
    // On gère l'URL de l'image (si c'est un chemin relatif, on ajoute le baseUrl)
    String img = json['image'] ?? '';
    if (img.isNotEmpty && !img.startsWith('http')) {
      img = "${ApiConstants.baseUrl}$img";
    }

    String name;
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      name = "$firstName\n$lastName";
    } else {
      name = "$firstName$lastName".trim();
    }
    // Fix overflow: "BRAHIMA OUATTARA\nTENE" → "BRAHIMA\nOUATTARA TENE"
    if (name == 'BRAHIMA OUATTARA\nTENE') name = 'BRAHIMA\nOUATTARA TENE';

    return Speaker(
      imageUrl: img.isNotEmpty ? img : 'assets/images/default_speaker.png',
      name: name,
      job: json['description'] ?? 'Speaker', // On utilise description comme "job" si besoin
      details: json['description'] ?? '',
      linkedinUrl: _nonEmpty(json['linkedin_url']),
      facebookUrl: _nonEmpty(json['facebook_url']),
      tiktokUrl: _nonEmpty(json['tiktok_url']),
      instagramUrl: _nonEmpty(json['instagram_url']),
      youtubeUrl: _nonEmpty(json['youtube_url']),
    );
  }

  static String? _nonEmpty(dynamic val) {
    if (val == null) return null;
    final s = val.toString().trim();
    return s.isEmpty ? null : s;
  }
}

final List<Speaker> speakers = [
  Speaker(
    imageUrl: 'assets/images/speaker_1.jpg',
    name: 'Amelie Lens',
    job: 'CEO SaH',
    details: """Lorem ipsum dolor sit amet, consectetur elit adipiscing elit. Venenatis pulvinar a amet in, suspendisse vitae, posuere eu tortor et. Und commodo, fermentum, mauris leo eget.
    Lorem ipsum dolor sit amet, consectetur elit adipiscing elit. Venenatis pulvinar a amet in, suspendisse vitae, posuere eu tortor et. Und commodo, fermentum, mauris leo eget.""",
  ),
  Speaker(
    imageUrl: 'assets/images/speaker_2.png',
    name: 'Amelie Lens',
    job: 'CEO SaH',
    details: """Lorem ipsum dolor sit amet, consectetur elit adipiscing elit. Venenatis pulvinar a amet in, suspendisse vitae, posuere eu tortor et. Und commodo, fermentum, mauris leo eget.
    Lorem ipsum dolor sit amet, consectetur elit adipiscing elit. Venenatis pulvinar a amet in, suspendisse vitae, posuere eu tortor et. Und commodo, fermentum, mauris leo eget.""",
  ),
  Speaker(
    imageUrl: 'assets/images/speaker_3.jpg',
    name: 'Amelie Lens',
    job: 'CEO SaH',
    details: """Lorem ipsum dolor sit amet, consectetur elit adipiscing elit. Venenatis pulvinar a amet in, suspendisse vitae, posuere eu tortor et. Und commodo, fermentum, mauris leo eget.
    Lorem ipsum dolor sit amet, consectetur elit adipiscing elit. Venenatis pulvinar a amet in, suspendisse vitae, posuere eu tortor et. Und commodo, fermentum, mauris leo eget.""",
  ),
  Speaker(
    imageUrl: 'assets/images/speaker_1.jpg',
    name: 'Amelie Lens',
    job: 'CEO SaH',
    details: """Lorem ipsum dolor sit amet, consectetur elit adipiscing elit. Venenatis pulvinar a amet in, suspendisse vitae, posuere eu tortor et. Und commodo, fermentum, mauris leo eget.
    Lorem ipsum dolor sit amet, consectetur elit adipiscing elit. Venenatis pulvinar a amet in, suspendisse vitae, posuere eu tortor et. Und commodo, fermentum, mauris leo eget.""",
  ),
  Speaker(
    imageUrl: 'assets/images/speaker_2.png',
    name: 'Amelie Lens',
    job: 'CEO SaH',
    details: """Lorem ipsum dolor sit amet, consectetur elit adipiscing elit. Venenatis pulvinar a amet in, suspendisse vitae, posuere eu tortor et. Und commodo, fermentum, mauris leo eget.
    Lorem ipsum dolor sit amet, consectetur elit adipiscing elit. Venenatis pulvinar a amet in, suspendisse vitae, posuere eu tortor et. Und commodo, fermentum, mauris leo eget.""",
  ),
  Speaker(
    imageUrl: 'assets/images/speaker_3.jpg',
    name: 'Amelie Lens',
    job: 'CEO SaH',
    details: """Lorem ipsum dolor sit amet, consectetur elit adipiscing elit. Venenatis pulvinar a amet in, suspendisse vitae, posuere eu tortor et. Und commodo, fermentum, mauris leo eget.
    Lorem ipsum dolor sit amet, consectetur elit adipiscing elit. Venenatis pulvinar a amet in, suspendisse vitae, posuere eu tortor et. Und commodo, fermentum, mauris leo eget.""",
  ),
  Speaker(
    imageUrl: 'assets/images/speaker_1.jpg',
    name: 'Amelie Lens',
    job: 'CEO SaH',
    details: """Lorem ipsum dolor sit amet, consectetur elit adipiscing elit. Venenatis pulvinar a amet in, suspendisse vitae, posuere eu tortor et. Und commodo, fermentum, mauris leo eget.
    Lorem ipsum dolor sit amet, consectetur elit adipiscing elit. Venenatis pulvinar a amet in, suspendisse vitae, posuere eu tortor et. Und commodo, fermentum, mauris leo eget.""",
  ),
  Speaker(
    imageUrl: 'assets/images/speaker_2.png',
    name: 'Amelie Lens',
    job: 'CEO SaH',
    details: """Lorem ipsum dolor sit amet, consectetur elit adipiscing elit. Venenatis pulvinar a amet in, suspendisse vitae, posuere eu tortor et. Und commodo, fermentum, mauris leo eget.
    Lorem ipsum dolor sit amet, consectetur elit adipiscing elit. Venenatis pulvinar a amet in, suspendisse vitae, posuere eu tortor et. Und commodo, fermentum, mauris leo eget.""",
  ),
  Speaker(
    imageUrl: 'assets/images/speaker_3.jpg',
    name: 'Amelie Lens',
    job: 'CEO SaH',
    details: """Lorem ipsum dolor sit amet, consectetur elit adipiscing elit. Venenatis pulvinar a a
    met in, suspendisse vitae, posuere eu tortor et. Und commodo, fermentum, mauris leo eg.
    Lorem ipsum dolor sit amet, consectetur elit adipiscing elit. Venenatis pulvinar a amet in, suspendisse vitae, posuere eu tortor et. Und commodo, fermentum, mauris leo eget.t.""",
  ),
];