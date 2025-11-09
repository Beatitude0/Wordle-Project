// ✅ test/test_helpers.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nulldle/game_state.dart';
import 'package:nulldle/game_screen.dart';

/// Reusable helper to wrap GameScreen with Provider and MaterialApp.
/// Use this to quickly build the test environment.
Widget buildTestApp({String difficulty = 'Easy'}) {
  return ChangeNotifierProvider(
    create: (_) => GameState(difficulty: difficulty)..initializeGame(),
    child: const MaterialApp(home: GameScreen()),
  );
}
