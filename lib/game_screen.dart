import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'game_state.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _showCountdown = false;
  int _countdown = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final game = context.read<GameState>();
      await game.loadGame();

      if (game.difficulty == 'Hard' && !game.isGameOver) {
        _showStartHardModePopup(game);
      }
    });
  }

  // --- Common snackbar for feedback ---
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // --- Win / Lose popup ---
  void _showEndDialog(BuildContext context, bool isWin, String word) {
    final emoji = isWin ? "😄" : "😞";
    final color = isWin ? Colors.green : Colors.red;
    final message = isWin
        ? "You guessed it!\nThe word was: ${word.toUpperCase()}"
        : "Out of guesses!\nThe word was: ${word.toUpperCase()}";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: TextStyle(fontSize: 64, color: color)),
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
              final game = context.read<GameState>();
              await game.resetGame();
              if (game.difficulty == 'Hard') {
                _showStartHardModePopup(game);
              }
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

  // --- Out of time popup ---
  void _showOutOfTimeDialog(BuildContext context, String word) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_off, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              "You're out of time!\nThe word was: ${word.toUpperCase()}",
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
              final game = context.read<GameState>();
              await game.resetGame();
              if (game.difficulty == 'Hard') {
                _showStartHardModePopup(game);
              }
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

  // --- Hard Mode popup ---
  Future<void> _showStartHardModePopup(GameState game) async {
    final start = await showDialog<bool>(
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
          "A 3-second countdown will appear before the timer begins.",
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
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              "Start",
              style: TextStyle(
                fontFamily: 'Courier',
                color: Colors.pink,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (start == true) {
      await _showHardModeCountdown(game);
    } else {
      // 👇 Cancel → revert to Easy mode
      game.difficulty = 'Easy';
      await game.resetGame();
    }
  }

  // --- Countdown before Hard mode starts ---
  Future<void> _showHardModeCountdown(GameState game) async {
    setState(() {
      _showCountdown = true;
      _countdown = 3;
    });

    for (int i = 3; i > 0; i--) {
      setState(() => _countdown = i);
      await Future.delayed(const Duration(seconds: 1));
    }

    setState(() => _showCountdown = false);
    await game.resetGame();

    game.startTimer(onTimerEnd: () {
      _showOutOfTimeDialog(context, game.targetWord);
    });
  }

  // --- Handle user guesses ---
  void _handleSubmit(BuildContext context, GameState game) {
    final guess = _controller.text;
    _controller.clear();

    final result = game.submitGuess(guess);

    switch (result) {
      case 'invalid_length':
        _showSnackBar("Enter exactly 5 letters (A–Z).");
        break;
      case 'not_in_dictionary':
        _showSnackBar("Not a valid word!");
        break;
      case 'duplicate':
        _showSnackBar("You already guessed $guess!");
        break;
      case 'win':
        _showEndDialog(context, true, game.targetWord);
        break;
      case 'lose':
        _showEndDialog(context, false, game.targetWord);
        break;
    }
  }

  // --- On-screen keyboard ---
  Widget _buildKeyboard(Map<String, Color> keyboardColors) {
    const rows = ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"];
    return Column(
      children: rows.map((r) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: r.split('').map((letter) {
            return Container(
              margin: const EdgeInsets.all(4.0),
              width: 30,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: keyboardColors[letter],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.black26),
              ),
              child: Text(
                letter,
                style: const TextStyle(
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

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final guesses = game.guesses;
    final colors = game.colorHistory;
    final keyboardColors = game.keyboardColors;

    return Scaffold(
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
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // --- Difficulty toggle + timer ---
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
                          onChanged: (val) async {
                            if (val) {
                              game.difficulty = 'Hard';
                              await _showStartHardModePopup(game);
                            } else {
                              game.difficulty = 'Easy';
                              await game.resetGame();
                            }
                          },
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
                const SizedBox(height: 8),

                // --- Grid ---
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(game.maxGuesses, (rowIndex) {
                      String? guess =
                          rowIndex < guesses.length ? guesses[rowIndex] : null;
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
                                color: Colors.white,
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

                // --- Input field ---
                TextField(
                  controller: _controller,
                  maxLines: 1,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Enter your guess",
                  ),
                  onSubmitted: (_) => _handleSubmit(context, game),
                ),
                const SizedBox(height: 12),

                // --- Buttons ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => _handleSubmit(context, game),
                      child: const Text(
                        "Submit",
                        style: TextStyle(
                          fontFamily: 'Courier',
                          color: Colors.pink,
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        await game.resetGame();
                        if (game.difficulty == 'Hard') {
                          _showStartHardModePopup(game);
                        }
                      },
                      child: const Text(
                        "Reset",
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
                const SizedBox(height: 12),
                _buildKeyboard(keyboardColors),
              ],
            ),
          ),

          // --- Countdown overlay ---
          if (_showCountdown)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                child: child,
              ),
              child: Container(
                key: ValueKey(_countdown),
                color: Colors.white.withOpacity(0.9),
                alignment: Alignment.center,
                child: Text(
                  "$_countdown",
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 140,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
