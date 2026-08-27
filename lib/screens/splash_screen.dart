import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen.dart';
import 'onboarding_screen.dart';

/// Écran de lancement Flutter (après le splash natif Android) : logo et nom
/// de l'app qui apparaissent avec une légère animation, le temps que l'app
/// finisse de démarrer. Redirige ensuite vers le tuto (premier lancement)
/// ou directement l'accueil.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const onboardingSeenKey = 'onboarding_seen_v1';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _proceed();
  }

  Future<void> _proceed() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(SplashScreen.onboardingSeenKey) ?? false;
    // Laisse l'animation du logo se jouer avant de basculer d'écran.
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => seen ? const HomeScreen() : const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF2563EB),
      body: Center(
        child: _SplashContent(),
      ),
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.task_alt, size: 72, color: Colors.white)
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(begin: const Offset(0.6, 0.6), end: const Offset(1, 1), curve: Curves.easeOutBack),
        const SizedBox(height: 16),
        Text.rich(
          TextSpan(
            text: 'Habitude',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            children: [
              TextSpan(
                text: '+',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 300.ms, duration: 500.ms)
            .slideY(begin: 0.3, end: 0, delay: 300.ms, duration: 500.ms, curve: Curves.easeOut),
      ],
    );
  }
}
