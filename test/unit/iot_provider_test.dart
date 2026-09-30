import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_provider_starter/models/iot_reading.dart';
import 'package:flutter_provider_starter/providers/iot_provider.dart';
import 'package:flutter_provider_starter/services/thingspeak_service.dart';

class FakeThingSpeakService extends ThingSpeakService {
  IoTReading? readingToReturn;
  List<IoTReading>? historyToReturn;
  bool shouldThrow = false;
  String errorMessage = 'Failed to fetch';
  int fetchCallCount = 0;

  @override
  Future<IoTReading> fetchLatestReading() async {
    fetchCallCount++;
    if (shouldThrow) {
      throw ThingSpeakException(errorMessage);
    }
    return readingToReturn ??
        IoTReading(
          createdAt: DateTime.now(),
          entryId: 1,
          temperature: 24.0,
          humidity: 55.0,
          airQuality: 40.0,
          lightIntensity: 600.0,
        );
  }

  @override
  Future<List<IoTReading>> fetchRecentReadings({int results = 20}) async {
    if (shouldThrow) {
      throw ThingSpeakException(errorMessage);
    }
    return historyToReturn ??
        [
          readingToReturn ??
              IoTReading(
                createdAt: DateTime.now(),
                entryId: 1,
                temperature: 24.0,
                humidity: 55.0,
                airQuality: 40.0,
                lightIntensity: 600.0,
              ),
        ];
  }
}

void main() {
  group('IoTProvider Unit Tests', () {
    late FakeThingSpeakService fakeService;
    late IoTProvider provider;

    setUp(() {
      fakeService = FakeThingSpeakService();
      provider = IoTProvider(fakeService);
    });

    test('Initial state is correct and has no data', () {
      expect(provider.latestReading, isNull);
      expect(provider.recentReadings, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.lastUpdated, isNull);
      expect(provider.hasData, isFalse);
    });

    test('fetchLatestReading successfully sets reading and updates lastUpdated', () async {
      final sample = IoTReading(
        createdAt: DateTime.utc(2026, 9, 29, 12, 0, 0),
        entryId: 99,
        temperature: 28.5,
        humidity: 62.0,
        airQuality: 45.0,
        lightIntensity: 700.0,
      );
      fakeService.readingToReturn = sample;
      fakeService.historyToReturn = [sample];

      await provider.fetchLatestReading();

      expect(provider.isLoading, isFalse);
      expect(provider.hasData, isTrue);
      expect(provider.latestReading?.entryId, 99);
      expect(provider.latestReading?.temperature, 28.5);
      expect(provider.recentReadings.length, 1);
      expect(provider.lastUpdated, isNotNull);
      expect(provider.errorMessage, isNull);
    });

    test('fetchLatestReading handles service exception gracefully', () async {
      fakeService.shouldThrow = true;
      fakeService.errorMessage = 'Network connection lost';

      await provider.fetchLatestReading();

      expect(provider.isLoading, isFalse);
      expect(provider.hasData, isFalse);
      expect(provider.errorMessage, 'Network connection lost');
    });

    test('clearError resets error state and notifies listeners', () async {
      fakeService.shouldThrow = true;
      fakeService.errorMessage = 'Temporary failure';

      await provider.fetchLatestReading();
      expect(provider.errorMessage, isNotNull);

      provider.clearError();
      expect(provider.errorMessage, isNull);
    });

    test('Prevents duplicate concurrent requests when already loading', () async {
      // Trigger two calls without awaiting first
      final f1 = provider.fetchLatestReading();
      final f2 = provider.fetchLatestReading();

      await Future.wait([f1, f2]);

      // Only one request should have hit the service
      expect(fakeService.fetchCallCount, 1);
    });

    test('Sorts historical readings chronologically from oldest to newest', () async {
      final earlier = IoTReading(
        createdAt: DateTime.utc(2026, 9, 29, 10, 0, 0),
        entryId: 1,
        temperature: 20.0,
      );
      final later = IoTReading(
        createdAt: DateTime.utc(2026, 9, 29, 11, 0, 0),
        entryId: 2,
        temperature: 24.0,
      );

      // Pass in reverse order
      fakeService.readingToReturn = later;
      fakeService.historyToReturn = [later, earlier];

      await provider.fetchLatestReading();

      expect(provider.recentReadings.length, 2);
      expect(provider.recentReadings[0].entryId, 1); // Earliest first
      expect(provider.recentReadings[1].entryId, 2); // Latest second
    });
  });
}
