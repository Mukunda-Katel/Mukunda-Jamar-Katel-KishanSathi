import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/weather_service.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../core/theme/app_theme.dart';

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

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _weatherService.getCurrentWeather(
        _locationController.text,
        authState.token,
      );

      setState(() {
        _weatherData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location Search
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Enter location',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _fetchWeather(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: _fetchWeather,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _fetchWeather,
                ),
              ],
            ),
            const Divider(color: Colors.white30),
            const SizedBox(height: 8),

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
              _buildWeatherContent()
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

  Widget _buildWeatherContent() {
    final location = _weatherData!['location'];
    final current = _weatherData!['current'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location Name
        Text(
          '${location['name']}, ${location['region']}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          location['localtime'] ?? '',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 16),

        // Temperature and Condition
        Row(
          children: [
            // Weather Icon
            if (current['condition']['icon'] != null)
              Image.network(
                'https:${current['condition']['icon']}',
                width: 64,
                height: 64,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.wb_sunny, color: Colors.white, size: 64),
              ),
            const SizedBox(width: 16),

            // Temperature
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${current['temp_c']}°C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  current['condition']['text'] ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Weather Details
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildWeatherDetail(
              Icons.water_drop,
              'Humidity',
              '${current['humidity']}%',
            ),
            _buildWeatherDetail(
              Icons.air,
              'Wind',
              '${current['wind_kph']} km/h',
            ),
            _buildWeatherDetail(
              Icons.thermostat,
              'Feels Like',
              '${current['feelslike_c']}°C',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildWeatherDetail(
              Icons.compress,
              'Pressure',
              '${current['pressure_mb']} mb',
            ),
            _buildWeatherDetail(
              Icons.wb_sunny,
              'UV Index',
              '${current['uv']}',
            ),
            _buildWeatherDetail(
              Icons.cloud,
              'Cloud',
              '${current['cloud']}%',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeatherDetail(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
