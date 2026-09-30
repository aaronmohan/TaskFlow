/// Model representing a single IoT reading entry from a ThingSpeak channel feed.
///
/// Sensor Field Mapping:
/// - field1: Temperature (°C)
/// - field2: Humidity (%)
/// - field3: Air Quality (AQI / raw metric)
/// - field4: Light Intensity (Lux / raw metric)
class IoTReading {
  final DateTime createdAt;
  final int entryId;
  final double? temperature;
  final double? humidity;
  final double? airQuality;
  final double? lightIntensity;

  const IoTReading({
    required this.createdAt,
    required this.entryId,
    this.temperature,
    this.humidity,
    this.airQuality,
    this.lightIntensity,
  });

  /// Factory constructor to safely parse ThingSpeak feed JSON.
  /// Handles string numbers, nulls, missing fields, and non-numeric values safely.
  factory IoTReading.fromJson(Map<String, dynamic> json) {
    // 1. Safe DateTime parsing
    DateTime parsedDate;
    final rawDate = json['created_at'];
    if (rawDate != null && rawDate is String && rawDate.isNotEmpty) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    // 2. Safe Entry ID parsing (can be int or numeric string)
    int parsedEntryId = 0;
    final rawEntryId = json['entry_id'];
    if (rawEntryId is int) {
      parsedEntryId = rawEntryId;
    } else if (rawEntryId != null) {
      parsedEntryId = int.tryParse(rawEntryId.toString()) ?? 0;
    }

    // 3. Safe double parsing helper
    double? parseNumericField(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isEmpty ||
            trimmed.toLowerCase() == 'null' ||
            trimmed.toLowerCase() == 'nan') {
          return null;
        }
        return double.tryParse(trimmed);
      }
      return null;
    }

    return IoTReading(
      createdAt: parsedDate,
      entryId: parsedEntryId,
      temperature: parseNumericField(json['field1']),
      humidity: parseNumericField(json['field2']),
      airQuality: parseNumericField(json['field3']),
      lightIntensity: parseNumericField(json['field4']),
    );
  }

  /// Convert model instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'created_at': createdAt.toIso8601String(),
      'entry_id': entryId,
      'field1': temperature?.toString(),
      'field2': humidity?.toString(),
      'field3': airQuality?.toString(),
      'field4': lightIntensity?.toString(),
    };
  }

  /// Create a copy with optionally updated fields.
  IoTReading copyWith({
    DateTime? createdAt,
    int? entryId,
    double? temperature,
    double? humidity,
    double? airQuality,
    double? lightIntensity,
  }) {
    return IoTReading(
      createdAt: createdAt ?? this.createdAt,
      entryId: entryId ?? this.entryId,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      airQuality: airQuality ?? this.airQuality,
      lightIntensity: lightIntensity ?? this.lightIntensity,
    );
  }

  @override
  String toString() {
    return 'IoTReading(entryId: $entryId, createdAt: $createdAt, '
        'temperature: $temperature°C, humidity: $humidity%, '
        'airQuality: $airQuality, lightIntensity: $lightIntensity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IoTReading &&
        other.entryId == entryId &&
        other.createdAt == createdAt &&
        other.temperature == temperature &&
        other.humidity == humidity &&
        other.airQuality == airQuality &&
        other.lightIntensity == lightIntensity;
  }

  @override
  int get hashCode {
    return Object.hash(
      entryId,
      createdAt,
      temperature,
      humidity,
      airQuality,
      lightIntensity,
    );
  }

  // --- Status Evaluation Methods ---

  /// Temperature status:
  /// < 18°C       → Cool
  /// 18–26°C      → Optimal
  /// > 26°C       → Warm
  static String getTemperatureStatus(double? temp) {
    if (temp == null) return 'No reading';
    if (temp < 18.0) return 'Cool';
    if (temp <= 26.0) return 'Optimal';
    return 'Warm';
  }

  /// Humidity status:
  /// < 30%        → Dry
  /// 30–60%       → Comfortable
  /// > 60%        → Humid
  static String getHumidityStatus(double? humidity) {
    if (humidity == null) return 'No reading';
    if (humidity < 30.0) return 'Dry';
    if (humidity <= 60.0) return 'Comfortable';
    return 'Humid';
  }

  /// Air Quality status:
  /// ≤ 50         → Good
  /// 51–100       → Moderate
  /// > 100        → Poor
  static String getAirQualityStatus(double? aqi) {
    if (aqi == null) return 'No reading';
    if (aqi <= 50.0) return 'Good';
    if (aqi <= 100.0) return 'Moderate';
    return 'Poor';
  }

  /// Light Intensity status:
  /// < 100 lux    → Low
  /// 100–500 lux  → Adequate
  /// > 500 lux    → Bright
  static String getLightStatus(double? light) {
    if (light == null) return 'No reading';
    if (light < 100.0) return 'Low';
    if (light <= 500.0) return 'Adequate';
    return 'Bright';
  }

  String get temperatureStatus => getTemperatureStatus(temperature);
  String get humidityStatus => getHumidityStatus(humidity);
  String get airQualityStatus => getAirQualityStatus(airQuality);
  String get lightStatus => getLightStatus(lightIntensity);
}
