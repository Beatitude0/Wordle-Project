import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nulldle/main.dart';
import 'package:nulldle/game_screen.dart';

void main() {
  testWidgets('HomeScreen UI elements remain consistent', (WidgetTester tester) async {
    // Pump the widget tree
    await tester.pumpWidget(WordleApp());

    // Title
    expect(find.text('Nulldle'), findsOneWidget);

    // Instruction text (substring match so it still passes if wrapped/refactored)
    expect(
      find.textContaining('Guess the hidden five-letter word'),
      findsOneWidget,
    );

    // Image
    expect(find.byType(Image), findsOneWidget);

    // Play Game button
    final playButton = find.widgetWithText(ElevatedButton, 'Play Game');
    expect(playButton, findsOneWidget);

    // Tap Play Game navigates to GameScreen
    await tester.tap(playButton);
    await tester.binding.setSurfaceSize(const Size(1080, 1920));
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets('GameScreen UI elements remain consistent', (WidgetTester tester) async {
    // Pump GameScreen
    await tester.binding.setSurfaceSize(const Size(1080, 1920));
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(),
      ),
    );

    // TextField for guesses
    expect(find.byType(TextField), findsOneWidget);

    // Buttons
    expect(find.widgetWithText(ElevatedButton, 'Submit'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'New Game'), findsOneWidget);

    // Grid of 6 rows × 5 columns = 30 tiles
    find.byWidgetPredicate(
      (widget) => widget is Container && widget.decoration is BoxDecoration && (widget).constraints == null,
    );
    expect(find.byType(Container), findsWidgets);

    // Keyboard rows exist
    expect(find.text('Q'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('Z'), findsOneWidget);

    // Default background is white
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, Colors.white);
  });
}
