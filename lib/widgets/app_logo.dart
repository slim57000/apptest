import 'package:flutter/material.dart';

/// Logo d'Habitude+ : utilise l'asset de l'icône de l'application.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogo({super.key, this.size = 26, this.showText = true});

  @override
  Widget build(BuildContext context) {
    // Logo léger pour l'en-tête : pas de disque de fond, juste le glyphe
    // "tâche cochée" en bleu de marque, cohérent avec l'usage de l'app.
    final mark = Icon(
      Icons.task_alt,
      size: size,
      color: const Color(0xFF2563EB),
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
