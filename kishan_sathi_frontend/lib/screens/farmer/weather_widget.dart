import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/weather_service.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';

class WeatherWidget extends StatefulWidget {
  final String? location;

  const WeatherWidget({super.key, this.location});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? _weatherData;
  bool _isLoading = false;
  String? _error;
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.location != null && widget.location!.isNotEmpty) {
      _locationController.text = widget.location!;
      _fetchWeather();
    } else {
      _locationController.text = 'Kathmandu';
      _fetchWeather();
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _fetchWeather() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthSuccess) return;

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _weatherService.getCurrentWeather(
        _locationController.text,
        authState.token,
      );

      if (!mounted) return;

      setState(() {
        _weatherData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTinyScreen = screenWidth < 360;
    final isSmallScreen = screenWidth < 600;

    final outerMargin = isTinyScreen ? 12.0 : 16.0;
    final cardRadius = isTinyScreen ? 14.0 : 16.0;
    final cardPadding = isTinyScreen ? 12.0 : 16.0;
    final locationIconSize = isTinyScreen ? 18.0 : 20.0;
    final locationInputSize = isTinyScreen ? 14.0 : 15.0;
    final actionIconSize = isTinyScreen ? 20.0 : 24.0;

    return Container(
      margin: EdgeInsets.all(outerMargin),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location Search
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.white, size: locationIconSize),
                SizedBox(width: isTinyScreen ? 6 : 8),
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    style: TextStyle(color: Colors.white, fontSize: locationInputSize),
                    decoration: InputDecoration(
                      hintText: 'Enter location',
                      hintStyle: TextStyle(color: Colors.white70, fontSize: locationInputSize),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _fetchWeather(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search, color: Colors.white, size: actionIconSize),
                  onPressed: _fetchWeather,
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.white, size: actionIconSize),
                  onPressed: _fetchWeather,
                ),
              ],
            ),
            const Divider(color: Colors.white30),
            SizedBox(height: isTinyScreen ? 4 : 8),

            // Weather Content
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            else if (_error != null)
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white70, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else if (_weatherData != null)
              _buildWeatherContent(
                isTinyScreen: isTinyScreen,
                isSmallScreen: isSmallScreen,
              )
            else
              const Center(
                child: Text(
                  'Enter a location to see weather',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherContent({
    required bool isTinyScreen,
    required bool isSmallScreen,
  }) {
    final location = _weatherData!['location'];
    final current = _weatherData!['current'];
    final details = [
      {'icon': Icons.water_drop, 'label': 'Humidity', 'value': '${current['humidity']}%'},
      {'icon': Icons.air, 'label': 'Wind', 'value': '${current['wind_kph']} km/h'},
      {'icon': Icons.thermostat, 'label': 'Feels Like', 'value': '${current['feelslike_c']}°C'},
      {'icon': Icons.compress, 'label': 'Pressure', 'value': '${current['pressure_mb']} mb'},
      {'icon': Icons.wb_sunny, 'label': 'UV Index', 'value': '${current['uv']}'},
      {'icon': Icons.cloud, 'label': 'Cloud', 'value': '${current['cloud']}%'},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrowCard = constraints.maxWidth < 340;
        final detailsPerRow = isNarrowCard ? 2 : 3;
        final detailSpacing = isNarrowCard ? 8.0 : 10.0;
        final detailItemWidth =
            (constraints.maxWidth - (detailSpacing * (detailsPerRow - 1))) / detailsPerRow;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location Name
            Text(
              '${location['name']}, ${location['region']}',
              style: TextStyle(
                color: Colors.white,
                fontSize: isTinyScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              location['localtime'] ?? '',
              style: TextStyle(
                color: Colors.white70,
                fontSize: isTinyScreen ? 11 : 12,
              ),
            ),
            SizedBox(height: isTinyScreen ? 12 : 16),

            // Temperature and Condition
            isNarrowCard
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (current['condition']['icon'] != null)
                        Image.network(
                          'https:${current['condition']['icon']}',
                          width: isTinyScreen ? 52 : 60,
                          height: isTinyScreen ? 52 : 60,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.wb_sunny,
                            color: Colors.white,
                            size: isTinyScreen ? 52 : 60,
                          ),
                        ),
                      SizedBox(height: isTinyScreen ? 8 : 10),
                      Text(
                        '${current['temp_c']}°C',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTinyScreen ? 38 : 44,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        current['condition']['text'] ?? '',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTinyScreen ? 14 : 16,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      if (current['condition']['icon'] != null)
                        Image.network(
                          'https:${current['condition']['icon']}',
                          width: isSmallScreen ? 56 : 64,
                          height: isSmallScreen ? 56 : 64,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.wb_sunny,
                            color: Colors.white,
                            size: isSmallScreen ? 56 : 64,
                          ),
                        ),
                      SizedBox(width: isSmallScreen ? 12 : 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${current['temp_c']}°C',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 40 : 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            current['condition']['text'] ?? '',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
            SizedBox(height: isTinyScreen ? 12 : 16),

            // Weather Details
            Wrap(
              spacing: detailSpacing,
              runSpacing: detailSpacing,
              children: details.map((detail) {
                return SizedBox(
                  width: detailItemWidth,
                  child: _buildWeatherDetail(
                    detail['icon'] as IconData,
                    detail['label'] as String,
                    detail['value'] as String,
                    iconSize: isTinyScreen ? 18 : 20,
                    labelFontSize: isTinyScreen ? 10 : 11,
                    valueFontSize: isTinyScreen ? 13 : 14,
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeatherDetail(
    IconData icon,
    String label,
    String value, {
    required double iconSize,
    required double labelFontSize,
    required double valueFontSize,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: iconSize),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white70, fontSize: labelFontSize),
          textAlign: TextAlign.center,
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: valueFontSize,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
