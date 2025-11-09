import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nulldle/game_screen.dart';
import 'package:nulldle/game_state.dart';

Widget createTestableGameScreen() {
  return ChangeNotifierProvider(
    create: (_) => GameState(difficulty: '')..initializeGame(),
    child: const MaterialApp(home: GameScreen()),
  );
}

void main() {
  testWidgets('Displays Nulldle title', (tester) async {
    await tester.pumpWidget(createTestableGameScreen());
    expect(find.text('Nulldle'), findsOneWidget);
  });

  testWidgets('Can tap on keyboard and input letters', (tester) async {
    await tester.pumpWidget(createTestableGameScreen());
    await tester.tap(find.text('A'));
    await tester.pump();
    expect(find.text('A'), findsWidgets);
  });

  testWidgets('Switching to Hard Mode shows popup', (tester) async {
    await tester.pumpWidget(createTestableGameScreen());
    final switchFinder = find.byType(Switch);
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
    expect(find.text('Start Hard Mode?'), findsOneWidget);
  });

  testWidgets('Pressing refresh resets game', (tester) async {
    await tester.pumpWidget(createTestableGameScreen());
    await tester.tap(find.byTooltip('Reset Game'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Mode:'), findsOneWidget);
  });

  testWidgets('Exit confirmation popup appears', (tester) async {
    await tester.pumpWidget(createTestableGameScreen());
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Exit to Home?'), findsOneWidget);
  });
}
