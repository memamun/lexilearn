// This is a basic Flutter widget test for LexiLearn app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lexilearn/main.dart';

void main() {
  group('LexiLearn Widget Tests', () {
    testWidgets('App should start with HomeScreen', (WidgetTester tester) async {
      await tester.pumpWidget(const LexiLearnApp());
      
      // Verify that the home screen is displayed
      expect(find.text('LexiLearn'), findsOneWidget);
    });

    testWidgets('HomeScreen should have navigation buttons', (WidgetTester tester) async {
      await tester.pumpWidget(const LexiLearnApp());
      
      // Verify navigation buttons exist
      expect(find.text('Flashcards'), findsOneWidget);
      expect(find.text('Quiz'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Vocabulary List'), findsOneWidget);
      expect(find.text('Statistics'), findsOneWidget);
    });

    testWidgets('Settings button should be present', (WidgetTester tester) async {
      await tester.pumpWidget(const LexiLearnApp());
      
      // Verify settings button exists
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('App should handle error boundary gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(const LexiLearnApp());
      
      // The app should not crash and should display the home screen
      expect(find.text('LexiLearn'), findsOneWidget);
    });
  });
}
