import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'game_screen.dart';
import 'main.dart'; // for NulldleText widget
import 'game_state.dart';

/// Home screen for Nulldle — shows title, instructions, and "Play" button.
/// Difficulty is now chosen inside GameScreen, so this file is simplified.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // --- Title ---
            const Padding(
              padding: EdgeInsets.only(top: 40.0),
              child: Text(
                'Nulldle',
                style: TextStyle(
                  fontFamily: 'Courier',
                  color: Colors.pink,
                  fontWeight: FontWeight.bold,
                  fontSize: 48.0,
                ),
              ),
            ),

            // --- Image ---
            Center(
              child: Image.asset(
                'assets/title.png',
                width: 200,
              ),
            ),

            // --- Description ---
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: NulldleText(
                  'Guess the hidden five-letter word in six tries!\n'
                  'Green = correct spot, Yellow = wrong spot, Grey = not in word.\n\n'
                  'Toggle between Easy and Hard mode inside the game screen.',
                  size: 14.0,
                ),
              ),
            ),

            // --- Play Button ---
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.pink, width: 2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider(
                        create: (_) => GameState()..initializeGame(),
                        child: const GameScreen(),
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Play Game',
                  style: TextStyle(
                    fontFamily: 'Courier',
                    color: Colors.pink,
                    fontWeight: FontWeight.bold,
                    fontSize: 24.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
