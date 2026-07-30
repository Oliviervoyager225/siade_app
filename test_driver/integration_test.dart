import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Pilote de `flutter drive` : écrit chaque capture demandée par
/// `integration_test/screenshots_test.dart` dans `screenshots/`.
Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      final File image = File('screenshots/$name.png');
      image.createSync(recursive: true);
      image.writeAsBytesSync(bytes);
      return true;
    },
  );
}
