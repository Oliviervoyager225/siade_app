import 'package:intl/intl.dart';
import 'package:siade2/src/core/constants/api_constants.dart';
import 'speaker.dart';

class Program {
  final String imageUrl;
  final String title;
  final String date;       // ex: "2026-04-09"
  final String? dayLabel;   // ex: "Jour 1" ou "Jour 2"
  final String details;
  final String? room;
  final String? startTime; // ex: "08:30:00"
  final String? endTime;   // ex: "09:50:00"
  final List<Speaker> speakers; // intervenants liés à ce programme

  Program({
    required this.imageUrl,
    required this.title,
    required this.date,
    this.dayLabel,
    required this.details,
    this.room,
    this.startTime,
    this.endTime,
    this.speakers = const [],
  });

  factory Program.fromJson(Map<String, dynamic> json) {
    // day_of_participation "1" ou "2" → vraie date de l'événement
    final day = json['day_of_participation']?.toString() ?? '1';
    final realDate = day == '2' ? ApiConstants.eventDay2 : ApiConstants.eventDay1;
    final dayLabel = day == '2' ? 'Jour 2' : 'Jour 1';

    // Image: depuis le backend si renseignée, sinon asset par défaut
    final apiImg = (json['image'] as String?) ?? '';
    String imageUrl;
    if (apiImg.isNotEmpty) {
      imageUrl = apiImg.startsWith('http') ? apiImg : '${ApiConstants.baseUrl}$apiImg';
    } else {
      imageUrl = '';
    }

    // Intervenants depuis speakers_detail
    final speakersList = <Speaker>[];
    final rawSpeakers = json['speakers_detail'];
    if (rawSpeakers is List) {
      for (final s in rawSpeakers) {
        if (s is Map<String, dynamic>) speakersList.add(Speaker.fromJson(s));
      }
    }

    return Program(
      imageUrl: imageUrl,
      title: (json['title'] as String?) ?? '',
      date: realDate,
      dayLabel: dayLabel,
      details: (json['description'] as String?) ?? '',
      room: json['room'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      speakers: speakersList,
    );
  }

  /// Retourne [jour_2_chiffres, MOIS_3_LETTRES] ex: ["09", "APR"]
  List<String> convertDate() {
    try {
      final dt = DateFormat('yyyy-MM-dd').parse(date);
      final day = dt.day.toString().padLeft(2, '0');
      final month = DateFormat('MMM').format(dt);
      return [day, month];
    } catch (_) {
      return ['09', 'AVR'];
    }
  }

  /// Formate "08:30:00" → "08:30"
  String? get formattedStartTime =>
      startTime != null && startTime!.length >= 5 ? startTime!.substring(0, 5) : startTime;
}

final List<Program> programs = [
  Program(
    imageUrl: 'assets/images/program_1.jpg',
    title: 'IA DEFENSE & ESPACE',
    date: '2026-12-21',
    details: """Lorem ipsum dolor sit amet, consectetur elit adipiscing elit. Venenatis pulvinar a a
    met in, suspendisse vitae, posuere eu tortor et. Und commodo, fermentum, mauris leo eg.
    Lorem ipsum dolor sit amet, consectetur elit adipiscing elit. Venenatis pulvinar a amet in, suspendisse vitae, posuere eu tortor et. Und commodo, fermentum, mauris leo eget.t.""",
  ),
  Program(
    imageUrl: 'assets/images/program_2.jpg',
    title: 'Fire Store',
    date: '2026-12-22',
    details: """Lorem ipsum dolor sit amet, consectetur elit adipiscing elit. Venenatis pulvinar a a
    met in, suspendisse vitae, posuere eu tortor et. Und commodo, fermentum, mauris leo eg.
    Lorem ipsum dolor sit amet, consectetur elit adipiscing elit. Venenatis pulvinar a amet in, suspendisse vitae, posuere eu tortor et. Und commodo, fermentum, mauris leo eget.t.""",
  ),
  Program(
    imageUrl: 'assets/images/program_1.jpg',
    title: 'IA DEFENSE & ESPACE',
    date: '2026-12-21',
    details: """Lorem ipsum dolor sit amet, consectetur elit adipiscing elit. Venenatis pulvinar a a
    met in, suspendisse vitae, posuere eu tortor et. Und commodo, fermentum, mauris leo eg.
    Lorem ipsum dolor sit amet, consectetur elit adipiscing elit. Venenatis pulvinar a amet in, suspendisse vitae, posuere eu tortor et. Und commodo, fermentum, mauris leo eget.t.""",
  ),
  Program(
    imageUrl: 'assets/images/program_2.jpg',
    title: 'Fire Store',
    date: '2026-12-22',
    details: """Lorem ipsum dolor sit amet, consectetur elit adipiscing elit. Venenatis pulvinar a a
    met in, suspendisse vitae, posuere eu tortor et. Und commodo, fermentum, mauris leo eg.
    Lorem ipsum dolor sit amet, consectetur elit adipiscing elit. Venenatis pulvinar a amet in, suspendisse vitae, posuere eu tortor et. Und commodo, fermentum, mauris leo eget.t.""",
  ),
  Program(
    imageUrl: 'assets/images/program_1.jpg',
    title: 'IA DEFENSE & ESPACE',
    date: '2026-12-21',
    details: """Lorem ipsum dolor sit amet, consectetur elit adipiscing elit. Venenatis pulvinar a a
    met in, suspendisse vitae, posuere eu tortor et. Und commodo, fermentum, mauris leo eg.
    Lorem ipsum dolor sit amet, consectetur elit adipiscing elit. Venenatis pulvinar a amet in, suspendisse vitae, posuere eu tortor et. Und commodo, fermentum, mauris leo eget.t.""",
  ),
  Program(
    imageUrl: 'assets/images/program_2.jpg',
    title: 'Fire Store',
    date: '2026-12-22',
    details: """Lorem ipsum dolor sit amet, consectetur elit adipiscing elit. Venenatis pulvinar a a
    met in, suspendisse vitae, posuere eu tortor et. Und commodo, fermentum, mauris leo eg.
    Lorem ipsum dolor sit amet, consectetur elit adipiscing elit. Venenatis pulvinar a amet in, suspendisse vitae, posuere eu tortor et. Und commodo, fermentum, mauris leo eget.t.""",
  ),
];
