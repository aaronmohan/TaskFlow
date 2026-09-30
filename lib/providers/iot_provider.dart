import 'package:flutter/foundation.dart';
import '../models/iot_reading.dart';
import '../services/thingspeak_service.dart';

/// Provider for managing IoT sensor telemetry state from ThingSpeak.
class IoTProvider extends ChangeNotifier {
  final ThingSpeakService _service;

  IoTProvider(this._service);

  IoTReading? _latestReading;
  List<IoTReading> _recentReadings = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastUpdated;

  // --- Getters ---
  IoTReading? get latestReading => _latestReading;
  List<IoTReading> get recentReadings => List.unmodifiable(_recentReadings);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdated => _lastUpdated;
  bool get hasData => _latestReading != null;

  /// Fetches both the latest reading and recent historical entries.
  /// Prevents duplicate concurrent requests unless [force] is true.
  Future<void> fetchLatestReading({bool force = false}) async {
    if (_isLoading && !force) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch latest entry and recent historical entries
      final latest = await _service.fetchLatestReading();

      List<IoTReading> history = [];
      try {
        history = await _service.fetchRecentReadings(results: 20);
      } catch (_) {
        // If history fails, still keep latest reading
        history = _recentReadings.isNotEmpty ? _recentReadings : [latest];
      }

      _latestReading = latest;
      final sortedHistory = List<IoTReading>.from(history.isNotEmpty ? history : [latest])
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _recentReadings = sortedHistory;
      _lastUpdated = DateTime.now();
      _errorMessage = null;
    } on ThingSpeakException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Unable to load sensor data. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears any existing error message and notifies listeners.
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}
