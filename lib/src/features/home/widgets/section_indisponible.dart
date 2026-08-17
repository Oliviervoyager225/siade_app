import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siade2/l10n/app_localizations.dart';
import 'package:siade2/src/providers/data_provider.dart';

/// Message affiché quand le chargement d'une section a échoué.
///
/// À distinguer de la section réellement vide : « Aucune donnée disponible »
/// devant un serveur injoignable laissait croire que l'événement n'avait ni
/// intervenant ni programme, et n'offrait aucun moyen de réessayer.
class SectionIndisponible extends StatelessWidget {
  const SectionIndisponible({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final couleur = isLight ? Colors.black54 : Colors.white70;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, size: 18, color: couleur),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                l10n.loadFailed,
                textAlign: TextAlign.center,
                style: TextStyle(color: couleur, fontSize: 13),
              ),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: () => context.read<DataProvider>().loadAllData(),
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(l10n.retry),
        ),
      ],
    );
  }
}
