class GameLogic {
  final Set<String> dictionary;
  final String solution;
  final List<String> guesses = [];
  bool _finished = false;

  GameLogic(this.dictionary, this.solution);

  String submit(String word) {
    word = word.trim().toUpperCase();

    if (_finished) return 'lose';
    if (word.length != 5) return 'invalid_length';
    if (guesses.contains(word)) return 'duplicate';
    if (!dictionary.contains(word)) return 'not_in_dictionary';

    guesses.add(word);

    if (word == solution.toUpperCase()) {
      _finished = true;
      return 'win';
    }
    if (guesses.length >= 6) {
      _finished = true;
      return 'lose';
    }

    return 'continue';
  }
}
