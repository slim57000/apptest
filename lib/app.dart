import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme.dart';

class HabitudeApp extends StatelessWidget {
  const HabitudeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habitude+',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeScreen(),
    );
  }
}
