import 'package:flutter/material.dart';

/// Logo d'Habitude+ : utilise l'asset de l'icône de l'application.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogo({super.key, this.size = 26, this.showText = true});

  @override
  Widget build(BuildContext context) {
    final mark = Image.asset(
      'assets/icon/icon_foreground.png',
      width: size,
      height: size,
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
