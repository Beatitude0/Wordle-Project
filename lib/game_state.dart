import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'word_service.dart';

/// Handles all core game logic and persistent storage.
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
  String difficulty = 'Easy';

  // Timer
  Timer? _timer;
  int _timeLeft = 0;

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

  // --- Initialization ---
  Future<void> initializeGame() async {
    _dictionary = await _wordService.loadDictionary();
    _targetWord = _wordService.pickRandomWord(_dictionary);
    _resetState();
    notifyListeners();
  }

  void _resetState() {
    _guesses.clear();
    _colorHistory.clear();
    _keyboardColors.updateAll((_, __) => Colors.grey.shade300);
    _isGameOver = false;

    if (difficulty == 'Hard') {
      _timeLeft = 60;
      startTimer();
    } else {
      _timeLeft = 0;
      _timer?.cancel();
    }
  }

  // --- Timer logic ---
  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        _timeLeft--;
        notifyListeners();
      } else {
        timer.cancel();
        _isGameOver = true;
        notifyListeners();
      }
    });
  }

  void pauseTimer() => _timer?.cancel();

  void resumeTimer() {
    if (difficulty == 'Hard' && !_isGameOver && _timeLeft > 0) {
      startTimer();
    }
  }

  // --- Save game progress ---
  Future<void> saveGame() async {
    final prefs = await SharedPreferences.getInstance();
    final gameData = {
      'targetWord': _targetWord,
      'guesses': _guesses,
      'colorHistory':
          _colorHistory.map((row) => row.map((c) => c.value).toList()).toList(),
      'keyboardColors': _keyboardColors.map((k, v) => MapEntry(k, v.value)),
      'isGameOver': _isGameOver,
      'difficulty': difficulty,
      'timeLeft': _timeLeft,
    };

    await prefs.setString('savedGame', jsonEncode(gameData));
  }

  // --- Load game progress ---
  Future<void> loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('savedGame');
    if (data == null) return initializeGame();

    final decoded = jsonDecode(data);

    _dictionary = await _wordService.loadDictionary();
    _targetWord =
        decoded['targetWord'] ?? _wordService.pickRandomWord(_dictionary);
    _guesses
      ..clear()
      ..addAll(List<String>.from(decoded['guesses'] ?? []));
    _colorHistory
      ..clear()
      ..addAll((decoded['colorHistory'] as List)
          .map((row) => (row as List).map((v) => Color(v)).toList())
          .toList());
    _keyboardColors
      ..clear()
      ..addAll((decoded['keyboardColors'] as Map)
          .map((k, v) => MapEntry(k, Color(v))));
    _isGameOver = decoded['isGameOver'] ?? false;
    difficulty = decoded['difficulty'] ?? 'Easy';
    _timeLeft = decoded['timeLeft'] ?? 0;

    if (difficulty == 'Hard' && !_isGameOver && _timeLeft > 0) {
      resumeTimer();
    }

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
    _rewardTime(colors);
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

  // --- Reward extra time for greens (Hard mode) ---
  void _rewardTime(List<Color> colors) {
    if (difficulty != 'Hard') return;
    int greens = colors.where((c) => c == Colors.green).length;
    if (greens > 0) {
      _timeLeft += (5 * greens);
      notifyListeners();
    }
  }

  // --- Evaluate guesses ---
  List<Color> _evaluateGuess(String guess, String target) {
    final List<Color> colors = List.filled(wordLength, Colors.grey);
    final List<bool> used = List.filled(wordLength, false);

    for (int i = 0; i < wordLength; i++) {
      if (guess[i] == target[i]) {
        colors[i] = Colors.green;
        used[i] = true;
      }
    }

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

  // --- Keyboard updates ---
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

  // --- Reset game ---
  Future<void> resetGame() async {
    _timer?.cancel();
    _targetWord = _wordService.pickRandomWord(_dictionary);
    _resetState();
    notifyListeners();
  }

  // --- Clear saved data ---
  Future<void> clearSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('savedGame');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
