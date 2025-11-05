import 'package:flutter_test/flutter_test.dart';
import 'package:nulldle/game_logic.dart';

void main() {
  final dict = {'APPLE', 'BERRY', 'CHAIR', 'WATER', 'ROUTE'};

  test('accepts only 5-letter words', () {
    final logic = GameLogic(dict, 'APPLE');
    expect(logic.submit('HI'), equals('invalid_length'));
  });

  test('rejects duplicates', () {
    final logic = GameLogic(dict, 'APPLE');
    logic.submit('APPLE');
    expect(logic.submit('APPLE'), equals('duplicate'));
  });

  test('rejects non-dictionary words', () {
    final logic = GameLogic(dict, 'APPLE');
    expect(logic.submit('ZZZZZ'), equals('not_in_dictionary'));
  });

  test('win condition triggers correctly', () {
    final logic = GameLogic(dict, 'APPLE');
    expect(logic.submit('APPLE'), equals('win'));
  });

  test('lose after 6 valid attempts', () {
    final logic =
        GameLogic({'APPLE', 'BERRY', 'CHAIR', 'WATER', 'ROUTE'}, 'APPLE');
    for (int i = 0; i < 6; i++) {
      logic.submit('BERRY'); // 6 wrong guesses
    }
    expect(logic.submit('ROUTE'), equals('lose'));
  });

  test('game stops accepting input after loss', () {
    final logic =
        GameLogic({'APPLE', 'BERRY', 'CHAIR', 'WATER', 'ROUTE'}, 'APPLE');
    for (int i = 0; i < 6; i++) {
      logic.submit('BERRY');
    }
    expect(logic.submit('APPLE'),
        equals('lose')); // should not change result after loss
  });
  test('continues game for valid incorrect guesses', () {
    final logic = GameLogic(dict, 'APPLE');
    expect(logic.submit('BERRY'), equals('continue'));
  });
}
