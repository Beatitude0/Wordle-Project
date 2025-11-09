import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'game_state.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  String _currentGuess = '';

  // --- Snackbars for errors ---
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // --- End game popup ---
  void _showEndDialog(BuildContext context, String result, String word) {
    String emoji;
    String message;
    Color color;

    if (result == 'win') {
      emoji = "😄";
      message = "You guessed it!\nThe word was: ${word.toUpperCase()}";
      color = Colors.green;
    } else if (result == 'timeout') {
      emoji = "⏰";
      message = "You ran out of time!\nThe word was: ${word.toUpperCase()}";
      color = Colors.red;
    } else {
      emoji = "😞";
      message = "Out of guesses!\nThe word was: ${word.toUpperCase()}";
      color = Colors.red;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: TextStyle(fontSize: 80, color: color)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
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
            onPressed: () async {
              Navigator.pop(context);
              await context.read<GameState>().resetGame();
            },
            child: const Text(
              "New Game",
              style: TextStyle(
                fontFamily: 'Courier',
                color: Colors.pink,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Handle physical + on-screen key input ---
  void _onKeyPressed(String key, GameState game) {
    if (game.isGameOver) return;

    setState(() {
      if (key == 'ENTER') {
        if (_currentGuess.length == game.wordLength) {
          final result = game.submitGuess(_currentGuess);
          _currentGuess = '';

          switch (result) {
            case 'invalid_length':
              _showSnackBar("Enter exactly ${game.wordLength} letters.");
              break;
            case 'not_in_dictionary':
              _showSnackBar("Not a valid word!");
              break;
            case 'duplicate':
              _showSnackBar("You already guessed that!");
              break;
            case 'win':
              _showEndDialog(context, 'win', game.targetWord);
              break;
            case 'lose':
              _showEndDialog(context, 'lose', game.targetWord);
              break;
            case 'timeout':
              _showEndDialog(context, 'timeout', game.targetWord);
              break;
            default:
              break;
          }
        } else {
          _showSnackBar("Enter ${game.wordLength} letters first!");
        }
      } else if (key == 'DEL') {
        if (_currentGuess.isNotEmpty) {
          _currentGuess = _currentGuess.substring(0, _currentGuess.length - 1);
        }
      } else if (RegExp(r'^[A-Z]$').hasMatch(key)) {
        if (_currentGuess.length < game.wordLength) {
          _currentGuess += key;
        }
      }
    });
  }

  // --- On-screen keyboard ---
  Widget _buildKeyboard(Map<String, Color> keyboardColors, GameState game) {
    const rows = ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"];
    return Column(
      children: [
        for (final row in rows)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.split('').map((letter) {
              return GestureDetector(
                onTap: () => _onKeyPressed(letter, game),
                child: Container(
                  margin: const EdgeInsets.all(4.0),
                  width: 32,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: keyboardColors[letter],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.black26),
                  ),
                  child: Text(
                    letter,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _keyButton("DEL", Colors.redAccent, game),
            const SizedBox(width: 8),
            _keyButton("ENTER", Colors.green, game),
          ],
        ),
      ],
    );
  }

  Widget _keyButton(String label, Color color, GameState game) {
    return GestureDetector(
      onTap: () => _onKeyPressed(label, game),
      child: Container(
        margin: const EdgeInsets.all(4.0),
        width: 80,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.black26),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final guesses = game.guesses;
    final colors = game.colorHistory;
    final keyboardColors = game.keyboardColors;

    // --- Timer end detection ---
    if (game.isGameOver && game.difficulty == 'Hard' && game.timeLeft <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showEndDialog(context, 'timeout', game.targetWord);
      });
    }

    return RawKeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKey: (event) {
        if (event is RawKeyDownEvent &&
            event.logicalKey.keyLabel.isNotEmpty &&
            event.data.logicalKey.keyLabel != 'Unidentified') {
          final keyLabel = event.logicalKey.keyLabel.toUpperCase();

          if (keyLabel == 'BACKSPACE') {
            _onKeyPressed('DEL', game);
          } else if (keyLabel == 'ENTER' || keyLabel == 'RETURN') {
            _onKeyPressed('ENTER', game);
          } else if (RegExp(r'^[A-Z]$').hasMatch(keyLabel)) {
            _onKeyPressed(keyLabel, game);
          }
        }
      },
      child: WillPopScope(
        onWillPop: () async {
          bool? shouldExit = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text(
                "Exit to Home?",
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
              content: const Text(
                "Are you sure you want to leave this game and return to the homepage?",
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 16,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      fontFamily: 'Courier',
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text(
                    "Exit",
                    style: TextStyle(
                      fontFamily: 'Courier',
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );

          if (shouldExit == true) {
            Navigator.of(context).pop(); // go back to HomeScreen
          }

          return false; // prevent automatic pop
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'Nulldle',
              style: TextStyle(
                fontFamily: 'Courier',
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.pink,
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: "Reset Game",
                onPressed: () async {
                  await game.resetGame();
                  setState(() => _currentGuess = '');
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // --- Difficulty + timer ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "Mode:",
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        Switch(
                          value: game.difficulty == 'Hard',
                          activeColor: Colors.pink,
                          onChanged: game.guesses.isEmpty
                              ? (val) async {
                                  if (val) {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text(
                                          "Start Hard Mode?",
                                          style: TextStyle(
                                            fontFamily: 'Courier',
                                            fontWeight: FontWeight.bold,
                                            color: Colors.pink,
                                          ),
                                        ),
                                        content: const Text(
                                          "You’ll have limited time to guess the word.\nReady to start?",
                                          style: TextStyle(
                                            fontFamily: 'Courier',
                                            fontSize: 16,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text("Cancel"),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text("Start"),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      game.difficulty = 'Hard';
                                      await game.resetGame();
                                      game.startTimer();
                                    } else {
                                      game.difficulty = 'Easy';
                                    }
                                  } else {
                                    game.difficulty = 'Easy';
                                    await game.resetGame();
                                  }
                                }
                              : null,
                        ),
                        Text(
                          game.difficulty,
                          style: TextStyle(
                            color: game.difficulty == 'Hard'
                                ? Colors.pink
                                : Colors.grey.shade600,
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (game.difficulty == 'Hard')
                      Row(
                        children: [
                          const Icon(Icons.timer, color: Colors.pink, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            "${game.timeLeft}s",
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: game.timeLeft <= 10
                                  ? Colors.red
                                  : Colors.pink.shade700,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- Game grid ---
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(game.maxGuesses, (rowIndex) {
                      String? guess;
                      if (rowIndex < guesses.length) {
                        guess = guesses[rowIndex];
                      } else if (rowIndex == guesses.length) {
                        guess = _currentGuess;
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(game.wordLength, (colIndex) {
                          String letter = '';
                          Color bgColor = Colors.grey.shade300;

                          if (guess != null && colIndex < guess.length) {
                            letter = guess[colIndex].toUpperCase();
                            if (rowIndex < colors.length) {
                              bgColor = colors[rowIndex][colIndex];
                            }
                          }

                          return Container(
                            margin: const EdgeInsets.all(4.0),
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
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 16),
                _buildKeyboard(keyboardColors, game),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
