import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_provider_starter/models/iot_reading.dart';

void main() {
  group('IoTReading Model Unit Tests', () {
    test('Parses valid complete ThingSpeak JSON correctly', () {
      final json = {
        'created_at': '2026-09-29T17:36:23Z',
        'entry_id': 2,
        'field1': '28.4',
        'field2': '72',
        'field3': '43',
        'field4': '650',
      };

      final reading = IoTReading.fromJson(json);

      expect(reading.entryId, 2);
      expect(reading.createdAt, DateTime.parse('2026-09-29T17:36:23Z'));
      expect(reading.temperature, 28.4);
      expect(reading.humidity, 72.0);
      expect(reading.airQuality, 43.0);
      expect(reading.lightIntensity, 650.0);
    });

    test('Safely handles null and missing fields without crashing', () {
      final json = <String, dynamic>{
        'created_at': '2026-09-29T17:00:00Z',
        'entry_id': 10,
      };

      final reading = IoTReading.fromJson(json);

      expect(reading.entryId, 10);
      expect(reading.temperature, isNull);
      expect(reading.humidity, isNull);
      expect(reading.airQuality, isNull);
      expect(reading.lightIntensity, isNull);
    });

    test('Safely handles invalid numeric strings (abc, NaN, null string)', () {
      final json = {
        'created_at': '2026-09-29T17:00:00Z',
        'entry_id': 'invalid_id',
        'field1': 'invalid_temp',
        'field2': 'NaN',
        'field3': 'null',
        'field4': '',
      };

      final reading = IoTReading.fromJson(json);

      expect(reading.entryId, 0); // Safe fallback to 0
      expect(reading.temperature, isNull);
      expect(reading.humidity, isNull);
      expect(reading.airQuality, isNull);
      expect(reading.lightIntensity, isNull);
    });

    test('Safely handles missing or empty map', () {
      final json = <String, dynamic>{};

      final reading = IoTReading.fromJson(json);

      expect(reading.entryId, 0);
      expect(reading.createdAt, isNotNull);
      expect(reading.temperature, isNull);
    });

    test('Correctly serializes to JSON map', () {
      final date = DateTime.utc(2026, 9, 29, 12, 0, 0);
      final reading = IoTReading(
        createdAt: date,
        entryId: 42,
        temperature: 24.5,
        humidity: 60.0,
        airQuality: 35.0,
        lightIntensity: 500.0,
      );

      final json = reading.toJson();

      expect(json['entry_id'], 42);
      expect(json['created_at'], date.toIso8601String());
      expect(json['field1'], '24.5');
      expect(json['field2'], '60.0');
      expect(json['field3'], '35.0');
      expect(json['field4'], '500.0');
    });

    test('copyWith updates specified fields and preserves others', () {
      final date = DateTime.utc(2026, 9, 29, 12, 0, 0);
      final initial = IoTReading(
        createdAt: date,
        entryId: 1,
        temperature: 20.0,
        humidity: 50.0,
      );

      final updated = initial.copyWith(
        temperature: 25.5,
        airQuality: 40.0,
      );

      expect(updated.entryId, 1);
      expect(updated.createdAt, date);
      expect(updated.temperature, 25.5);
      expect(updated.humidity, 50.0);
      expect(updated.airQuality, 40.0);
      expect(updated.lightIntensity, isNull);
    });

    test('Equality and toString behave predictably', () {
      final date = DateTime.utc(2026, 9, 29, 12, 0, 0);
      final r1 = IoTReading(createdAt: date, entryId: 1, temperature: 25.0);
      final r2 = IoTReading(createdAt: date, entryId: 1, temperature: 25.0);
      final r3 = IoTReading(createdAt: date, entryId: 2, temperature: 25.0);

      expect(r1, equals(r2));
      expect(r1.hashCode, equals(r2.hashCode));
      expect(r1, isNot(equals(r3)));
      expect(r1.toString(), contains('25.0°C'));
    });

    group('Status Threshold Evaluation Tests', () {
      test('Light Intensity thresholds match exact specifications', () {
        // < 100 -> Low
        expect(IoTReading.getLightStatus(99.0), 'Low');
        expect(IoTReading.getLightStatus(0.0), 'Low');

        // 100–500 -> Adequate
        expect(IoTReading.getLightStatus(100.0), 'Adequate');
        expect(IoTReading.getLightStatus(300.0), 'Adequate');
        expect(IoTReading.getLightStatus(500.0), 'Adequate');

        // > 500 -> Bright
        expect(IoTReading.getLightStatus(501.0), 'Bright');
        expect(IoTReading.getLightStatus(650.0), 'Bright');
        expect(IoTReading.getLightStatus(1200.0), 'Bright');

        // null -> No reading
        expect(IoTReading.getLightStatus(null), 'No reading');
      });

      test('Temperature boundary behavior matches specifications', () {
        // < 18°C -> Cool
        expect(IoTReading.getTemperatureStatus(17.9), 'Cool');
        expect(IoTReading.getTemperatureStatus(-5.0), 'Cool');

        // 18–26°C -> Optimal
        expect(IoTReading.getTemperatureStatus(18.0), 'Optimal');
        expect(IoTReading.getTemperatureStatus(22.5), 'Optimal');
        expect(IoTReading.getTemperatureStatus(26.0), 'Optimal');

        // > 26°C -> Warm
        expect(IoTReading.getTemperatureStatus(26.1), 'Warm');
        expect(IoTReading.getTemperatureStatus(35.0), 'Warm');

        // null -> No reading
        expect(IoTReading.getTemperatureStatus(null), 'No reading');
      });

      test('Humidity boundary behavior matches specifications', () {
        // < 30% -> Dry
        expect(IoTReading.getHumidityStatus(29.9), 'Dry');
        expect(IoTReading.getHumidityStatus(10.0), 'Dry');

        // 30–60% -> Comfortable
        expect(IoTReading.getHumidityStatus(30.0), 'Comfortable');
        expect(IoTReading.getHumidityStatus(45.0), 'Comfortable');
        expect(IoTReading.getHumidityStatus(60.0), 'Comfortable');

        // > 60% -> Humid
        expect(IoTReading.getHumidityStatus(60.1), 'Humid');
        expect(IoTReading.getHumidityStatus(85.0), 'Humid');

        // null -> No reading
        expect(IoTReading.getHumidityStatus(null), 'No reading');
      });

      test('Air Quality boundary behavior matches specifications', () {
        // <= 50 -> Good
        expect(IoTReading.getAirQualityStatus(0.0), 'Good');
        expect(IoTReading.getAirQualityStatus(50.0), 'Good');

        // 51–100 -> Moderate
        expect(IoTReading.getAirQualityStatus(50.1), 'Moderate');
        expect(IoTReading.getAirQualityStatus(51.0), 'Moderate');
        expect(IoTReading.getAirQualityStatus(100.0), 'Moderate');

        // > 100 -> Poor
        expect(IoTReading.getAirQualityStatus(100.1), 'Poor');
        expect(IoTReading.getAirQualityStatus(200.0), 'Poor');

        // null -> No reading
        expect(IoTReading.getAirQualityStatus(null), 'No reading');
      });

      test('Model getters return identical status to static methods', () {
        final r = IoTReading(
          createdAt: DateTime.now(),
          entryId: 1,
          temperature: 24.0,
          humidity: 55.0,
          airQuality: 40.0,
          lightIntensity: 650.0,
        );

        expect(r.temperatureStatus, 'Optimal');
        expect(r.humidityStatus, 'Comfortable');
        expect(r.airQualityStatus, 'Good');
        expect(r.lightStatus, 'Bright');
      });
    });

    group('Timestamp & Timezone Handling Tests', () {
      test('Parses ThingSpeak UTC timestamp and supports conversion to local time', () {
        final json = {
          'created_at': '2026-09-29T17:36:23Z',
          'entry_id': 1,
        };

        final reading = IoTReading.fromJson(json);

        // Internal timestamp is preserved as UTC
        expect(reading.createdAt.isUtc, isTrue);
        expect(reading.createdAt.year, 2026);
        expect(reading.createdAt.month, 9);
        expect(reading.createdAt.day, 29);
        expect(reading.createdAt.hour, 17);
        expect(reading.createdAt.minute, 36);
        expect(reading.createdAt.second, 23);

        // toLocal() converts to device local time without mutating the stored timestamp
        final local = reading.createdAt.toLocal();
        expect(local.isUtc, isFalse);
        expect(local.millisecondsSinceEpoch, reading.createdAt.millisecondsSinceEpoch);
        expect(reading.createdAt.isUtc, isTrue);
      });
    });
  });
}
