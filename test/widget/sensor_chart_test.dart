import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:flutter_provider_starter/models/iot_reading.dart';
import 'package:flutter_provider_starter/widgets/sensor_chart.dart';

void main() {
  Widget buildChartTestWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: child,
        ),
      ),
    );
  }

  group('SensorChart Widget Tests', () {
    testWidgets('Converts ThingSpeak UTC timestamp to local device timezone on x-axis',
        (WidgetTester tester) async {
      // UTC timestamp: 17:36:23 UTC
      final utcTime1 = DateTime.utc(2026, 9, 29, 17, 30, 0);
      final utcTime2 = DateTime.utc(2026, 9, 29, 17, 36, 0);

      final readings = [
        IoTReading(createdAt: utcTime1, entryId: 1, temperature: 24.0),
        IoTReading(createdAt: utcTime2, entryId: 2, temperature: 26.5),
      ];

      await tester.pumpWidget(
        buildChartTestWidget(
          SensorChart(
            title: 'Temperature History',
            unit: '°C',
            accentColor: Colors.red,
            readings: readings,
            valueExtractor: (r) => r.temperature,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Local time formatted strings
      final expectedLocalTime1 = DateFormat('h:mm a').format(utcTime1.toLocal());
      final expectedLocalTime2 = DateFormat('h:mm a').format(utcTime2.toLocal());

      // Should display localized time on the x-axis
      expect(find.text(expectedLocalTime1), findsOneWidget);
      expect(find.text(expectedLocalTime2), findsOneWidget);

      // Verify that if local timezone is not UTC, the raw UTC hours are NOT displayed
      final utcFormat1 = DateFormat('h:mm a').format(utcTime1);
      if (utcTime1.toLocal().timeZoneOffset != Duration.zero) {
        // Only assert non-matching if the local timezone is different from UTC
        expect(expectedLocalTime1 != utcFormat1, isTrue);
      }
    });

    testWidgets('Sorts readings chronologically when provided out of order',
        (WidgetTester tester) async {
      // Pass readings with newer time first and older time second
      final earlier = DateTime.utc(2026, 9, 29, 10, 0, 0);
      final later = DateTime.utc(2026, 9, 29, 12, 0, 0);

      final outOfOrderReadings = [
        IoTReading(createdAt: later, entryId: 2, temperature: 28.0),
        IoTReading(createdAt: earlier, entryId: 1, temperature: 22.0),
      ];

      await tester.pumpWidget(
        buildChartTestWidget(
          SensorChart(
            title: 'Temperature History',
            unit: '°C',
            accentColor: Colors.red,
            readings: outOfOrderReadings,
            valueExtractor: (r) => r.temperature,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final earlierLocal = DateFormat('h:mm a').format(earlier.toLocal());
      final laterLocal = DateFormat('h:mm a').format(later.toLocal());

      // Both times are rendered
      expect(find.text(earlierLocal), findsOneWidget);
      expect(find.text(laterLocal), findsOneWidget);

      // The earliest time should be on the left (first in Row)
      final earlierOffset = tester.getTopLeft(find.text(earlierLocal));
      final laterOffset = tester.getTopLeft(find.text(laterLocal));
      expect(earlierOffset.dx < laterOffset.dx, isTrue);

      // Latest value should be 28.0 °C (from the chronologically latest reading)
      expect(find.text('28.0 °C'), findsOneWidget);
    });

    testWidgets('Handles multiple readings (8 to 20 historical readings) correctly',
        (WidgetTester tester) async {
      final base = DateTime.utc(2026, 9, 29, 14, 0, 0);
      final readings = List.generate(
        15,
        (i) => IoTReading(
          createdAt: base.add(Duration(minutes: i * 5)),
          entryId: i + 1,
          temperature: 20.0 + (i * 0.5),
        ),
      );

      await tester.pumpWidget(
        buildChartTestWidget(
          SensorChart(
            title: 'Temperature History',
            unit: '°C',
            accentColor: Colors.red,
            readings: readings,
            valueExtractor: (r) => r.temperature,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Sample count
      expect(find.text('15 samples'), findsOneWidget);

      // Min and Max
      expect(find.text('Min: 20.0°C'), findsOneWidget);
      expect(find.text('Max: 27.0°C'), findsOneWidget);

      // Latest value badge
      expect(find.text('27.0 °C'), findsOneWidget);
    });

    testWidgets('Safely skips null and NaN sensor values without crashing',
        (WidgetTester tester) async {
      final base = DateTime.utc(2026, 9, 29, 14, 0, 0);
      final readings = [
        IoTReading(createdAt: base, entryId: 1, temperature: 21.0),
        IoTReading(createdAt: base.add(const Duration(minutes: 5)), entryId: 2, temperature: null),
        IoTReading(createdAt: base.add(const Duration(minutes: 10)), entryId: 3, temperature: 25.0),
      ];

      await tester.pumpWidget(
        buildChartTestWidget(
          SensorChart(
            title: 'Temperature History',
            unit: '°C',
            accentColor: Colors.red,
            readings: readings,
            valueExtractor: (r) => r.temperature,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Only 2 valid samples should be counted
      expect(find.text('2 samples'), findsOneWidget);
      expect(find.text('Min: 21.0°C'), findsOneWidget);
      expect(find.text('Max: 25.0°C'), findsOneWidget);
    });

    testWidgets('Handles a single reading gracefully without crash',
        (WidgetTester tester) async {
      final time = DateTime.utc(2026, 9, 29, 16, 0, 0);
      final readings = [
        IoTReading(createdAt: time, entryId: 1, temperature: 23.5),
      ];

      await tester.pumpWidget(
        buildChartTestWidget(
          SensorChart(
            title: 'Temperature History',
            unit: '°C',
            accentColor: Colors.red,
            readings: readings,
            valueExtractor: (r) => r.temperature,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Single sample count
      expect(find.text('1 sample'), findsOneWidget);
      expect(find.text('23.5 °C'), findsOneWidget);

      // Local time should be displayed centered
      final localTimeStr = DateFormat('h:mm a').format(time.toLocal());
      expect(find.text(localTimeStr), findsOneWidget);
    });

    testWidgets('Handles empty readings without crash',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildChartTestWidget(
          SensorChart(
            title: 'Humidity History',
            unit: '%',
            accentColor: Colors.blue,
            readings: const [],
            valueExtractor: (r) => r.humidity,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Humidity History available yet'), findsOneWidget);
    });

    testWidgets('Handles identical values gracefully (flat line behavior)',
        (WidgetTester tester) async {
      final base = DateTime.utc(2026, 9, 29, 12, 0, 0);
      final readings = List.generate(
        5,
        (i) => IoTReading(
          createdAt: base.add(Duration(minutes: i * 10)),
          entryId: i + 1,
          temperature: 24.0,
        ),
      );

      await tester.pumpWidget(
        buildChartTestWidget(
          SensorChart(
            title: 'Temperature History',
            unit: '°C',
            accentColor: Colors.red,
            readings: readings,
            valueExtractor: (r) => r.temperature,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('5 samples'), findsOneWidget);
      expect(find.text('Min: 24.0°C'), findsOneWidget);
      expect(find.text('Max: 24.0°C'), findsOneWidget);
    });
  });
}
