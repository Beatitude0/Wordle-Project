import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// Use relative imports so it works even if your package name changes.
import 'package:nulldle/game_state.dart';
import 'package:nulldle/game_screen.dart';

/// Wraps GameScreen in Provider + MaterialApp and initializes the game.
Widget _wrap({String difficulty = 'Easy'}) {
  return ChangeNotifierProvider(
    create: (_) => GameState(difficulty: '')
      ..difficulty = difficulty
      ..initializeGame(),
    child: const MaterialApp(home: GameScreen()),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🧩 Basic UI', () {
    testWidgets('loads title, mode switch, reset button, and keyboard listener',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('Nulldle'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      expect(find.textContaining('Mode:'), findsOneWidget);
      expect(find.byTooltip('Reset Game'), findsOneWidget);
      // RawKeyboardListener is present to capture physical keys
      expect(find.byType(RawKeyboardListener), findsOneWidget);
    });
  });

  group('🎮 Typing & Reset', () {
    testWidgets('typing via physical keyboard fills current row (Easy mode)',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Send a key. We ensure a frame after each for the UI to update.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
      await tester.pump();

      // The letter "A" should appear in the current (active) row.
      expect(find.text('A'), findsWidgets);
    });

    testWidgets('refresh button resets the grid', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyB);
      await tester.pump();

      expect(find.text('B'), findsWidgets);

      await tester.tap(find.byTooltip('Reset Game'));
      await tester.pumpAndSettle();

      // After reset, the typed letter should be gone.
      expect(find.text('B'), findsNothing);
    });
  });

  group('⚙️ Difficulty & Countdown', () {
    testWidgets('switching to Hard shows confirmation popup', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Start Hard Mode?'), findsOneWidget);
      expect(find.textContaining('90 seconds'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Cancel keeps Easy mode, Start triggers countdown and timer',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Open popup
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Cancel first: should revert to Easy
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Easy'), findsOneWidget);

      // Open again, this time Start
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start'));
      await tester.pump(); // start of countdown

      // Countdown overlay should show "3", then "2", "1", "GO!"
      // We’ll step through it quickly
      expect(find.text('3'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('2'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('1'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('GO!'), findsOneWidget);

      // After GO!, overlay disappears and timer appears
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Timer row visible (icon + seconds)
      expect(find.byIcon(Icons.timer), findsWidgets);
    });

    testWidgets('switching modes before first guess clears grid',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Type a letter
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      await tester.pump();
      expect(find.text('C'), findsWidgets);

      // Switch to Hard and cancel (should revert to Easy and clear)
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Grid should be cleared by your implementation when changing modes pre-guess
      expect(find.text('C'), findsNothing);
    });
  });

  group('⏱️ Timer & Hint', () {
    testWidgets('hint button appears only in Hard, usable once, then disabled',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Turn on Hard, Start
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start'));
      // Let countdown finish quickly
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // Hint button should be visible
      final hintBtnFinder =
          find.widgetWithText(ElevatedButton, 'Use Hint (-10s)');
      expect(hintBtnFinder, findsOneWidget);

      // Tap once
      await tester.tap(hintBtnFinder);
      await tester.pumpAndSettle();

      // Snackbar shows "Hint:"
      expect(find.textContaining('Hint:'), findsOneWidget);

      // Button now disabled (onPressed == null)
      final ElevatedButton hintBtn = tester.widget(hintBtnFinder);
      expect(hintBtn.onPressed, isNull);
    });
  });

  group('🏁 Completion & Exit', () {
    testWidgets('timeout dialog appears with correct message', (tester) async {
      // Build with a pre-configured hard-mode GameState that is already out of time
      final game = GameState();
      game.difficulty = 'Hard';
      await game.initializeGame();
      game.timeLeft = 0;
      game.isGameOver = true;

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: game,
          child: const MaterialApp(home: GameScreen()),
        ),
      );

      // The dialog is triggered in build via addPostFrameCallback, so pump
      await tester.pumpAndSettle();

      expect(find.textContaining('You ran out of time!'), findsOneWidget);
      expect(find.textContaining('⏰'), findsWidgets);
    });

    testWidgets('back navigation opens exit confirmation dialog',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Trigger back
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Exit to Home?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Exit'), findsOneWidget);
    });
  });
}
