import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:siade2/main.dart' as app;

/// Génère les captures d'écran App Store Connect.
///
/// Lancement (sur macOS, simulateur iPhone 6,5" démarré) :
///
///   flutter drive \
///     --driver=test_driver/integration_test.dart \
///     --target=integration_test/screenshots_test.dart \
///     -d SIMULATOR_UDID \
///     --dart-define=SCREENSHOT_EMAIL=... --dart-define=SCREENSHOT_PASSWORD=...
///
/// Les PNG atterrissent dans `screenshots/`. Sur un simulateur
/// iPhone 11 Pro Max / XS Max, la sortie fait exactement 1242 × 2688 px,
/// le format attendu par Apple pour l'emplacement 6,5 pouces.
const String kEmail = String.fromEnvironment('SCREENSHOT_EMAIL');
const String kPassword = String.fromEnvironment('SCREENSHOT_PASSWORD');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('captures App Store', (WidgetTester tester) async {
    // Requis uniquement sur Android ; sur iOS la capture passe par le driver.
    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
    }

    app.main();

    // `pumpAndSettle` ne convient pas : le splash et les carrousels animent
    // en boucle, il ne se stabiliserait jamais. On avance par pas fixes.
    Future<void> settle([int seconds = 3]) async {
      final end = DateTime.now().add(Duration(seconds: seconds));
      while (DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> shoot(String name) async {
      await settle(1);
      await binding.takeScreenshot(name);
    }

    // Laisse passer le splash natif + l'init Firebase.
    await settle(8);
    await shoot('01_accueil');

    // Écran d'accueil -> écran de connexion.
    final decouvrir = find.text('Découvrir');
    if (decouvrir.evaluate().isNotEmpty) {
      await tester.tap(decouvrir.first, warnIfMissed: false);
      await settle(3);
      await shoot('02_connexion');
    }

    // Connexion réelle si des identifiants ont été fournis au build.
    if (kEmail.isNotEmpty && kPassword.isNotEmpty) {
      final champs = find.byType(TextField);
      if (champs.evaluate().length >= 2) {
        await tester.enterText(champs.at(0), kEmail);
        await settle(1);
        await tester.enterText(champs.at(1), kPassword);
        await settle(1);
        await shoot('03_saisie_connexion');

        final seConnecter = find.textContaining(
          RegExp('connexion|connecter', caseSensitive: false),
        );
        if (seConnecter.evaluate().isNotEmpty) {
          await tester.tap(seConnecter.last, warnIfMissed: false);
          // L'authentification Firebase + le chargement des données réseau
          // demandent nettement plus qu'un pump classique.
          await settle(20);
          await shoot('04_accueil_connecte');

          // Parcourt la barre de navigation principale pour varier les visuels.
          final navBar = find.byType(BottomNavigationBar);
          if (navBar.evaluate().isNotEmpty) {
            final icones = find.descendant(
              of: navBar.first,
              matching: find.byType(Icon),
            );
            final total = icones.evaluate().length;
            for (var i = 1; i < total && i < 4; i++) {
              await tester.tap(icones.at(i), warnIfMissed: false);
              await settle(6);
              await shoot('0${4 + i}_onglet_$i');
            }
          }
        }
      }
    }
  }, timeout: const Timeout(Duration(minutes: 10)));
}
