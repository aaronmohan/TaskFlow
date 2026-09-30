import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_provider_starter/services/thingspeak_service.dart';

class MockHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request) handler;
  http.BaseRequest? lastRequest;

  MockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request;
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
    );
  }
}

void main() {
  group('ThingSpeakService Unit Tests', () {
    const testChannelId = '3515139';
    const testApiKey = 'SECRET_READ_KEY';

    test('fetchLatestReading parses valid 200 response and passes THINGSPEAKAPIKEY header', () async {
      late http.BaseRequest capturedRequest;

      final mockClient = MockHttpClient((req) async {
        capturedRequest = req;
        return http.Response(
          jsonEncode({
            'created_at': '2026-09-29T18:00:00Z',
            'entry_id': 105,
            'field1': '26.8',
            'field2': '65.2',
            'field3': '48',
            'field4': '720',
          }),
          200,
        );
      });

      final service = ThingSpeakService(
        channelId: testChannelId,
        readApiKey: testApiKey,
        client: mockClient,
      );

      final reading = await service.fetchLatestReading();

      expect(reading.entryId, 105);
      expect(reading.temperature, 26.8);
      expect(reading.humidity, 65.2);
      expect(reading.airQuality, 48.0);
      expect(reading.lightIntensity, 720.0);

      // Verify URL and headers
      expect(capturedRequest.url.path, contains('/channels/3515139/feeds/last.json'));
      expect(capturedRequest.headers['THINGSPEAKAPIKEY'], testApiKey);
      expect(capturedRequest.headers['Accept'], 'application/json');
    });

    test('fetchRecentReadings parses feeds array', () async {
      final mockClient = MockHttpClient((req) async {
        return http.Response(
          jsonEncode({
            'channel': {'id': 3515139, 'name': 'Environment'},
            'feeds': [
              {
                'created_at': '2026-09-29T17:50:00Z',
                'entry_id': 101,
                'field1': '25.0',
                'field2': '60.0',
              },
              {
                'created_at': '2026-09-29T17:55:00Z',
                'entry_id': 102,
                'field1': '25.5',
                'field2': '62.0',
              },
            ],
          }),
          200,
        );
      });

      final service = ThingSpeakService(
        channelId: testChannelId,
        readApiKey: testApiKey,
        client: mockClient,
      );

      final feeds = await service.fetchRecentReadings(results: 2);

      expect(feeds.length, 2);
      expect(feeds[0].entryId, 101);
      expect(feeds[0].temperature, 25.0);
      expect(feeds[1].entryId, 102);
      expect(feeds[1].temperature, 25.5);
    });

    test('Throws ThingSpeakException on 401/403 without leaking API key', () async {
      final mockClient = MockHttpClient((req) async {
        return http.Response('Unauthorized', 403);
      });

      final service = ThingSpeakService(
        channelId: testChannelId,
        readApiKey: testApiKey,
        client: mockClient,
      );

      expect(
        () => service.fetchLatestReading(),
        throwsA(
          isA<ThingSpeakException>()
              .having((e) => e.message, 'message', contains('Unauthorized access'))
              .having((e) => e.toString(), 'string', isNot(contains(testApiKey))),
        ),
      );
    });

    test('Throws ThingSpeakException on "-1" response body (ThingSpeak auth failure code)', () async {
      final mockClient = MockHttpClient((req) async {
        return http.Response('-1', 200);
      });

      final service = ThingSpeakService(
        channelId: testChannelId,
        readApiKey: testApiKey,
        client: mockClient,
      );

      expect(
        () => service.fetchLatestReading(),
        throwsA(
          isA<ThingSpeakException>()
              .having((e) => e.message, 'message', contains('Unauthorized access')),
        ),
      );
    });

    test('Throws ThingSpeakException on 404 channel not found', () async {
      final mockClient = MockHttpClient((req) async {
        return http.Response('Not Found', 404);
      });

      final service = ThingSpeakService(
        channelId: testChannelId,
        client: mockClient,
      );

      expect(
        () => service.fetchLatestReading(),
        throwsA(
          isA<ThingSpeakException>()
              .having((e) => e.message, 'message', contains('channel not found')),
        ),
      );
    });

    test('Throws ThingSpeakException on 429 rate limit exceeded', () async {
      final mockClient = MockHttpClient((req) async {
        return http.Response('Rate limit exceeded', 429);
      });

      final service = ThingSpeakService(
        channelId: testChannelId,
        client: mockClient,
      );

      expect(
        () => service.fetchLatestReading(),
        throwsA(
          isA<ThingSpeakException>()
              .having((e) => e.message, 'message', contains('rate limit exceeded')),
        ),
      );
    });

    test('Throws ThingSpeakException on 500 server error', () async {
      final mockClient = MockHttpClient((req) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = ThingSpeakService(
        channelId: testChannelId,
        client: mockClient,
      );

      expect(
        () => service.fetchLatestReading(),
        throwsA(
          isA<ThingSpeakException>()
              .having((e) => e.message, 'message', contains('server error')),
        ),
      );
    });

    test('Throws ThingSpeakException on network failure (SocketException)', () async {
      final mockClient = MockHttpClient((req) async {
        throw const SocketException('No Internet');
      });

      final service = ThingSpeakService(
        channelId: testChannelId,
        client: mockClient,
      );

      expect(
        () => service.fetchLatestReading(),
        throwsA(
          isA<ThingSpeakException>()
              .having((e) => e.message, 'message', contains('Network error')),
        ),
      );
    });
  });
}
