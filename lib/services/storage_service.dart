import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/task.dart';

class StorageService {
  static const String _userKey = 'taskflow_user_session';
  static const String _themeKey = 'taskflow_dark_theme';
  static const String _tasksKey = 'taskflow_cached_tasks';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // --- User Session ---
  Future<void> saveUser(User user) async {
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  User? getUser() {
    final raw = _prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return User.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearUser() async {
    await _prefs.remove(_userKey);
  }

  // --- Theme ---
  bool isDarkMode() {
    return _prefs.getBool(_themeKey) ?? false;
  }

  Future<void> setDarkMode(bool isDark) async {
    await _prefs.setBool(_themeKey, isDark);
  }

  // --- Tasks Cache / Local Tasks ---
  List<Task>? getCachedTasks() {
    final raw = _prefs.getString(_tasksKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final tasks = <Task>[];
        for (final item in decoded) {
          if (item is Map) {
            tasks.add(Task.fromJson(Map<String, dynamic>.from(item)));
          }
        }
        return tasks.isNotEmpty ? tasks : null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> saveTasks(List<Task> tasks) async {
    try {
      final encoded = jsonEncode(tasks.map((t) => t.toJson()).toList());
      return await _prefs.setString(_tasksKey, encoded);
    } catch (_) {
      return false;
    }
  }
}
