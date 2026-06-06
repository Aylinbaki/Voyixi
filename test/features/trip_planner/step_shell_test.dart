import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyixi/features/trip_planner/step_shell.dart';

void main() {
  Widget createWidget({
    bool canGoNext = true,
    bool isLoading = false,
    bool isLastStep = false,
    VoidCallback? onNext,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: StepShell(
          icon: Icons.map,
          title: 'Test Title',
          canGoNext: canGoNext,
          onNext: onNext ?? () {},
          isLoading: isLoading,
          isLastStep: isLastStep,
          child: const Text('Test Child Content'),
        ),
      ),
    );
  }

  group('StepShell Widget Tests', () {
    testWidgets('renders title and child content', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Child Content'), findsOneWidget);
      expect(find.byIcon(Icons.map), findsOneWidget);
    });

    testWidgets('next button shows "Next" when not the last step', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget(isLastStep: false));
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('next button shows "Create Plan" when it is the last step', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget(isLastStep: true));
      expect(find.text('Create Plan'), findsOneWidget);
    });

    testWidgets('calls onNext when button is tapped and canGoNext is true', (WidgetTester tester) async {
      bool called = false;
      await tester.pumpWidget(createWidget(
        canGoNext: true,
        onNext: () => called = true,
      ));

      await tester.tap(find.text('Next'));
      expect(called, isTrue);
    });

    testWidgets('does not call onNext when button is tapped and canGoNext is false', (WidgetTester tester) async {
      bool called = false;
      await tester.pumpWidget(createWidget(
        canGoNext: false,
        onNext: () => called = true,
      ));

      await tester.tap(find.text('Next'));
      expect(called, isFalse);
    });

    testWidgets('shows loading indicator when isLoading is true', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget(isLoading: true));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Next'), findsNothing);
    });
  });
}
