import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_provider_starter/models/task.dart';

void main() {
  group('Task Model JSON Parsing', () {
    test('Correctly parses complete JSON map', () {
      final json = {
        'id': '10',
        'title': 'Complete Flutter Project',
        'description': 'Finish TaskFlow implementation and prepare for interview.',
        'completed': true,
        'priority': 'high',
        'dueDate': '2026-09-30T10:00:00.000Z',
        'userId': '1',
      };

      final task = Task.fromJson(json);

      expect(task.id, '10');
      expect(task.title, 'Complete Flutter Project');
      expect(task.description, 'Finish TaskFlow implementation and prepare for interview.');
      expect(task.completed, isTrue);
      expect(task.priority, TaskPriority.high);
      expect(task.dueDate, isNotNull);
      expect(task.userId, '1');
    });

    test('Safely handles null and missing fields', () {
      final json = <String, dynamic>{
        'id': 5,
        'title': 'Minimal Task',
      };

      final task = Task.fromJson(json);

      expect(task.id, '5');
      expect(task.title, 'Minimal Task');
      expect(task.description, '');
      expect(task.completed, isFalse);
      expect(task.priority, TaskPriority.medium);
      expect(task.dueDate, isNull);
    });

    test('Serializes to JSON correctly', () {
      final date = DateTime.utc(2026, 9, 30);
      final task = Task(
        id: '1',
        title: 'Push to GitHub',
        description: 'Publish TaskFlow code',
        completed: false,
        priority: TaskPriority.medium,
        dueDate: date,
        userId: '2',
      );

      final json = task.toJson();

      expect(json['id'], '1');
      expect(json['title'], 'Push to GitHub');
      expect(json['priority'], 'medium');
      expect(json['completed'], isFalse);
      expect(json['dueDate'], date.toIso8601String());
      expect(json['category'], 'work');
    });

    test('Parses TaskCategory and falls back to other if null or invalid', () {
      final jsonWork = {'title': 'Work task', 'category': 'work'};
      expect(Task.fromJson(jsonWork).category, TaskCategory.work);

      final jsonCareer = {'title': 'Career task', 'category': 'career'};
      expect(Task.fromJson(jsonCareer).category, TaskCategory.career);

      final jsonInvalid = {'title': 'Unknown task', 'category': 'non_existent'};
      expect(Task.fromJson(jsonInvalid).category, TaskCategory.other);

      final jsonMissing = {'title': 'No cat task'};
      expect(Task.fromJson(jsonMissing).category, TaskCategory.other);
    });

    test('copyWith preserves and updates category', () {
      final task = Task(id: '1', title: 'Test', description: 'Test desc', category: TaskCategory.work);
      final updated = task.copyWith(category: TaskCategory.learning);
      expect(updated.category, TaskCategory.learning);
      expect(updated.title, 'Test');
    });
  });
}
