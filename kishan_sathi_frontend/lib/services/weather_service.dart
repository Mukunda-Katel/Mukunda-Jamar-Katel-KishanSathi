import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';

class WeatherService {
  static const String baseUrl = '${ApiConstants.apiBaseUrl}/farmer';

  /// Get current weather for a location
  Future<Map<String, dynamic>> getCurrentWeather(
    String location,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/weather/current/').replace(
          queryParameters: {'location': location},
        ),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch weather');
      }
    } catch (e) {
      throw Exception('Error fetching weather: $e');
    }
  }

  /// Get weather forecast for a location
  Future<Map<String, dynamic>> getWeatherForecast(
    String location,
    String token, {
    int days = 3,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/weather/forecast/').replace(
          queryParameters: {
            'location': location,
            'days': days.toString(),
          },
        ),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch forecast');
      }
    } catch (e) {
      throw Exception('Error fetching forecast: $e');
    }
  }
}
