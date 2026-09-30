import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/storage_service.dart';

enum TaskFilter {
  all('All'),
  pending('Pending'),
  completed('Completed'),
  highPriority('High Priority'),
  mediumPriority('Medium Priority'),
  lowPriority('Low Priority');

  final String label;
  const TaskFilter(this.label);
}

class TaskProvider extends ChangeNotifier {
  final TaskService _taskService;
  final StorageService? _storageService;

  TaskProvider(this._taskService, [this._storageService]) {
    _loadInitialCachedTasks();
  }

  void _loadInitialCachedTasks() {
    final cached = _storageService?.getCachedTasks();
    if (cached != null && cached.isNotEmpty) {
      _tasks = List<Task>.from(cached);
    }
  }

  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  TaskFilter _selectedFilter = TaskFilter.all;

  // Getters
  List<Task> get allTasks => List.unmodifiable(_tasks);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  TaskFilter get selectedFilter => _selectedFilter;
  TaskCategory? _selectedCategory;
  TaskCategory? get selectedCategory => _selectedCategory;

  // Filtered & Searched Tasks List
  List<Task> get filteredTasks {
    return _tasks.where((task) {
      // 1. Status / Priority Filter match
      bool matchesFilter = true;
      switch (_selectedFilter) {
        case TaskFilter.all:
          matchesFilter = true;
          break;
        case TaskFilter.pending:
          matchesFilter = !task.completed;
          break;
        case TaskFilter.completed:
          matchesFilter = task.completed;
          break;
        case TaskFilter.highPriority:
          matchesFilter = task.priority == TaskPriority.high;
          break;
        case TaskFilter.mediumPriority:
          matchesFilter = task.priority == TaskPriority.medium;
          break;
        case TaskFilter.lowPriority:
          matchesFilter = task.priority == TaskPriority.low;
          break;
      }
      if (!matchesFilter) return false;

      // 2. Category Filter match
      if (_selectedCategory != null && task.category != _selectedCategory) {
        return false;
      }

      // 3. Search query match (title, description, and category)
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      final titleMatch = task.title.toLowerCase().contains(q);
      final descMatch = task.description.toLowerCase().contains(q);
      final catMatch = task.category.label.toLowerCase().contains(q);
      return titleMatch || descMatch || catMatch;
    }).toList();
  }

  // Dynamic Statistics
  int get totalCount => _tasks.length;
  int get completedCount => _tasks.where((t) => t.completed).length;
  int get pendingCount => _tasks.where((t) => !t.completed).length;
  int get highPriorityCount =>
      _tasks.where((t) => t.priority == TaskPriority.high).length;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter(TaskFilter filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void setCategoryFilter(TaskCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Initialization & Fetching
  Future<void> fetchTasks(String token, {bool forceRefresh = false}) async {
    // If tasks are already loaded in memory and not forcing a refresh, preserve them!
    if (_tasks.isNotEmpty && !forceRefresh) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Check local storage first for persistent load
    final cached = _storageService?.getCachedTasks();
    if (cached != null && cached.isNotEmpty && !forceRefresh) {
      _tasks = List<Task>.from(cached);
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final fetched = await _taskService.fetchTasks(token: token);
      final currentSaved = _storageService?.getCachedTasks() ?? _tasks;
      if (currentSaved.isNotEmpty && !forceRefresh) {
        _tasks = List<Task>.from(currentSaved);
      } else {
        _tasks = List<Task>.from(fetched);
      }
      await _storageService?.saveTasks(_tasks);
    } catch (e) {
      if (_tasks.isEmpty) {
        final cachedTasks = _storageService?.getCachedTasks();
        if (cachedTasks != null && cachedTasks.isNotEmpty) {
          _tasks = List<Task>.from(cachedTasks);
        } else {
          // Fallback to default demo tasks so the app is always functional
          _tasks = List<Task>.from(TaskService.defaultSampleTasks);
          await _storageService?.saveTasks(_tasks);
        }
      }
      _errorMessage = 'Unable to load tasks. Please check your internet connection.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addTask(String token, Task newTask) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final createdTask = await _taskService.createTask(
        token: token,
        task: newTask,
      );
      _tasks.insert(0, createdTask);
      await _storageService?.saveTasks(_tasks);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (_) {
      // Local addition fallback
      _tasks.insert(0, newTask);
      await _storageService?.saveTasks(_tasks);
      _isLoading = false;
      notifyListeners();
      return true;
    }
  }

  Future<bool> updateTask(String token, Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return false;

    _tasks[index] = task;
    notifyListeners();

    try {
      await _taskService.updateTask(token: token, task: task);
      await _storageService?.saveTasks(_tasks);
      return true;
    } catch (_) {
      // Keep optimistic update locally
      await _storageService?.saveTasks(_tasks);
      return true;
    }
  }

  Future<void> toggleTaskCompletion(String token, Task task) async {
    final updated = task.copyWith(completed: !task.completed);
    await updateTask(token, updated);
  }

  Future<bool> deleteTask(String token, String taskId) async {
    final original = List<Task>.from(_tasks);
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();

    try {
      await _taskService.deleteTask(token: token, taskId: taskId);
      await _storageService?.saveTasks(_tasks);
      return true;
    } catch (_) {
      _tasks = original;
      _errorMessage = 'Unable to delete task. Try again.';
      notifyListeners();
      return false;
    }
  }
}
