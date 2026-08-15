import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:habit_tracker/app.dart';
import 'package:habit_tracker/providers/habits_provider.dart';
import 'package:habit_tracker/providers/premium_provider.dart';
import 'package:habit_tracker/services/purchase_service.dart';
import 'package:habit_tracker/services/storage_service.dart';

void main() {
  testWidgets('Affiche l\'état vide au premier lancement', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider(create: (_) => StorageService()),
          ChangeNotifierProvider(
            create: (context) => HabitsProvider(context.read<StorageService>()),
          ),
          ChangeNotifierProvider(create: (_) => PremiumProvider(PurchaseService())),
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

    expect(find.text('Habitude+'), findsOneWidget);
    expect(find.text('Aucune habitude pour l\'instant'), findsOneWidget);
  });
}
