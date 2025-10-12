// This is a basic Flutter widget test for LexiLearn app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:lexilearn/main.dart';

void main() {
  testWidgets('LexiLearn app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LexiLearnApp());

    // Verify that the app title is displayed.
    expect(find.text('LexiLearn'), findsOneWidget);

    // Verify that the main navigation buttons are present.
    expect(find.text('Flashcards'), findsOneWidget);
    expect(find.text('Quiz'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
  });
}
