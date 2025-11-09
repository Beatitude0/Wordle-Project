import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'game_state.dart';
import 'word_service.dart';
import 'home_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => GameState(wordService: WordService())..initializeGame(),
      child: const WordleApp(),
    ),
  );
}

/// Consistent custom text style across the app.
class NulldleText extends StatelessWidget {
  final String text;
  final double size;

  const NulldleText(this.text, {super.key, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Courier',
        color: Colors.pink,
        fontWeight: FontWeight.bold,
        fontSize: size,
      ),
    );
  }
}

class WordleApp extends StatelessWidget {
  const WordleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.pink),
      home: const HomeScreen(),
    );
  }
}
