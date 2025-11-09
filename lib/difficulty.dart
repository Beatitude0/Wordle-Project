//difficulty.dart
//Defines the difficulty modes and their behaviour.

enum Difficulty { easy, hard }

extension DifficultyExtension on Difficulty {
  /// User-friendly label for dropdowns and UI.
  String get label {
    switch (this) {
      case Difficulty.hard:
        return "Hard";
      case Difficulty.easy:
        return "Easy";
    }
  }

  /// Starting time in seconds for timer-based modes.
  int get initialTime {
    switch (this) {
      case Difficulty.hard:
        return 60;
      case Difficulty.easy:
        return 0;
    }
  }

  /// Whether this difficulty mode includes a timer.
  bool get hasTimer => this == Difficulty.hard;
}
