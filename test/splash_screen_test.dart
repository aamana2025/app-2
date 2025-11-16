import 'package:aamanaclassroom/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SplashScreen Tests', () {
    testWidgets('SplashScreen displays logo', (WidgetTester tester) async {
      // Create a test app with the splash screen
      await tester.pumpWidget(
        MaterialApp(
          home: const SplashScreen(),
        ),
      );

      // Wait for the widget to build
      await tester.pump();

      // Verify that the logo (school icon) is present
      expect(find.byIcon(Icons.school), findsOneWidget);

      // Verify the background color is white
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.white);
    });

    testWidgets('SplashScreen has proper structure',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const SplashScreen(),
        ),
      );

      await tester.pump();

      // Check that the main components are present
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(Center), findsWidgets);
      expect(find.byType(Column), findsOneWidget);
      expect(find.byIcon(Icons.school), findsOneWidget);
    });
  });
}
