/// Configuration for ThingSpeak IoT service.
/// Uses compile-time environment variables configured via `--dart-define`.
class ThingSpeakConfig {
  /// ThingSpeak Channel ID (default: 3515139)
  static const String channelId = String.fromEnvironment(
    'THINGSPEAK_CHANNEL_ID',
    defaultValue: '3515139',
  );

  /// ThingSpeak Read API Key (passed via --dart-define=THINGSPEAK_READ_API_KEY=...)
  /// Never hardcode or commit secret keys to source control.
  static const String readApiKey = String.fromEnvironment(
    'THINGSPEAK_READ_API_KEY',
    defaultValue: '',
  );

  /// Base ThingSpeak REST API endpoint
  static const String baseUrl = 'https://api.thingspeak.com';

  /// Endpoint to fetch the latest feed entry for the configured channel
  static Uri get latestFeedUri =>
      Uri.parse('$baseUrl/channels/$channelId/feeds/last.json');

  /// Endpoint to fetch recent historical feed entries for the configured channel
  static Uri recentFeedsUri({int results = 20}) =>
      Uri.parse('$baseUrl/channels/$channelId/feeds.json?results=$results');
}
