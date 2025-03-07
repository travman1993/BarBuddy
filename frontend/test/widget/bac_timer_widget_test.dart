import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barbuddy/widgets/bac_timer_widget.dart';
import 'package:barbuddy/models/bac_model.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';

void main() {
  group('BAC Timer Widget Tests', () {
    testWidgets('Widget displays correct BAC level - Safe', (WidgetTester tester) async {
      // Create a test BAC estimate (safe level)
      final now = DateTime.now();
      final estimate = BACEstimate(
        bac: 0.02,
        timestamp: now,
        soberTime: now.add(const Duration(hours: 1, minutes: 20)),
        legalTime: now,
        drinkIds: ['drink1'],
      );
      
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BACTimerWidget(
              bacEstimate: estimate,
              onRefresh: () {},
            ),
          ),
        ),
      );
      
      // Verify BAC value is displayed
      expect(find.text('0.020'), findsOneWidget);
      
      // Verify the widget shows "Under legal limit" text
      expect(find.text('Under legal limit'), findsOneWidget);
      
      // Verify the sober time text
      expect(find.text('Until completely sober'), findsOneWidget);
    });
    
    testWidgets('Widget displays correct BAC level - Danger', (WidgetTester tester) async {
      // Create a test BAC estimate (danger level)
      final now = DateTime.now();
      final estimate = BACEstimate(
        bac: 0.10,
        timestamp: now,
        soberTime: now.add(const Duration(hours: 6, minutes: 40)),
        legalTime: now.add(const Duration(hours: 1, minutes: 20)),
        drinkIds: ['drink1', 'drink2'],
      );
      
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BACTimerWidget(
              bacEstimate: estimate,
              onRefresh: () {},
              showDetailedInfo: true,
            ),
          ),
        ),
      );
      
      // Verify BAC value is displayed
      expect(find.text('0.100'), findsOneWidget);
      
      // Verify "Until legal to drive" text is shown since BAC is above legal limit
      expect(find.text('Until legal to drive'), findsOneWidget);
      
      // Verify warning text about legal limit
      expect(find.textContaining('illegal to drive'), findsOneWidget);
      
      // Verify CircularPercentIndicator is displayed
      expect(find.byType(CircularPercentIndicator), findsOneWidget);
    });
    
    testWidgets('Refresh button calls onRefresh callback', (WidgetTester tester) async {
      bool refreshCalled = false;
      
      // Create a test BAC estimate
      final now = DateTime.now();
      final estimate = BACEstimate(
        bac: 0.05,
        timestamp: now,
        soberTime: now.add(const Duration(hours: 3, minutes: 20)),
        legalTime: now.add(const Duration(minutes: 30)),
        drinkIds: ['drink1'],
      );
      
      // Build the widget with a callback that sets our flag
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BACTimerWidget(
              bacEstimate: estimate,
              onRefresh: () {
                refreshCalled = true;
              },
            ),
          ),
        ),
      );
      
      // Find and tap the refresh button
      final refreshButton = find.byIcon(Icons.refresh);
      expect(refreshButton, findsOneWidget);
      await tester.tap(refreshButton);
      
      // Verify callback was called
      expect(refreshCalled, isTrue);
    });
    
    testWidgets('Widget updates when BAC estimate changes', (WidgetTester tester) async {
      // Initial BAC estimate
      final now = DateTime.now();
      final initialEstimate = BACEstimate(
        bac: 0.03,
        timestamp: now,
        soberTime: now.add(const Duration(hours: 2)),
        legalTime: now,
        drinkIds: ['drink1'],
      );
      
      // Build the widget initially
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BACTimerWidget(
              bacEstimate: initialEstimate,
              onRefresh: () {},
            ),
          ),
        ),
      );
      
      // Verify initial BAC
      expect(find.text('0.030'), findsOneWidget);
      
      // New BAC estimate
      final updatedEstimate = BACEstimate(
        bac: 0.07,
        timestamp: now,
        soberTime: now.add(const Duration(hours: 4, minutes: 40)),
        legalTime: now.add(const Duration(minutes: 40)),
        drinkIds: ['drink1', 'drink2'],
      );
      
      // Update the widget with new estimate
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BACTimerWidget(
              bacEstimate: updatedEstimate,
              onRefresh: () {},
            ),
          ),
        ),
      );
      
      // Rebuild widget
      await tester.pump();
      
      // Verify updated BAC
      expect(find.text('0.070'), findsOneWidget);
    });
  });
}