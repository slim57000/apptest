import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/habits_provider.dart';
import 'providers/premium_provider.dart';
import 'services/purchase_service.dart';
import 'services/storage_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => StorageService()),
        ChangeNotifierProvider(
          create: (context) => HabitsProvider(context.read<StorageService>()),
        ),
        ChangeNotifierProvider(
          create: (_) => PremiumProvider(PurchaseService()),
        ),
      ],
      child: const HabitudeApp(),
    ),
  );
}
