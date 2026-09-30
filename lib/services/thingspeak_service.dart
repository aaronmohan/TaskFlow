import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/thingspeak_config.dart';
import '../models/iot_reading.dart';

/// Custom exception for ThingSpeak API operations.
/// Explicitly omits sensitive credentials from error messages.
class ThingSpeakException implements Exception {
  final String message;
  final int? statusCode;

  const ThingSpeakException(this.message, [this.statusCode]);

  @override
  String toString() => 'ThingSpeakException: $message';
}

/// Service layer responsible for all communication with the ThingSpeak REST API.
class ThingSpeakService {
  final String baseUrl;
  final String channelId;
  final String readApiKey;
  final http.Client _client;

  ThingSpeakService({
    String? baseUrl,
    String? channelId,
    String? readApiKey,
    http.Client? client,
  })  : baseUrl = baseUrl ?? ThingSpeakConfig.baseUrl,
        channelId = channelId ?? ThingSpeakConfig.channelId,
        readApiKey = readApiKey ?? ThingSpeakConfig.readApiKey,
        _client = client ?? http.Client();

  /// Default headers sent with requests.
  /// Passes the Read API Key via the THINGSPEAKAPIKEY header if provided.
  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (readApiKey.isNotEmpty) {
      headers['THINGSPEAKAPIKEY'] = readApiKey;
    }
    return headers;
  }

  /// Fetches the single latest entry from the private ThingSpeak channel.
  /// Endpoint: GET /channels/{channelId}/feeds/last.json
  Future<IoTReading> fetchLatestReading() async {
    final uri = Uri.parse('$baseUrl/channels/$channelId/feeds/last.json');

    try {
      final response = await _client
          .get(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 10));

      return _parseLatestResponse(response);
    } on SocketException {
      throw const ThingSpeakException(
        'Network error. Please check your internet connection.',
      );
    } on http.ClientException {
      throw const ThingSpeakException(
        'Unable to connect to ThingSpeak server.',
      );
    } on TimeoutException {
      throw const ThingSpeakException(
        'Connection to ThingSpeak timed out. Please try again.',
      );
    } on FormatException {
      throw const ThingSpeakException(
        'Received invalid response format from ThingSpeak.',
      );
    }
  }

  /// Fetches the most recent historical entries from the private ThingSpeak channel.
  /// Endpoint: GET /channels/{channelId}/feeds.json?results={results}
  Future<List<IoTReading>> fetchRecentReadings({int results = 20}) async {
    final uri = Uri.parse('$baseUrl/channels/$channelId/feeds.json?results=$results');

    try {
      final response = await _client
          .get(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 10));

      return _parseFeedsResponse(response);
    } on SocketException {
      throw const ThingSpeakException(
        'Network error. Please check your internet connection.',
      );
    } on http.ClientException {
      throw const ThingSpeakException(
        'Unable to connect to ThingSpeak server.',
      );
    } on TimeoutException {
      throw const ThingSpeakException(
        'Connection to ThingSpeak timed out. Please try again.',
      );
    } on FormatException {
      throw const ThingSpeakException(
        'Received invalid response format from ThingSpeak.',
      );
    }
  }

  /// Parses and validates the HTTP response for the latest reading.
  IoTReading _parseLatestResponse(http.Response response) {
    _validateStatusCode(response.statusCode, response.body);

    final trimmedBody = response.body.trim();

    // ThingSpeak returns "-1" or "0" if authentication fails or channel is empty
    if (trimmedBody == '-1') {
      throw const ThingSpeakException(
        'Unauthorized access to private channel. Please verify your Read API Key.',
        401,
      );
    }

    if (trimmedBody == '0' || trimmedBody.isEmpty || trimmedBody == '{}') {
      throw const ThingSpeakException(
        'No sensor data available in this channel feed.',
        204,
      );
    }

    final dynamic decoded = jsonDecode(trimmedBody);
    if (decoded is! Map<String, dynamic>) {
      throw const ThingSpeakException('Invalid JSON data received from sensor.');
    }

    // Check if feed contains required identifiers
    if (!decoded.containsKey('created_at') && !decoded.containsKey('entry_id')) {
      throw const ThingSpeakException(
        'Missing required feed information in ThingSpeak response.',
      );
    }

    return IoTReading.fromJson(decoded);
  }

  /// Parses and validates the HTTP response for historical feeds.
  List<IoTReading> _parseFeedsResponse(http.Response response) {
    _validateStatusCode(response.statusCode, response.body);

    final trimmedBody = response.body.trim();

    if (trimmedBody == '-1') {
      throw const ThingSpeakException(
        'Unauthorized access to private channel. Please verify your Read API Key.',
        401,
      );
    }

    final dynamic decoded = jsonDecode(trimmedBody);
    if (decoded is! Map<String, dynamic>) {
      throw const ThingSpeakException('Invalid JSON data received from sensor feed.');
    }

    final feeds = decoded['feeds'];
    if (feeds == null || feeds is! List) {
      return [];
    }

    final readings = <IoTReading>[];
    for (final item in feeds) {
      if (item is Map<String, dynamic>) {
        readings.add(IoTReading.fromJson(item));
      } else if (item is Map) {
        readings.add(IoTReading.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    return readings;
  }

  /// Validates standard HTTP status codes with user-friendly errors.
  void _validateStatusCode(int statusCode, String body) {
    if (statusCode == 200 || statusCode == 201) {
      return;
    }

    if (statusCode == 401 || statusCode == 403) {
      throw ThingSpeakException(
        'Unauthorized access to private channel. Please check your Read API Key.',
        statusCode,
      );
    }

    if (statusCode == 404) {
      throw ThingSpeakException(
        'ThingSpeak channel not found. Please verify Channel ID $channelId.',
        statusCode,
      );
    }

    if (statusCode == 429) {
      throw ThingSpeakException(
        'ThingSpeak rate limit exceeded. Please wait 15 seconds before retrying.',
        statusCode,
      );
    }

    if (statusCode >= 500) {
      throw ThingSpeakException(
        'ThingSpeak server error ($statusCode). Please try again later.',
        statusCode,
      );
    }

    throw ThingSpeakException(
      'Unexpected response from sensor server (status $statusCode).',
      statusCode,
    );
  }
}
