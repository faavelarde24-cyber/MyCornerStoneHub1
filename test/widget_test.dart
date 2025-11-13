// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cornerstone_hub/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(hasSeenIntro: true),
      ),
    );

    // Verify that the app builds without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Shows intro screen when hasSeenIntro is false', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(hasSeenIntro: false),
      ),
    );

    // Verify intro wrapper is shown
    expect(find.byType(IntroWrapper), findsOneWidget);
  });

  testWidgets('Shows login page when hasSeenIntro is true', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(hasSeenIntro: true),
      ),
    );

    await tester.pumpAndSettle();

    // Verify login page is shown (adjust based on your LoginPage implementation)
    expect(find.byType(IntroWrapper), findsNothing);
  });
}