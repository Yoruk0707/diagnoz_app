// lib/features/game/presentation/pages/game_page.dart
//
// NEDEN: Router bu sayfayı çağırır → GameScreen'e delege eder.
// Bottom nav bar ShellRoute içinde olduğu için
// GamePage ayrı kalmalı (router yapısı bozulmasın).

import 'package:flutter/material.dart';

import 'game_screen.dart';

/// Oyun sayfası — router entry point.
///
/// NEDEN: ShellRoute → GamePage → GameScreen zinciri.
/// GameScreen tüm oyun state'lerini handle eder.
class GamePage extends StatelessWidget {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GameScreen();
  }
}
