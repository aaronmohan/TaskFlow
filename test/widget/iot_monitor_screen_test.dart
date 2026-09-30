import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_provider_starter/models/iot_reading.dart';
import 'package:flutter_provider_starter/providers/iot_provider.dart';
import 'package:flutter_provider_starter/screens/iot_monitor_screen.dart';
import 'package:flutter_provider_starter/services/thingspeak_service.dart';

class FakeWidgetThingSpeakService extends ThingSpeakService {
  IoTReading? readingToReturn;
  List<IoTReading>? historyToReturn;
  bool shouldThrow = false;
  String errorMsg = 'Unable to connect';
  int fetchCount = 0;

  @override
  Future<IoTReading> fetchLatestReading() async {
    fetchCount++;
    if (shouldThrow) {
      throw ThingSpeakException(errorMsg);
    }
    return readingToReturn ??
        IoTReading(
          createdAt: DateTime.utc(2026, 9, 29, 18, 0, 0),
          entryId: 10,
          temperature: 28.4,
          humidity: 72.0,
          airQuality: 43.0,
          lightIntensity: 650.0,
        );
  }

  @override
  Future<List<IoTReading>> fetchRecentReadings({int results = 20}) async {
    if (shouldThrow) {
      throw ThingSpeakException(errorMsg);
    }
    return historyToReturn ??
        [
          readingToReturn ??
              IoTReading(
                createdAt: DateTime.utc(2026, 9, 29, 18, 0, 0),
                entryId: 10,
                temperature: 28.4,
                humidity: 72.0,
                airQuality: 43.0,
                lightIntensity: 650.0,
              ),
        ];
  }
}

void main() {
  Widget buildTestScreen(IoTProvider provider) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<IoTProvider>.value(value: provider),
      ],
      child: const MaterialApp(
        home: IoTMonitorScreen(),
      ),
    );
  }

  testWidgets('IoTMonitorScreen renders sensor cards and data successfully',
      (WidgetTester tester) async {
    final fakeService = FakeWidgetThingSpeakService();
    final sample = IoTReading(
      createdAt: DateTime.utc(2026, 9, 29, 17, 36, 23),
      entryId: 2,
      temperature: 28.4,
      humidity: 72.0,
      airQuality: 43.0,
      lightIntensity: 650.0,
    );
    fakeService.readingToReturn = sample;
    fakeService.historyToReturn = [sample];

    final provider = IoTProvider(fakeService);
    // Pre-fetch reading so screen renders with data immediately
    await provider.fetchLatestReading();

    await tester.pumpWidget(buildTestScreen(provider));
    await tester.pumpAndSettle();

    // Verify Title & Subtitle
    expect(find.text('IoT Monitor'), findsWidgets);
    expect(find.text('Live sensor data from ThingSpeak'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);

    // Verify Sensor Cards
    expect(find.text('Temperature'), findsOneWidget);
    expect(find.text('28.4 °C'), findsWidgets);

    expect(find.text('Humidity'), findsWidgets);
    expect(find.text('72.0 %'), findsOneWidget);

    expect(find.text('Air Quality'), findsOneWidget);
    expect(find.text('43'), findsOneWidget);

    expect(find.text('Light Intensity'), findsOneWidget);
    expect(find.text('650 lux'), findsOneWidget);

    // Verify Sensor Status Captions (including 650 lux -> Bright)
    expect(find.text('Warm'), findsOneWidget);
    expect(find.text('Humid'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
    expect(find.text('Bright'), findsOneWidget);

    // Verify Historical Trends section
    expect(find.text('Historical Trends'), findsOneWidget);
    expect(find.text('Temperature History'), findsOneWidget);
  });

  testWidgets('IoTMonitorScreen renders error state and triggers retry',
      (WidgetTester tester) async {
    final fakeService = FakeWidgetThingSpeakService();
    fakeService.shouldThrow = true;
    fakeService.errorMsg = 'ThingSpeak server unreachable.';

    final provider = IoTProvider(fakeService);

    await tester.pumpWidget(buildTestScreen(provider));
    await tester.pumpAndSettle();

    // Verify Error State
    expect(find.text('Unable to load sensor data.'), findsOneWidget);
    expect(find.text('ThingSpeak server unreachable.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    // Tap retry after fixing the fake service
    fakeService.shouldThrow = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    // Should now show sensor cards
    expect(find.text('28.4 °C'), findsWidgets);
  });
}
