import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_provider_starter/models/task.dart';
import 'package:flutter_provider_starter/providers/auth_provider.dart';
import 'package:flutter_provider_starter/providers/task_provider.dart';
import 'package:flutter_provider_starter/services/auth_service.dart';
import 'package:flutter_provider_starter/services/task_service.dart';
import 'package:flutter_provider_starter/screens/task_form_screen.dart';

class FakeEditTaskService extends TaskService {
  List<Task> tasks = [];
  Task? lastUpdated;

  @override
  Future<List<Task>> fetchTasks({required String token}) async => tasks;

  @override
  Future<Task> updateTask({required String token, required Task task}) async {
    lastUpdated = task;
    return task;
  }
}

void main() {
  testWidgets('TaskFormScreen in edit mode pre-fills fields and saves changes',
      (WidgetTester tester) async {
    final existingTask = Task(
      id: 'task-55',
      title: 'Initial Title',
      description: 'Initial Description',
      priority: TaskPriority.high,
      category: TaskCategory.work,
      completed: false,
    );

    final fakeService = FakeEditTaskService();
    fakeService.tasks = [existingTask];
    final authProvider = AuthProvider(AuthService());
    final taskProvider = TaskProvider(fakeService);
    await taskProvider.fetchTasks('');

    final navKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<TaskProvider>.value(value: taskProvider),
        ],
        child: MaterialApp(
          navigatorKey: navKey,
          home: const Scaffold(body: Text('Root Screen')),
        ),
      ),
    );
    navKey.currentState!.push(
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(taskToEdit: existingTask),
      ),
    );
    await tester.pumpAndSettle();

    // Verify pre-filled data
    expect(find.text('Edit Task'), findsOneWidget);
    expect(find.text('Initial Title'), findsOneWidget);
    expect(find.text('Initial Description'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);

    // Edit Title
    await tester.enterText(find.widgetWithText(TextFormField, 'Initial Title'), 'Updated Title Value');
    await tester.pumpAndSettle();

    // Save
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save Changes'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Task updated successfully'), findsOneWidget);
    expect(fakeService.lastUpdated?.title, 'Updated Title Value');
  });
}
