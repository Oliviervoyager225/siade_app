import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale? _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Locale? get locale => _locale;

  void setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    (await SharedPreferences.getInstance()).setString('language_code', locale.languageCode);
  }

  void _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'fr';
    _locale = Locale(languageCode);
    notifyListeners();
  }
}
