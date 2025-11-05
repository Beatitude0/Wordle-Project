# Nulldle AI Agent Instructions

This is a Flutter implementation of a Wordle-like word guessing game. Below are key aspects of the codebase to understand:

## Project Architecture

- **Main Components**:
  - `main.dart`: Entry point and home screen UI
  - `game_screen.dart`: Core game logic and UI
  - `assets/english_dict.txt`: Word dictionary for game play

### Key Patterns

1. **Widget Structure**:
   - `NulldleText`: Custom text widget with consistent styling (Courier font, pink color)
   - Stateless widgets for static UI (HomeScreen)
   - Stateful widget for game logic (GameScreen)

2. **Game State Management**:
   - State maintained in `_GameScreenState` with:
     - `_targetWord`: Current word to guess
     - `_guesses`: List of player attempts
     - `_keyboardColors`: Map tracking letter states
     - `_dictionary`: List of valid 5-letter words

3. **UI Conventions**:
   - Color scheme: Pink primary, Green/Yellow/Red for letter states
   - Consistent font: Courier
   - Standard button styling with pink text

## Development Workflows

1. **Running the App**:
   ```bash
   flutter run
   ```

2. **Testing**:
   - Widget tests in `test/widget_test.dart`
   - Run tests with:
   ```bash
   flutter test
   ```

3. **Asset Management**:
   - New assets must be declared in `pubspec.yaml`
   - Current assets:
     - `assets/english_dict.txt`: Word list
     - `assets/title.png`: Game title image

## Common Tasks

1. **Adding Words**:
   - Modify `assets/english_dict.txt`
   - Words must be 5 letters, lowercase, one per line

2. **UI Modifications**:
   - Use `NulldleText` widget for consistent text styling
   - Follow existing color scheme (primary: Pink)
   - Maintain responsive layout using Expanded and flexible widgets

3. **Game Logic Changes**:
   - Core game logic in `_GameScreenState`
   - Color calculation in `_tileColor` method
   - Keyboard state updates in `_updateKeyboard`

## Dependencies

- Flutter SDK ^3.6.0
- cupertino_icons ^1.0.8
- flutter_lints ^5.0.0 (dev)