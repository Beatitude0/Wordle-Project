import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// The main play screen of the app.
///
/// Responsibilities:
/// - Loads the dictionary of words from assets.
/// - Randomly selects the target word for the game.
/// - Stores and updates guesses made by the player.
/// - Checks guesses for validity and win/lose conditions.
/// - Updates the on-screen keyboard colors based on guesses.
/// - Displays the game grid (6 rows × 5 columns).
/// - Shows dialogs for win and lose scenarios.
/// - Provides reset/new game functionality.
/// - Manages the overall UI layout (grid, text field, buttons, keyboard).
class GameScreen extends StatefulWidget {
  GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final TextEditingController _controller = TextEditingController();
  late List<String> _dictionary;
  String _targetWord = '';
  List<String> _guesses = [];
  final int _maxGuesses = 6; // Total allowed guesses should be 6
  Map<String, Color> _keyboardColors = {
    for (var c in 'QWERTYUIOPASDFGHJKLZXCVBNM'.split(''))
      c: Colors.grey.shade300,
  };

  @override
  void initState() {
    super.initState();
    _loadDictionary();
  }

  // Load dictionary and select the word for play
  Future<void> _loadDictionary() async {
    final dict = await rootBundle.loadString('assets/english_dict.txt');
    setState(() {
      _dictionary = dict
          .split('\n')
          .map((w) => w.trim().toLowerCase())
          .where((w) => w.length == 5)
          .toList();

      _targetWord = _dictionary[Random().nextInt(_dictionary.length)];
    });
  }

  // Figures out what color each tile should be
  Color _tileColor(String guess, int index) {
    if (_targetWord[index] == guess[index]) {
      return Colors.green;
    } else if (_targetWord.contains(guess[index])) {
      return Colors.yellow;
    } else {
      return Colors.grey; // changed from red to grey for better UX
    }
  }

  // Updates the on-screen keyboard colors after each guess, so the player can see which letters they’ve already tried
  void _updateKeyboard(String guess) {
    for (int i = 0; i < guess.length; i++) {
      String letter = guess[i].toUpperCase();
      Color newColor = _tileColor(guess, i);

      // Priority order: Green > Yellow > Red
      if (_keyboardColors[letter] == Colors.green) continue;
      if (_keyboardColors[letter] == Colors.yellow && newColor == Colors.grey)
        continue;

      _keyboardColors[letter] = newColor;
    }
  }

  // Displays a win dialog when the player guesses the word correctly,
  // showing a smiley face, the correct word, and providing a button
  // that both closes the dialog and resets the game state for a new round
  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ":D",
                style: TextStyle(
                  fontSize: 64,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                "You guessed it!\nThe word was: ${_targetWord.toUpperCase()}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 20,
                  color: Colors.pink,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                // Reset the game
                setState(() {
                  _guesses.clear();
                  _controller.clear();
                  _targetWord =
                      _dictionary[Random().nextInt(_dictionary.length)];
                  _keyboardColors = {
                    for (var c in 'QWERTYUIOPASDFGHJKLZXCVBNM'.split(''))
                      c: Colors.grey.shade300,
                  };
                });
              },
              child: Text(
                "Close",
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 64,
                  color: Colors.pink,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // resolve and reset game
  void _resetGame() {
    showDialog(
      context: context,
      barrierDismissible: false, // must press Close
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ":(",
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 64,
                  color: Colors.pink,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                "The word was: ${_targetWord.toUpperCase()}",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                // Now reset the game
                setState(() {
                  _guesses.clear();
                  _controller.clear();
                  _targetWord =
                      _dictionary[Random().nextInt(_dictionary.length)];
                  _keyboardColors = {
                    for (var c in 'QWERTYUIOPASDFGHJKLZXCVBNM'.split(''))
                      c: Colors.grey.shade300,
                  };
                });
              },
              child: Text(
                "Close",
                style: TextStyle(
                  fontFamily: 'Courier',
                  color: Colors.pink,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Handles the player's guess:
  // Reads and clears the input text.
  // Validates the guess against the dictionary.
  // Updates the game state by recording the guess and refreshing the keyboard colors.
  // Checks win/loss conditions: if the guess matches the target word, show a win dialog
  // if the guess limit is reached, reveal the correct word and reset the game.

  void _submitGuess() {
    final guess = _controller.text.toLowerCase();
    _controller.clear();

    // Validate 5-letter alphabetic input
    if (guess.length != 5 || !RegExp(r'^[a-zA-Z]+$').hasMatch(guess)) {
      _showSnackBar("Enter exactly 5 letters (A–Z).");
      return;
    }

    // Check if the guess is in the dictionary
    if (!_dictionary.contains(guess)) {
      _showSnackBar("Not a valid word!");
      return;
    }

    // Block duplicate guesses
    if (_guesses.contains(guess)) {
      _showSnackBar("You already guessed $guess!");
      return;
    }

    setState(() {
      _guesses.add(guess);
      _updateKeyboard(guess); // update colors here
    });

    if (guess == _targetWord) {
      _showWinDialog();
      _showSnackBar("You win!");
    } else if (_guesses.length >= _maxGuesses) {
      _resetGame();
      _showSnackBar("Out of guesses! Word was $_targetWord");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    Widget _buildKeyboard() {
      const keyboardRows = ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"];

      return Column(
        children: keyboardRows.map((row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.split('').map((letter) {
              return Container(
                margin: EdgeInsets.all(4.0),
                width: 30,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _keyboardColors[letter],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black26),
                ),
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (rowIndex) {
                  String? guess =
                      rowIndex < _guesses.length ? _guesses[rowIndex] : null;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (colIndex) {
                      String letter = '';
                      Color bgColor = Colors.grey.shade300;

                      if (guess != null && colIndex < guess.length) {
                        letter = guess[colIndex].toUpperCase();
                        bgColor = _tileColor(guess, colIndex);
                      }

                      return Container(
                        margin: EdgeInsets.all(4.0),
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.black26),
                        ),
                        child: Text(
                          letter,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                      );
                    }),
                  );
                }),
              ),
            ),
            TextField(
              controller: _controller,
              maxLines: 1, // stops multiline input
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.none,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter your guess",
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _submitGuess,
                  child: Text(
                    "Submit",
                    style: TextStyle(
                      fontFamily: 'Courier',
                      color: Colors.pink,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _resetGame,
                  child: Text(
                    "New Game",
                    style: TextStyle(
                      fontFamily: 'Courier',
                      color: Colors.pink,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildKeyboard(),
          ],
        ),
      ),
    );
  }
}
