import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:siade2/main.dart' as app;
import 'package:siade2/src/features/home/pages/app_layout.dart';
import 'package:siade2/src/features/login/widgets/widgets.dart';

/// Génère les captures d'écran App Store Connect.
///
/// Lancement (sur macOS, simulateur iPhone démarré) :
///
///   flutter drive \
///     --driver=test_driver/integration_test.dart \
///     --target=integration_test/screenshots_test.dart \
///     -d SIMULATOR_UDID \
///     --dart-define=SCREENSHOT_EMAIL=... --dart-define=SCREENSHOT_PASSWORD=...
///
/// Les PNG atterrissent dans `screenshots/`, puis le workflow Codemagic les
/// ramène à 1284 × 2778, l'un des deux formats acceptés par Apple pour
/// l'emplacement 6,5 pouces.
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

    // `pumpAndSettle` ne convient pas : le splash, le carrousel d'onboarding
    // et les animations de fond tournent en boucle, il ne se stabiliserait
    // jamais. On avance par pas fixes.
    Future<void> patienter(int secondes) async {
      final fin = DateTime.now().add(Duration(seconds: secondes));
      while (DateTime.now().isBefore(fin)) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    /// Pompe jusqu'à ce que [f] apparaisse. Rend `false` au bout de
    /// [secondes] plutôt que de faire échouer le test : une capture
    /// manquante vaut mieux qu'un run entièrement perdu.
    Future<bool> attendre(Finder f, {int secondes = 30}) async {
      final fin = DateTime.now().add(Duration(seconds: secondes));
      while (DateTime.now().isBefore(fin)) {
        await tester.pump(const Duration(milliseconds: 200));
        if (f.evaluate().isNotEmpty) return true;
      }
      return false;
    }

    Future<void> capturer(String nom) async {
      await patienter(1);
      await binding.takeScreenshot(nom);
      // ignore: avoid_print
      print('[captures] $nom');
    }

    // --- Onboarding -------------------------------------------------------
    // splash_page.dart fait défiler 3 diapos via un Timer de 4 s. La
    // troisième porte le bouton « Découvrir » : on la capture via ce
    // bouton plutôt qu'à l'aveugle, sinon elle sort en double.
    await patienter(6);
    await capturer('01_onboarding_1');
    await patienter(4);
    await capturer('02_onboarding_2');

    final decouvrir = find.text('Découvrir');
    if (await attendre(decouvrir, secondes: 30)) {
      await capturer('03_onboarding_3');
      await tester.tap(decouvrir.first, warnIfMissed: false);
    } else {
      // ignore: avoid_print
      print('[captures] "Découvrir" introuvable, on tente la suite');
    }

    // --- Connexion --------------------------------------------------------
    final champs = find.byType(TextField);
    if (!await attendre(champs, secondes: 20)) {
      // ignore: avoid_print
      print('[captures] écran de connexion jamais atteint');
      return;
    }
    await capturer('04_connexion');

    if (kEmail.isEmpty || kPassword.isEmpty) {
      // ignore: avoid_print
      print('[captures] pas d\'identifiants fournis, arrêt avant connexion');
      return;
    }
    if (champs.evaluate().length < 2) {
      // ignore: avoid_print
      print('[captures] champs de saisie introuvables');
      return;
    }

    await tester.enterText(champs.at(0), kEmail);
    await patienter(1);
    await tester.enterText(champs.at(1), kPassword);
    await patienter(1);

    // La page porte deux GradientButton libellés « Connexion » : l'onglet du
    // haut, dont le onTap est vide, et le bouton de soumission plus bas.
    // C'est le dernier dans l'arbre. Un find.textContaining attraperait
    // « Ou se connecter avec », un libellé décoratif non cliquable.
    final seConnecter = find.widgetWithText(GradientButton, 'Connexion');
    if (seConnecter.evaluate().isEmpty) {
      // ignore: avoid_print
      print('[captures] bouton de connexion introuvable');
      return;
    }
    await tester.tap(seConnecter.last, warnIfMissed: false);

    // --- Écrans connectés -------------------------------------------------
    // On attend AppLayout lui-même plutôt que sa barre de navigation : celle-ci
    // est un NavigationBar Material 3, et guetter un BottomNavigationBar
    // faisait échouer l'étape alors que la connexion avait réussi.
    if (!await attendre(find.byType(AppLayout), secondes: 60)) {
      // ignore: avoid_print
      print('[captures] connexion non aboutie');
      // Préfixe `debug_` : capture de diagnostic, pas destinée à l'App Store.
      await capturer('debug_apres_connexion');
      return;
    }
    // Les écrans connectés chargent leurs données par le réseau.
    await patienter(10);
    await capturer('05_accueil_connecte');

    // Les destinations de la barre sont des GestureDetector personnalisés.
    final navBar = find.byType(NavigationBar);
    if (navBar.evaluate().isEmpty) return;
    final onglets = find.descendant(
      of: navBar.first,
      matching: find.byType(GestureDetector),
    );
    final total = onglets.evaluate().length;
    // ignore: avoid_print
    print('[captures] $total onglets détectés');
    for (var i = 1; i < total && i < 5; i++) {
      await tester.tap(onglets.at(i), warnIfMissed: false);
      await patienter(8);
      await capturer('0${5 + i}_onglet_$i');
    }
  }, timeout: const Timeout(Duration(minutes: 15)));
}
