import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:habit_tracker/app.dart';
import 'package:habit_tracker/providers/backup_provider.dart';
import 'package:habit_tracker/providers/challenge_provider.dart';
import 'package:habit_tracker/providers/habits_provider.dart';
import 'package:habit_tracker/providers/locale_provider.dart';
import 'package:habit_tracker/providers/premium_provider.dart';
import 'package:habit_tracker/providers/theme_mode_provider.dart';
import 'package:habit_tracker/services/backup_service.dart';
import 'package:habit_tracker/services/challenge_service.dart';
import 'package:habit_tracker/services/health_service.dart';
import 'package:habit_tracker/services/notification_service.dart';
import 'package:habit_tracker/services/purchase_service.dart';
import 'package:habit_tracker/services/storage_service.dart';
import 'package:habit_tracker/services/widget_service.dart';

void main() {
  testWidgets('Affiche l\'état vide au premier lancement', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider(create: (_) => StorageService()),
          Provider(create: (_) => NotificationService()),
          Provider(create: (_) => HealthService()),
          Provider(create: (_) => WidgetService()),
          ChangeNotifierProvider(
            create: (context) => HabitsProvider(
              context.read<StorageService>(),
              context.read<NotificationService>(),
              context.read<HealthService>(),
              context.read<WidgetService>(),
            ),
          ),
          ChangeNotifierProvider(create: (_) => PremiumProvider(PurchaseService())),
          ChangeNotifierProvider(create: (_) => ChallengeProvider(ChallengeService())),
          ChangeNotifierProvider(create: (_) => BackupProvider(BackupService())),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ChangeNotifierProvider(create: (_) => AppThemeModeProvider()),
        ],
        child: const HabitudeApp(),
      ),
    );
    // Pas de pumpAndSettle : l'initialisation d'in_app_purchase reste en
    // attente indéfiniment sous `flutter test` (pas de plateforme réelle),
    // ce qui empêcherait jamais l'UI de se stabiliser. On avance juste de
    // quelques frames, largement de quoi charger les habitudes locales.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // La locale par défaut du harness de test est l'anglais, quelle que
    // soit la locale de repli de l'app (le français) : on vérifie donc le
    // texte anglais ici plutôt que de dépendre de la résolution de locale.
    expect(find.text('Habitude+'), findsOneWidget);
    expect(find.text('No habits yet'), findsOneWidget);
  });
}
