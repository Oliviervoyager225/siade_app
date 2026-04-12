import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siade2/src/commons/data/models/exponent.dart';
import 'package:siade2/src/commons/data/models/program.dart';
import 'package:siade2/src/commons/data/models/speaker.dart';

class FavoritesProvider with ChangeNotifier {
  static const _kPrograms  = 'fav_programs';
  static const _kSpeakers  = 'fav_speakers';
  static const _kExponents = 'fav_exponents';

  List<Map<String, dynamic>> _programs  = [];
  List<Map<String, dynamic>> _speakers  = [];
  List<Map<String, dynamic>> _exponents = [];

  List<Map<String, dynamic>> get favoritePrograms  => List.unmodifiable(_programs);
  List<Map<String, dynamic>> get favoriteSpeakers  => List.unmodifiable(_speakers);
  List<Map<String, dynamic>> get favoriteExponents => List.unmodifiable(_exponents);

  int get totalCount => _programs.length + _speakers.length + _exponents.length;

  FavoritesProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _programs  = _decode(prefs.getString(_kPrograms));
    _speakers  = _decode(prefs.getString(_kSpeakers));
    _exponents = _decode(prefs.getString(_kExponents));
    notifyListeners();
  }

  List<Map<String, dynamic>> _decode(String? raw) {
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(String key, List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(list));
  }

  // ── Programs ──────────────────────────────────────────────────────────────

  bool isFavoriteProgram(Program p) =>
      _programs.any((m) => m['key'] == p.title);

  Future<void> toggleProgram(Program p) async {
    if (isFavoriteProgram(p)) {
      _programs.removeWhere((m) => m['key'] == p.title);
    } else {
      _programs.add({
        'key':       p.title,
        'title':     p.title,
        'imageUrl':  p.imageUrl,
        'date':      p.date,
        'room':      p.room ?? '',
        'startTime': p.formattedStartTime ?? '',
        'type':      'program',
      });
    }
    notifyListeners();
    await _save(_kPrograms, _programs);
  }

  // ── Speakers ──────────────────────────────────────────────────────────────

  bool isFavoriteSpeaker(Speaker s) =>
      _speakers.any((m) => m['key'] == s.name);

  Future<void> toggleSpeaker(Speaker s) async {
    if (isFavoriteSpeaker(s)) {
      _speakers.removeWhere((m) => m['key'] == s.name);
    } else {
      _speakers.add({
        'key':      s.name,
        'name':     s.name,
        'imageUrl': s.imageUrl,
        'job':      s.job,
        'type':     'speaker',
      });
    }
    notifyListeners();
    await _save(_kSpeakers, _speakers);
  }

  // ── Exponents ─────────────────────────────────────────────────────────────

  bool isFavoriteExponent(Exponent e) =>
      _exponents.any((m) => m['key'] == (e.slug ?? e.name));

  Future<void> toggleExponent(Exponent e) async {
    final key = e.slug ?? e.name;
    if (isFavoriteExponent(e)) {
      _exponents.removeWhere((m) => m['key'] == key);
    } else {
      _exponents.add({
        'key':      key,
        'name':     e.name,
        'imageUrl': e.imageUrl,
        'job':      e.job,
        'type':     'exponent',
      });
    }
    notifyListeners();
    await _save(_kExponents, _exponents);
  }
}
