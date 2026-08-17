import 'package:flutter/material.dart';

class OutlineButton extends StatelessWidget {
  final String text;

  /// Chemin d'une image d'assets affichée à gauche du libellé.
  ///
  /// Remplace l'ancien paramètre `icon` de type [IconData], qui était
  /// trompeur : sa valeur était ignorée et le bouton dessinait toujours
  /// `google.png`. Ajouter un second fournisseur de connexion demandait donc
  /// de pouvoir désigner l'image réellement voulue.
  final String? iconAsset;

  /// Teinte appliquée à [iconAsset]. À laisser nulle pour un logo
  /// polychrome comme celui de Google ; à renseigner pour une silhouette
  /// monochrome comme le logo Apple, qui doit suivre le thème sous peine
  /// d'être invisible sur l'un des deux fonds.
  final Color? iconColor;

  /// Un spinner remplace le contenu, sans changer la taille du bouton : la
  /// rangée de connexions ne doit pas se réorganiser pendant l'attente.
  final bool isLoading;

  final VoidCallback onTap;

  const OutlineButton({
    Key? key,
    required this.text,
    this.iconAsset,
    this.iconColor,
    this.isLoading = false,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final couleurTexte = isLight ? const Color(0xFF60438C) : Colors.white;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: isLight ? Colors.white.withOpacity(0.6) : null,
        border: Border.all(
          color: isLight ? Colors.transparent : Colors.white24,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: isLoading ? null : onTap,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: couleurTexte,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (iconAsset != null) ...[
                        Image.asset(
                          iconAsset!,
                          width: 24,
                          height: 24,
                          color: iconColor,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: TextStyle(
                          color: couleurTexte,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
