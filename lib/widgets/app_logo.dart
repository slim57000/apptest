import 'package:flutter/material.dart';

/// Logo d'Habitude+ : utilise l'asset de l'icône de l'application.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogo({super.key, this.size = 26, this.showText = true});

  @override
  Widget build(BuildContext context) {
    // icon_foreground.png est un glyphe blanc sur fond transparent (couche
    // "foreground" standard pour les icônes adaptatives Android, où le fond
    // est fourni séparément) : invisible tel quel sur un AppBar clair. On
    // l'affiche donc ici sur son propre disque bleu de marque, pour rester
    // lisible partout où ce logo est utilisé dans l'app.
    final mark = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF2563EB),
      ),
      padding: EdgeInsets.all(size * 0.16),
      child: Image.asset('assets/icon/icon_foreground.png'),
    );

    if (!showText) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: size * 0.4),
        Text.rich(
          TextSpan(
            text: 'Habitude',
            style: TextStyle(
              fontSize: size * 0.82,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            children: [
              TextSpan(
                text: '+',
                style: TextStyle(
                  fontSize: size * 0.95,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
