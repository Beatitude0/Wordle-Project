import 'package:flutter/material.dart';
import 'game_screen.dart';
// Removed unused imports: 'package:flutter/services.dart';

// The main entry point of the Nulldle app.

void main() {
  runApp(WordleApp());
}

/// A reusable custom text widget for the Nulldle app.
///
/// This widget ensures consistent styling across the app by applying
/// Courier font family, Bold pink text, Centered alignment,
/// A configurable font size (default: 24.0).
///
/// This will give the app a constant feel.
class NulldleText extends StatelessWidget {
  final String text;
  final double size;

  NulldleText(this.text, {super.key, this.size = 24.0});

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

// entry point that configures app-wide settings and decides the initial screen.
class WordleApp extends StatelessWidget {
  WordleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: HomeScreen(),
    );
  }
}

// The landing screen showing the title, game blurb, and a button to start the game.
class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Center(
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
          Center(
            child: Image.asset(
              'assets/title.png',
              width: 200,
            ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: NulldleText(
                'Guess the hidden five-letter word in just six tries! After each guess, tiles will light up, green means the letter is in the right spot, yellow means the letter is in the word but in the wrong spot, and grey means the letter is not in the word at all.',
                size: 14.0,
              ),
            ),
          ),
          Center(
            child: ElevatedButton(
              child: Text(
                'Play Game',
                style: TextStyle(
                  fontFamily: 'Courier',
                  color: Colors.pink,
                  fontWeight: FontWeight.bold,
                  fontSize: 24.0,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GameScreen()),
                );
              },
            ),
          ),
          SizedBox(
            height: 20,
          )
        ],
      ),
    );
  }
}
