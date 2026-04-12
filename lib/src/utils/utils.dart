import 'package:flutter/material.dart';

/// Returns a deterministic color based on the first letter of [nameOrEmail].
/// For email addresses (contains '@'), uses the part before '@'.
Color avatarColorForInitial(String nameOrEmail) {
  const letterColors = [
    Color(0xFF1565C0), Color(0xFF6A1B9A), Color(0xFF00838F), Color(0xFFAD1457),
    Color(0xFF2E7D32), Color(0xFFE65100), Color(0xFF4527A0), Color(0xFF00695C),
    Color(0xFFC62828), Color(0xFF37474F), Color(0xFFD84315), Color(0xFF1B5E20),
    Color(0xFF880E4F), Color(0xFF0D47A1), Color(0xFF4A148C), Color(0xFF006064),
    Color(0xFFBF360C), Color(0xFF1A237E), Color(0xFF558B2F), Color(0xFF827717),
    Color(0xFF4E342E), Color(0xFF01579B), Color(0xFF33691E), Color(0xFF6D4C41),
    Color(0xFF283593), Color(0xFF004D40),
  ];
  const fallback = Color(0xFF423B69);
  final src = nameOrEmail.contains('@') ? nameOrEmail.split('@').first : nameOrEmail;
  if (src.isEmpty) return fallback;
  final idx = src[0].toUpperCase().codeUnitAt(0) - 'A'.codeUnitAt(0);
  if (idx < 0 || idx >= letterColors.length) return fallback;
  return letterColors[idx];
}
