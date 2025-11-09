import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nulldle/game_state.dart';
import 'package:nulldle/game_screen.dart';

/// A reusable widget builder for Provider-based GameScreen.
Widget createGameScreen({String difficulty = 'Easy'}) {
  return ChangeNotifierProvider(
    create: (_) => GameState(difficulty: '')..difficulty = difficulty,
    child: const MaterialApp(
      home: GameScreen(),
    ),
  );
}
