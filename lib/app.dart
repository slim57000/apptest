import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'providers/habits_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';

class HabitudeApp extends StatelessWidget {
  const HabitudeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeOverride = context.watch<LocaleProvider>().locale;

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // `locale` force la langue choisie dans les Réglages ; `null` laisse
      // le callback ci-dessous suivre la langue du système (avec repli sur
      // le français, marché principal, même si l'ordre alphabétique généré
      // met l'anglais en premier dans supportedLocales).
      locale: localeOverride,
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale != null) {
          for (final supported in supportedLocales) {
            if (supported.languageCode == locale.languageCode) return supported;
          }
        }
        return const Locale('fr');
      },
      home: const _HealthSyncGate(child: SplashScreen()),
    );
  }
}

/// Au retour au premier plan : recharge les habitudes depuis le stockage
/// (pour récupérer une bascule faite depuis le widget écran d'accueil
/// pendant que l'app était en arrière-plan) puis resynchronise les pas de
/// santé (Health Connect / Apple Health), en plus du sync fait à
/// l'ouverture -- utile si l'utilisateur marche puis revient dans l'app
/// plus tard dans la journée.
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
      _onResumed();
    }
  }

  Future<void> _onResumed() async {
    final habits = context.read<HabitsProvider>();
    await habits.reload();
    await habits.syncHealthSteps();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
