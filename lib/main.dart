import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/habits_provider.dart';
import 'providers/premium_provider.dart';
import 'services/notification_service.dart';
import 'services/purchase_service.dart';
import 'services/storage_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => StorageService()),
        Provider(create: (_) => NotificationService()),
        ChangeNotifierProvider(
          create: (context) => HabitsProvider(
            context.read<StorageService>(),
            context.read<NotificationService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PremiumProvider(PurchaseService()),
        ),
      ],
      child: const HabitudeApp(),
    ),
  );
}
