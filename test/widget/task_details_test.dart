import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_provider_starter/models/task.dart';
import 'package:flutter_provider_starter/providers/auth_provider.dart';
import 'package:flutter_provider_starter/providers/task_provider.dart';
import 'package:flutter_provider_starter/services/auth_service.dart';
import 'package:flutter_provider_starter/services/task_service.dart';
import 'package:flutter_provider_starter/screens/task_details_screen.dart';

class FakeTaskDetailsService extends TaskService {
  List<Task> tasks;
  FakeTaskDetailsService(this.tasks);

  @override
  Future<List<Task>> fetchTasks({required String token}) async => tasks;

  @override
  Future<Task> updateTask({required String token, required Task task}) async {
    final idx = tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) {
      tasks[idx] = task;
    }
    return task;
  }

  @override
  Future<bool> deleteTask({required String token, required String taskId}) async {
    tasks.removeWhere((t) => t.id == taskId);
    return true;
  }
}

void main() {
  testWidgets('TaskDetailsScreen displays full details and supports status toggle and delete dialog',
      (WidgetTester tester) async {
    final sampleTask = Task(
      id: 'task-100',
      title: 'Review System Architecture',
      description: 'Analyze Provider state and responsive navigation patterns.',
      priority: TaskPriority.high,
      category: TaskCategory.work,
      completed: false,
      dueDate: DateTime.utc(2026, 10, 15),
    );

    final fakeService = FakeTaskDetailsService([sampleTask]);
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
          home: const Scaffold(body: Text('Root Home')),
        ),
      ),
    );
    navKey.currentState!.push(
      MaterialPageRoute(
        builder: (_) => const TaskDetailsScreen(taskId: 'task-100'),
      ),
    );
    await tester.pumpAndSettle();

    // Verify task details
    expect(find.text('Review System Architecture'), findsOneWidget);
    expect(find.text('Analyze Provider state and responsive navigation patterns.'), findsOneWidget);
    expect(find.text('HIGH'), findsOneWidget);
    expect(find.text('Work'), findsWidgets);
    expect(find.textContaining('Pending'), findsWidgets);

    // Verify Delete confirmation dialog pops up
    await tester.tap(find.byTooltip('Delete Task').first);
    await tester.pumpAndSettle();

    expect(find.text('Delete Task?'), findsOneWidget);
    expect(find.text('Are you sure you want to delete this task?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    // Dismiss dialog with Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Task?'), findsNothing);

    // Now tap delete and confirm
    await tester.tap(find.byTooltip('Delete Task').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Task deleted successfully'), findsOneWidget);
    expect(taskProvider.allTasks.any((t) => t.id == 'task-100'), isFalse);
  });
}
