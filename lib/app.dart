import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'providers/habits_provider.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

class HabitudeApp extends StatelessWidget {
  const HabitudeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Le français reste la langue de repli par défaut (marché principal),
      // même si l'ordre alphabétique généré met l'anglais en premier.
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale != null) {
          for (final supported in supportedLocales) {
            if (supported.languageCode == locale.languageCode) return supported;
          }
        }
        return const Locale('fr');
      },
      home: const _HealthSyncGate(child: HomeScreen()),
    );
  }
}

/// Resynchronise les pas de santé (Health Connect / Apple Health) au retour
/// au premier plan, en plus du sync fait à l'ouverture -- utile si
/// l'utilisateur marche puis revient dans l'app plus tard dans la journée.
class _HealthSyncGate extends StatefulWidget {
  final Widget child;

  const _HealthSyncGate({required this.child});

  @override
  State<_HealthSyncGate> createState() => _HealthSyncGateState();
}

class _HealthSyncGateState extends State<_HealthSyncGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<HabitsProvider>().syncHealthSteps();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
