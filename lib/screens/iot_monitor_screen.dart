import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/thingspeak_config.dart';
import '../models/iot_reading.dart';
import '../providers/iot_provider.dart';
import '../widgets/sensor_chart.dart';

/// Screen displaying real-time IoT sensor telemetry from ThingSpeak.
/// Features live cards for Temperature, Humidity, Air Quality, and Light Intensity,
/// along with historical trend charts and responsive layouts.
class IoTMonitorScreen extends StatefulWidget {
  const IoTMonitorScreen({super.key});

  @override
  State<IoTMonitorScreen> createState() => _IoTMonitorScreenState();
}

class _IoTMonitorScreenState extends State<IoTMonitorScreen> {
  int _selectedChartMetric = 0; // 0: Temperature, 1: Humidity

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTelemetry();
    });
  }

  void _loadTelemetry() {
    final provider = Provider.of<IoTProvider?>(context, listen: false);
    if (provider != null && !provider.hasData && !provider.isLoading) {
      provider.fetchLatestReading();
    }
  }

  void _onRefresh() {
    final provider = Provider.of<IoTProvider?>(context, listen: false);
    provider?.fetchLatestReading(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iotProvider = Provider.of<IoTProvider?>(context, listen: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('IoT Monitor'),
        actions: [
          IconButton(
            tooltip: 'Refresh Telemetry',
            icon: iotProvider?.isLoading == true
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: iotProvider?.isLoading == true ? null : _onRefresh,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: _buildBody(context, iotProvider, theme, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    IoTProvider? provider,
    ThemeData theme,
    bool isDark,
  ) {
    if (provider == null) {
      return const Center(child: Text('IoT Provider not registered'));
    }

    // 1. Initial Loading State (when no previous data exists)
    if (provider.isLoading && !provider.hasData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                'Fetching live sensor telemetry...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Error State (when fetch failed and no data to show)
    if (provider.errorMessage != null && !provider.hasData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withAlpha(isDark ? 40 : 25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_outlined,
                  size: 48,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Unable to load sensor data.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                provider.errorMessage ?? 'Please check your connection and configuration.',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Empty State (no error, but reading is null)
    if (!provider.hasData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sensors_off_outlined,
                size: 56,
                color: theme.colorScheme.outlineVariant,
              ),
              const SizedBox(height: 16),
              const Text(
                'No sensor readings available',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Connect to ThingSpeak channel #${ThingSpeakConfig.channelId} to view telemetry.',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Fetch Data'),
              ),
            ],
          ),
        ),
      );
    }

    final reading = provider.latestReading!;
    final history = provider.recentReadings;

    // 4. Data Content
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final cardCols = isWide ? 4 : 2;

        return RefreshIndicator(
          onRefresh: () async => provider.fetchLatestReading(force: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Banner
                _buildHeaderCard(context, theme, isDark, provider, reading),
                const SizedBox(height: 20),

                // Error alert banner if refreshing failed while keeping stale data
                if (provider.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(isDark ? 40 : 25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade700),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            provider.errorMessage!,
                            style: TextStyle(
                              color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: provider.clearError,
                        ),
                      ],
                    ),
                  ),
                ],

                // Section Title: Live Readings
                Text(
                  'Current Telemetry',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Responsive Sensor Cards Grid
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cardCols,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    mainAxisExtent: 155,
                  ),
                  children: [
                    _SensorCard(
                      label: 'Temperature',
                      value: reading.temperature != null
                          ? '${reading.temperature!.toStringAsFixed(1)} °C'
                          : '-- °C',
                      icon: Icons.thermostat_outlined,
                      accentColor: const Color(0xFFEF4444),
                      caption: _getTemperatureStatus(reading.temperature),
                    ),
                    _SensorCard(
                      label: 'Humidity',
                      value: reading.humidity != null
                          ? '${reading.humidity!.toStringAsFixed(1)} %'
                          : '-- %',
                      icon: Icons.water_drop_outlined,
                      accentColor: const Color(0xFF3B82F6),
                      caption: _getHumidityStatus(reading.humidity),
                    ),
                    _SensorCard(
                      label: 'Air Quality',
                      value: reading.airQuality != null
                          ? reading.airQuality!.toStringAsFixed(0)
                          : '--',
                      icon: Icons.air_outlined,
                      accentColor: const Color(0xFF10B981),
                      caption: _getAirQualityStatus(reading.airQuality),
                    ),
                    _SensorCard(
                      label: 'Light Intensity',
                      value: reading.lightIntensity != null
                          ? '${reading.lightIntensity!.toStringAsFixed(0)} lux'
                          : '-- lux',
                      icon: Icons.wb_sunny_outlined,
                      accentColor: const Color(0xFFF59E0B),
                      caption: _getLightStatus(reading.lightIntensity),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Section Title: Historical Trends
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Historical Trends',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Temp')),
                        ButtonSegment(value: 1, label: Text('Humidity')),
                      ],
                      selected: {_selectedChartMetric},
                      onSelectionChanged: (set) {
                        setState(() {
                          _selectedChartMetric = set.first;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Chart View
                if (_selectedChartMetric == 0)
                  SensorChart(
                    title: 'Temperature History',
                    unit: '°C',
                    accentColor: const Color(0xFFEF4444),
                    readings: history,
                    valueExtractor: (r) => r.temperature,
                  )
                else
                  SensorChart(
                    title: 'Humidity History',
                    unit: '%',
                    accentColor: const Color(0xFF3B82F6),
                    readings: history,
                    valueExtractor: (r) => r.humidity,
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    IoTProvider provider,
    IoTReading reading,
  ) {
    final localDateTime = (provider.lastUpdated ?? reading.createdAt).toLocal();
    final updatedText = DateFormat('d MMM y, h:mm a').format(localDateTime);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withAlpha(isDark ? 50 : 25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.sensors,
                      color: Color(0xFF4F46E5),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'IoT Monitor',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Live sensor data from ThingSpeak',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(isDark ? 40 : 20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981).withAlpha(100)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Connected',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'Channel #${ThingSpeakConfig.channelId} • Entry #${reading.entryId}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                'Last updated: $updatedText',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTemperatureStatus(double? temp) => IoTReading.getTemperatureStatus(temp);
  String _getHumidityStatus(double? humidity) => IoTReading.getHumidityStatus(humidity);
  String _getAirQualityStatus(double? aqi) => IoTReading.getAirQualityStatus(aqi);
  String _getLightStatus(double? light) => IoTReading.getLightStatus(light);
}

class _SensorCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String caption;

  const _SensorCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(isDark ? 50 : 25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
