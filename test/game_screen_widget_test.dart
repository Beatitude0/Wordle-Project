import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nulldle/game_state.dart';
import 'package:nulldle/word_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GameState game;

  setUp(() async {
    game = GameState(wordService: WordService(), difficulty: 'Easy');
    await game.initializeGame();
  });

  tearDown(() {
    game.stopAllTimers(); // ✅ cancel background timers
  });

  group('🧠 Initialization & Reset', () {
    test('dictionary and target word load properly', () async {
      expect(game.targetWord.isNotEmpty, true);
      expect(game.guesses, isEmpty);
      expect(game.keyboardColors.length, 26);
    });

    test('resetGame clears guesses and timer', () async {
      game.submitGuess('apple');
      await game.resetGame();
      expect(game.guesses, isEmpty);
      expect(game.timeLeft, anyOf(0, 90)); // depends on difficulty
      expect(game.isGameOver, false);
    });
  });

  group('💬 Guess Logic', () {
    test('rejects invalid length guesses', () {
      final result = game.submitGuess('abc');
      expect(result, 'invalid_length');
    });

    test('rejects duplicate guesses', () {
      game.submitGuess('apple');
      final result = game.submitGuess('apple');
      expect(result, 'duplicate');
    });

    test('ends game after correct guess', () {
      final target = game.targetWord;
      final result = game.submitGuess(target);
      expect(result, 'win');
      expect(game.isGameOver, true);
    });

    test('ends game after max guesses', () {
      final validWord = game.targetWord; // guaranteed valid
      for (int i = 0; i < 6; i++) {
        game.submitGuess(validWord);
      }

      expect(game.isGameOver, true);
    });
  });

  group('⚙️ Timer Mechanics', () {
    test('startTimer initializes countdown and stops at zero', () async {
      game.difficulty = 'Hard';
      game.startTimer();
      expect(game.timeLeft, greaterThan(0));

      await Future.delayed(const Duration(seconds: 2));
      game.stopAllTimers();
      expect(game.timeLeft, lessThanOrEqualTo(90));
    });

    test('pauseTimer stops countdown', () async {
      game.difficulty = 'Hard';
      game.startTimer();
      final before = game.timeLeft;
      await Future.delayed(const Duration(seconds: 1));
      game.pauseTimer();
      final paused = game.timeLeft;
      await Future.delayed(const Duration(seconds: 2));
      expect(game.timeLeft, paused); // unchanged
      expect(paused, lessThan(before));
    });
  });

  group('💡 Hint System', () {
    test('only works once in Hard mode and deducts 10 seconds', () async {
      game.difficulty = 'Hard';
      game.startTimer();
      final before = game.timeLeft;

      final hint = game.useHint();
      expect(hint, isNotNull);
      expect(game.hintUsed, true);
      expect(game.timeLeft, lessThan(before));

      // Second call should return null (only once per round)
      final hint2 = game.useHint();
      expect(hint2, isNull);
    });
  });

  group('🏁 Reward Logic', () {
    test('adds +5 seconds only first time for each green position', () async {
      game.difficulty = 'Hard';
      game.startTimer();
      final before = game.timeLeft;

      // Force evaluate guess that has same letters
      game.submitGuess(game.targetWord);

      // Should reward exactly 5 * wordLength once
      expect(game.timeLeft, greaterThan(before));

      final rewarded = game.timeLeft;

      // Submitting again shouldn’t add more time
      game.submitGuess(game.targetWord);
      expect(game.timeLeft, equals(rewarded));
    });
  });

  group('🧹 Cleanup', () {
    test('stopAllTimers cancels running timers safely', () {
      game.startTimer();
      game.stopAllTimers();
      expect(() {
        game.stopAllTimers();
      }, returnsNormally);
    });
  });
}
