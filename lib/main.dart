import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/supabase_config.dart';
import 'providers/backup_provider.dart';
import 'providers/challenge_provider.dart';
import 'providers/habits_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/premium_provider.dart';
import 'services/backup_service.dart';
import 'services/challenge_service.dart';
import 'services/health_service.dart';
import 'services/notification_service.dart';
import 'services/purchase_service.dart';
import 'services/storage_service.dart';
import 'services/widget_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
  }

  runApp(
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
        ChangeNotifierProvider(
          create: (_) => PremiumProvider(PurchaseService()),
        ),
        ChangeNotifierProvider(
          create: (_) => ChallengeProvider(ChallengeService()),
        ),
        ChangeNotifierProvider(
          create: (_) => BackupProvider(BackupService()),
        ),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const HabitudeApp(),
    ),
  );
}
