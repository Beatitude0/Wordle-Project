import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

/// Handles loading the dictionary and selecting random words for the game.
///
/// This service isolates file-access and randomness so that the rest of the
/// game can be easily tested without depending on asset files.
class WordService {
  final int wordLength;

  WordService({this.wordLength = 5});

  /// Loads a list of words of the specified [wordLength] from the assets file.
  Future<List<String>> loadDictionary() async {
    final rawData = await rootBundle.loadString('assets/english_dict.txt');
    final words = rawData
        .split('\n')
        .map((w) => w.trim().toLowerCase())
        .where((w) => w.length == wordLength)
        .toList();
    return words;
  }

  /// Returns a random word from the dictionary.
  String pickRandomWord(List<String> dictionary) {
    if (dictionary.isEmpty) {
      throw StateError('Dictionary is empty.');
    }
    final random = Random();
    return dictionary[random.nextInt(dictionary.length)];
  }
}
