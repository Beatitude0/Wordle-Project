import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'word_service.dart';

/// Handles full Nulldle logic and state.
/// ✅ Supports Easy/Hard mode with timer, hint, and dynamic reward logic.
class GameState extends ChangeNotifier {
  final WordService _wordService;
  final int maxGuesses;
  final int wordLength;

  late List<String> _dictionary;
  String _targetWord = '';
  final List<String> _guesses = [];
  final List<List<Color>> _colorHistory = [];
  final Map<String, Color> _keyboardColors = {
    for (var c in 'QWERTYUIOPASDFGHJKLZXCVBNM'.split(''))
      c: Colors.grey.shade300,
  };

  bool _isGameOver = false;

  // Timer
  Timer? _timer;
  int _timeLeft = 0;

  // Difficulty
  String difficulty = 'Easy';

  // Hint system
  bool _hintUsed = false;
  String? _hintLetter;

  // ✅ Tracks rewarded green positions (avoid repeated +5s)
  final Set<int> _rewardedPositions = {};

  GameState({
    WordService? wordService,
    this.maxGuesses = 6,
    this.wordLength = 5,
  }) : _wordService = wordService ?? WordService();

  // --- Getters ---
  List<String> get guesses => List.unmodifiable(_guesses);
  List<List<Color>> get colorHistory => List.unmodifiable(_colorHistory);
  Map<String, Color> get keyboardColors => Map.unmodifiable(_keyboardColors);
  bool get isGameOver => _isGameOver;
  String get targetWord => _targetWord;
  int get timeLeft => _timeLeft;
  bool get hintUsed => _hintUsed;
  String? get hintLetter => _hintLetter;

  // ---------------- Initialization ----------------
  Future<void> initializeGame() async {
    _dictionary = await _wordService.loadDictionary();
    _targetWord = _wordService.pickRandomWord(_dictionary);
    if (_targetWord.isEmpty) _targetWord = 'apple';
    await resetGame();
  }

  // ---------------- Timer Logic ----------------
  void startTimer() {
    _timer?.cancel();
    _isGameOver = false;

    if (_timeLeft <= 0) {
      _timeLeft = 90;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0 && !_isGameOver) {
        _timeLeft--;
        notifyListeners();
      } else {
        timer.cancel();
        if (!_isGameOver) {
          _isGameOver = true;
          notifyListeners(); // triggers timeout popup
        }
      }
    });
  }

  void pauseTimer() => _timer?.cancel();

  void resumeTimer() {
    if (difficulty == 'Hard' && !_isGameOver && _timeLeft > 0) {
      startTimer();
    }
  }

  // ---------------- Hint System ----------------
  String? useHint() {
    if (_hintUsed || _isGameOver || difficulty != 'Hard') return null;

    final index = Random().nextInt(_targetWord.length);
    _hintLetter = _targetWord[index];
    _hintUsed = true;

    // Deduct 10 seconds (never below 0)
    _timeLeft = (_timeLeft - 10).clamp(0, 999);
    notifyListeners();
    return _hintLetter;
  }

  // ---------------- Guess Submission ----------------
  String submitGuess(String guess) {
    guess = guess.toLowerCase();

    if (_isGameOver) return 'game_over';
    if (guess.length != wordLength) return 'invalid_length';
    if (!_dictionary.contains(guess)) return 'not_in_dictionary';
    if (_guesses.contains(guess)) return 'duplicate';

    final colors = _evaluateGuess(guess);
    _guesses.add(guess);
    _colorHistory.add(colors);
    _updateKeyboard(guess, colors);

    if (guess == _targetWord) {
      _isGameOver = true;
      _timer?.cancel();
      notifyListeners();
      return 'win';
    } else if (_guesses.length >= maxGuesses) {
      _isGameOver = true;
      _timer?.cancel();
      notifyListeners();
      return 'lose';
    }

    notifyListeners();
    return 'continue';
  }

  // ---------------- Guess Evaluation ----------------
  List<Color> _evaluateGuess(String guess) {
    final colors = List<Color>.filled(wordLength, Colors.grey);
    final used = List<bool>.filled(wordLength, false);

    // Pass 1: Greens
    for (int i = 0; i < wordLength; i++) {
      if (guess[i] == _targetWord[i]) {
        colors[i] = Colors.green;
        used[i] = true;

        // ✅ +5s once per position in Hard mode
        if (difficulty == 'Hard' && !_rewardedPositions.contains(i)) {
          _rewardedPositions.add(i);
          _timeLeft += 5;
        }
      }
    }

    // Pass 2: Yellows
    for (int i = 0; i < wordLength; i++) {
      if (colors[i] == Colors.green) continue;
      for (int j = 0; j < wordLength; j++) {
        if (!used[j] && guess[i] == _targetWord[j]) {
          colors[i] = Colors.yellow;
          used[j] = true;
          break;
        }
      }
    }

    notifyListeners();
    return colors;
  }

  // ---------------- Keyboard Update ----------------
  void _updateKeyboard(String guess, List<Color> rowColors) {
    for (int i = 0; i < guess.length; i++) {
      final letter = guess[i].toUpperCase();
      final color = rowColors[i];
      final current = _keyboardColors[letter];

      if (current == Colors.green) continue;
      if (current == Colors.yellow && color == Colors.grey) continue;

      _keyboardColors[letter] = color;
    }
  }

  // ---------------- Reset Game ----------------
  Future<void> resetGame() async {
    _timer?.cancel();
    _guesses.clear();
    _colorHistory.clear();
    _rewardedPositions.clear();
    _keyboardColors.updateAll((_, __) => Colors.grey.shade300);
    _isGameOver = false;
    _hintUsed = false;
    _hintLetter = null;

    if (_dictionary.isEmpty) {
      _dictionary = await _wordService.loadDictionary();
    }

    _targetWord = _wordService.pickRandomWord(_dictionary);
    if (_targetWord.isEmpty) _targetWord = 'apple';

    _timeLeft = (difficulty == 'Hard') ? 90 : 0;

    // ✅ Auto-start timer immediately if in Hard mode (for “New Game” flow)
    if (difficulty == 'Hard') {
      startTimer();
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
