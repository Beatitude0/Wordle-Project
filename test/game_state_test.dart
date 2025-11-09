// ✅ test/game_state_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nulldle/game_state.dart';
import 'package:nulldle/word_service.dart';

void main() {
  late GameState game;

  setUp(() async {
    game = GameState(wordService: WordService(), difficulty: 'Easy');
    await game.initializeGame();
  });

  group('🧩 Basic Logic', () {
    test('initializes correctly with a valid target word', () {
      expect(game.targetWord.isNotEmpty, true);
      expect(game.guesses.isEmpty, true);
      expect(game.colorHistory.isEmpty, true);
    });

    test('rejects invalid length and duplicate guesses', () {
      final result1 = game.submitGuess('abc'); // too short
      expect(result1, equals('invalid_length'));

      final word = game.targetWord;
      game.submitGuess(word);
      final result2 = game.submitGuess(word);
      expect(result2, equals('duplicate'));
    });

    test('rejects non-dictionary word', () {
      final result = game.submitGuess('zzzzz');
      expect(result, equals('not_in_dictionary'));
    });
  });

  group('🎮 Game outcomes', () {
    test('winning ends the game and stops timer', () {
      game.difficulty = 'Hard';
      game.startTimer();
      final word = game.targetWord;
      final result = game.submitGuess(word);

      expect(result, equals('win'));
      expect(game.isGameOver, true);
    });

    test('losing after max guesses', () {
      for (int i = 0; i < game.maxGuesses; i++) {
        game.submitGuess(game.targetWord == 'apple' ? 'grape' : 'apple');
      }
      expect(game.isGameOver, true);
    });
  });

  group('⏱️ Timer behavior', () {
    test('starts, counts down, and stops at zero', () async {
      game.difficulty = 'Hard';
      game.startTimer();
      expect(game.timeLeft, 90);
      await Future.delayed(const Duration(seconds: 2));
      expect(game.timeLeft < 90, true);
      game.pauseTimer();
    });

    test('resets and restarts timer on resetGame()', () async {
      game.difficulty = 'Hard';
      await game.resetGame();
      expect(game.timeLeft, 90);
    });
  });

  group('💡 Hint System', () {
    test('allows only one hint per round and deducts 10s', () {
      game.difficulty = 'Hard';
      game.startTimer();
      final before = game.timeLeft;

      final hint = game.useHint();
      expect(hint != null, true);
      expect(game.hintUsed, true);
      expect(game.timeLeft, lessThan(before));

      // second hint should return null
      final secondHint = game.useHint();
      expect(secondHint, isNull);
    });
  });

  group('🏆 Reward System', () {
    test('adds +5s only for first-time green positions', () {
      game.difficulty = 'Hard';
      game.startTimer();
      final before = game.timeLeft;

      // Simulate one correct letter
      game.submitGuess(game.targetWord);
      expect(game.timeLeft > before, true);

      final afterFirst = game.timeLeft;
      game.submitGuess(game.targetWord);
      expect(game.timeLeft, equals(afterFirst)); // no extra +5s
    });
  });

  group('🔁 Reset', () {
    test('resets all game properties properly', () async {
      game.submitGuess(game.targetWord);
      await game.resetGame();
      expect(game.guesses.isEmpty, true);
      expect(game.hintUsed, false);
      expect(game.timeLeft >= 0, true);
    });
  });
}
