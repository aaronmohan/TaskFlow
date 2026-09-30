enum TaskPriority {
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  static TaskPriority fromString(String? value) {
    if (value == null) return TaskPriority.medium;
    switch (value.trim().toLowerCase()) {
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      case 'medium':
      default:
        return TaskPriority.medium;
    }
  }
}

enum TaskCategory {
  work,
  career,
  learning,
  personal,
  shopping,
  other;

  String get label {
    switch (this) {
      case TaskCategory.work:
        return 'Work';
      case TaskCategory.career:
        return 'Career';
      case TaskCategory.learning:
        return 'Learning';
      case TaskCategory.personal:
        return 'Personal';
      case TaskCategory.shopping:
        return 'Shopping';
      case TaskCategory.other:
        return 'Other';
    }
  }

  static TaskCategory fromString(String? value) {
    if (value == null) return TaskCategory.other;
    switch (value.trim().toLowerCase()) {
      case 'work':
        return TaskCategory.work;
      case 'career':
        return TaskCategory.career;
      case 'learning':
        return TaskCategory.learning;
      case 'personal':
        return TaskCategory.personal;
      case 'shopping':
        return TaskCategory.shopping;
      case 'other':
      default:
        return TaskCategory.other;
    }
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final bool completed;
  final TaskPriority priority;
  final TaskCategory category;
  final DateTime? dueDate;
  final String userId;

  Task({
    required this.id,
    required this.title,
    required this.description,
    this.completed = false,
    this.priority = TaskPriority.medium,
    this.category = TaskCategory.work,
    this.dueDate,
    this.userId = '1',
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['dueDate'] != null) {
      if (json['dueDate'] is String && (json['dueDate'] as String).isNotEmpty) {
        parsedDate = DateTime.tryParse(json['dueDate']);
      } else if (json['dueDate'] is int) {
        parsedDate = DateTime.fromMillisecondsSinceEpoch(json['dueDate']);
      }
    }

    return Task(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      completed: json['completed'] == true || json['completed'] == 1 || json['completed'] == 'true',
      priority: TaskPriority.fromString(json['priority']?.toString()),
      category: json['category'] != null
          ? TaskCategory.fromString(json['category']?.toString())
          : TaskCategory.other,
      dueDate: parsedDate,
      userId: json['userId']?.toString() ?? '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'completed': completed,
      'priority': priority.name,
      'category': category.name,
      'dueDate': dueDate?.toIso8601String(),
      'userId': userId,
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? completed,
    TaskPriority? priority,
    TaskCategory? category,
    DateTime? dueDate,
    String? userId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      userId: userId ?? this.userId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
