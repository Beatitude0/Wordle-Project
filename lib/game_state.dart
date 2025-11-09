import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'word_service.dart';

/// Handles all game logic and state — separated cleanly from UI.
/// Supports Easy (no timer) and Hard (timer + bonus seconds).
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
  String difficulty = 'Easy'; // Either "Easy" or "Hard"

  // --- Timer fields ---
  Timer? _timer;
  int _timeLeft = 0;

  // --- Hint fields (optional future use) ---
  bool _hintUsed = false;
  String? _hintLetter;

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

  // --- Initialization ---
  Future<void> initializeGame() async {
    _dictionary = await _wordService.loadDictionary();
    _targetWord = _wordService.pickRandomWord(_dictionary);
    if (_targetWord.isEmpty) _targetWord = 'apple'; // fallback

    _guesses.clear();
    _colorHistory.clear();
    _keyboardColors.updateAll((_, __) => Colors.grey.shade300);
    _isGameOver = false;
    _hintUsed = false;
    _hintLetter = null;

    if (difficulty == 'Hard') {
      _timeLeft = 60;
    } else {
      _timeLeft = 0;
    }

    notifyListeners();
  }

  // --- Timer logic ---
  void startTimer({VoidCallback? onTimerEnd}) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        _timeLeft--;
        notifyListeners();
      } else {
        timer.cancel();
        _isGameOver = true;
        notifyListeners();
        if (onTimerEnd != null) onTimerEnd(); // triggers lose popup
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
  }

  void resumeTimer({VoidCallback? onTimerEnd}) {
    if (difficulty == 'Hard' && !_isGameOver && _timeLeft > 0) {
      startTimer(onTimerEnd: onTimerEnd);
    }
  }

  // --- Reward time for green letters ---
  void _rewardTimeForCorrectLetters(List<Color> colors) {
    if (difficulty != 'Hard') return;
    int greenCount = colors.where((c) => c == Colors.green).length;
    if (greenCount > 0) {
      _timeLeft += (5 * greenCount);
      notifyListeners();
    }
  }

  // --- Hint system (future use) ---
  void useHint() {
    if (_hintUsed || _isGameOver) return;
    final available = List.generate(wordLength, (i) => i).toList();
    final index = available[Random().nextInt(available.length)];
    _hintLetter = _targetWord[index];
    _hintUsed = true;
    notifyListeners();
  }

  // --- Submit guess ---
  String submitGuess(String guess) {
    guess = guess.toLowerCase();

    if (_isGameOver) return 'game_over';
    if (guess.length != wordLength) return 'invalid_length';
    if (!_dictionary.contains(guess)) return 'not_in_dictionary';
    if (_guesses.contains(guess)) return 'duplicate';

    final colors = _evaluateGuess(guess, _targetWord);
    _rewardTimeForCorrectLetters(colors);

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

  // --- Guess evaluation ---
  List<Color> _evaluateGuess(String guess, String target) {
    final List<Color> colors = List.filled(wordLength, Colors.grey);
    final List<bool> used = List.filled(wordLength, false);

    // Pass 1: Green
    for (int i = 0; i < wordLength; i++) {
      if (guess[i] == target[i]) {
        colors[i] = Colors.green;
        used[i] = true;
      }
    }

    // Pass 2: Yellow
    for (int i = 0; i < wordLength; i++) {
      if (colors[i] == Colors.green) continue;
      for (int j = 0; j < wordLength; j++) {
        if (!used[j] && guess[i] == target[j]) {
          colors[i] = Colors.yellow;
          used[j] = true;
          break;
        }
      }
    }

    return colors;
  }

  // --- Keyboard color update ---
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

  // --- Save & Load Game ---
  Future<void> saveGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('guesses', _guesses);
    await prefs.setString('targetWord', _targetWord);
    await prefs.setString('difficulty', difficulty);
    await prefs.setInt('timeLeft', _timeLeft);
  }

  Future<void> loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    _dictionary = await _wordService.loadDictionary();

    _targetWord = prefs.getString('targetWord') ?? '';
    _guesses
      ..clear()
      ..addAll(prefs.getStringList('guesses') ?? []);
    _colorHistory.clear();
    for (final g in _guesses) {
      _colorHistory.add(_evaluateGuess(g, _targetWord));
    }
    difficulty = prefs.getString('difficulty') ?? 'Easy';
    _timeLeft = prefs.getInt('timeLeft') ?? (difficulty == 'Hard' ? 60 : 0);
    _isGameOver = false;
    _keyboardColors.updateAll((_, __) => Colors.grey.shade300);
    notifyListeners();
  }

  // --- Reset game ---
  Future<void> resetGame() async {
    _timer?.cancel();
    await initializeGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
