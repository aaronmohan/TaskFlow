import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_provider_starter/models/task.dart';
import 'package:flutter_provider_starter/providers/task_provider.dart';
import 'package:flutter_provider_starter/services/task_service.dart';

class FakeTaskService extends TaskService {
  @override
  Future<List<Task>> fetchTasks({required String token}) async {
    return [
      Task(
        id: '1',
        title: 'Complete Flutter Project',
        description: 'Finish the TaskFlow mobile application.',
        completed: false,
        priority: TaskPriority.high,
        category: TaskCategory.work,
      ),
      Task(
        id: '2',
        title: 'Update Resume',
        description: 'Add Flutter and REST API experience.',
        completed: true,
        priority: TaskPriority.high,
        category: TaskCategory.career,
      ),
      Task(
        id: '3',
        title: 'Prepare Interview Questions',
        description: 'Review Dart and state management concepts.',
        completed: false,
        priority: TaskPriority.medium,
        category: TaskCategory.learning,
      ),
      Task(
        id: '4',
        title: 'Learn Widget Testing',
        description: 'Write widget tests for dashboard.',
        completed: false,
        priority: TaskPriority.low,
        category: TaskCategory.learning,
      ),
    ];
  }

  @override
  Future<Task> createTask({required String token, required Task task}) async {
    return task.copyWith(id: '99');
  }

  @override
  Future<Task> updateTask({required String token, required Task task}) async {
    return task;
  }

  @override
  Future<bool> deleteTask({required String token, required String taskId}) async {
    return true;
  }
}

void main() {
  late TaskProvider taskProvider;

  setUp(() async {
    taskProvider = TaskProvider(FakeTaskService());
    await taskProvider.fetchTasks('dummy_token');
  });

  group('TaskProvider Dynamic Statistics', () {
    test('Calculates totals, completed, pending, and high priority accurately', () {
      expect(taskProvider.totalCount, 4);
      expect(taskProvider.completedCount, 1);
      expect(taskProvider.pendingCount, 3);
      expect(taskProvider.highPriorityCount, 2);
    });
  });

  group('Task Filtering', () {
    test('Filters by Pending tasks', () {
      taskProvider.setFilter(TaskFilter.pending);
      expect(taskProvider.filteredTasks.length, 3);
      expect(taskProvider.filteredTasks.every((t) => !t.completed), isTrue);
    });

    test('Filters by Completed tasks', () {
      taskProvider.setFilter(TaskFilter.completed);
      expect(taskProvider.filteredTasks.length, 1);
      expect(taskProvider.filteredTasks.first.title, 'Update Resume');
    });

    test('Filters by High Priority tasks', () {
      taskProvider.setFilter(TaskFilter.highPriority);
      expect(taskProvider.filteredTasks.length, 2);
      expect(taskProvider.filteredTasks.every((t) => t.priority == TaskPriority.high), isTrue);
    });

    test('Filters by Category correctly', () {
      taskProvider.setCategoryFilter(TaskCategory.learning);
      expect(taskProvider.filteredTasks.length, 2);
      expect(taskProvider.filteredTasks.every((t) => t.category == TaskCategory.learning), isTrue);

      taskProvider.setCategoryFilter(TaskCategory.work);
      expect(taskProvider.filteredTasks.length, 1);
      expect(taskProvider.filteredTasks.first.title, 'Complete Flutter Project');

      // Clear filter
      taskProvider.setCategoryFilter(null);
      expect(taskProvider.filteredTasks.length, 4);
    });
  });

  group('Task Search', () {
    test('Searches by title case-insensitively', () {
      taskProvider.setSearchQuery('resume');
      expect(taskProvider.filteredTasks.length, 1);
      expect(taskProvider.filteredTasks.first.title, 'Update Resume');
    });

    test('Searches by description content', () {
      taskProvider.setSearchQuery('state management');
      expect(taskProvider.filteredTasks.length, 1);
      expect(taskProvider.filteredTasks.first.title, 'Prepare Interview Questions');
    });

    test('Searches by category label', () {
      taskProvider.setSearchQuery('Learning');
      expect(taskProvider.filteredTasks.length, 2);
    });

    test('Combines search and filter simultaneously', () {
      taskProvider.setFilter(TaskFilter.pending);
      taskProvider.setSearchQuery('Flutter');
      // Matches "Complete Flutter Project" (pending) but not "Update Resume" (completed)
      expect(taskProvider.filteredTasks.length, 1);
      expect(taskProvider.filteredTasks.first.title, 'Complete Flutter Project');
    });
  });

  group('Task CRUD Operations', () {
    test('Toggles task completion state properly', () async {
      final task = taskProvider.allTasks.first;
      expect(task.completed, isFalse);

      await taskProvider.toggleTaskCompletion('dummy_token', task);

      final updated = taskProvider.allTasks.firstWhere((t) => t.id == task.id);
      expect(updated.completed, isTrue);
      expect(taskProvider.completedCount, 2);
    });

    test('Creates new task successfully', () async {
      final newTask = Task(
        id: 'new-1',
        title: 'New Grocery Task',
        description: 'Milk and eggs',
        priority: TaskPriority.low,
        category: TaskCategory.shopping,
      );

      final success = await taskProvider.addTask('dummy_token', newTask);
      expect(success, isTrue);
      expect(taskProvider.totalCount, 5);
      expect(taskProvider.allTasks.first.title, 'New Grocery Task');
    });

    test('Deletes task successfully', () async {
      final initialCount = taskProvider.totalCount;
      final success = await taskProvider.deleteTask('dummy_token', '1');
      expect(success, isTrue);
      expect(taskProvider.totalCount, initialCount - 1);
      expect(taskProvider.allTasks.any((t) => t.id == '1'), isFalse);
    });
  });
}
