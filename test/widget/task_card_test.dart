import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_provider_starter/models/task.dart';
import 'package:flutter_provider_starter/widgets/task_card.dart';

void main() {
  testWidgets('TaskCard displays title, description, priority and pending status', (WidgetTester tester) async {
    final task = Task(
      id: '1',
      title: 'Complete Flutter Project',
      description: 'Finish TaskFlow implementation and prepare for interview.',
      completed: false,
      priority: TaskPriority.high,
      dueDate: DateTime.now().add(const Duration(days: 2)),
    );

    bool tapped = false;
    bool toggled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskCard(
            task: task,
            onTap: () => tapped = true,
            onToggleComplete: () => toggled = true,
          ),
        ),
      ),
    );

    expect(find.text('Complete Flutter Project'), findsOneWidget);
    expect(find.text('Finish TaskFlow implementation and prepare for interview.'), findsOneWidget);
    expect(find.text('HIGH'), findsOneWidget);
    expect(find.text('○ Pending'), findsOneWidget);

    // Tap on card
    await tester.tap(find.text('Complete Flutter Project'));
    expect(tapped, isTrue);

    // Tap on status toggle icon
    await tester.tap(find.byIcon(Icons.radio_button_unchecked));
    expect(toggled, isTrue);
  });

  testWidgets('TaskCard displays completed status and check icon', (WidgetTester tester) async {
    final task = Task(
      id: '2',
      title: 'Update Resume',
      description: 'Finalize Flutter internship resume.',
      completed: true,
      priority: TaskPriority.medium,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskCard(
            task: task,
            onTap: () {},
            onToggleComplete: () {},
          ),
        ),
      ),
    );

    expect(find.text('Update Resume'), findsOneWidget);
    expect(find.text('✓ Completed'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });
}
