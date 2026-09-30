import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_provider_starter/providers/auth_provider.dart';
import 'package:flutter_provider_starter/providers/task_provider.dart';
import 'package:flutter_provider_starter/services/auth_service.dart';
import 'package:flutter_provider_starter/services/task_service.dart';
import 'package:flutter_provider_starter/screens/task_form_screen.dart';

void main() {
  testWidgets('Create Task shows validation error when title is empty', (WidgetTester tester) async {
    final authProvider = AuthProvider(AuthService());
    final taskProvider = TaskProvider(TaskService());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<TaskProvider>.value(value: taskProvider),
        ],
        child: const MaterialApp(
          home: TaskFormScreen(),
        ),
      ),
    );

    expect(find.text('Create Task'), findsAtLeastNWidgets(1));
    expect(find.text('Task Title'), findsOneWidget);
    expect(find.text('Priority'), findsOneWidget);
    expect(find.text('Due Date'), findsOneWidget);

    // Tap submit button with empty title
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create Task'));
    await tester.tap(find.widgetWithText(FilledButton, 'Create Task'));
    await tester.pumpAndSettle();

    expect(find.text('Task title is required'), findsOneWidget);
  });
}
