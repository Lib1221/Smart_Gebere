import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smart_gebere/core/services/offline_storage.dart';

/// Comprehensive weather service with caching and fallback mechanisms
class WeatherService {
  static WeatherService? _instance;
  static WeatherService get instance => _instance ??= WeatherService._();
  
  WeatherService._();
  
  /// Fetches current weather with caching
  /// Uses Open-Meteo (free, no API key required) as primary source
  Future<Map<String, dynamic>> getCurrentWeather({bool forceRefresh = false}) async {
    // Try cached data first if not forcing refresh
    if (!forceRefresh) {
      final cached = OfflineStorage.getCachedWeather('current');
      if (cached != null) {
        debugPrint('[WeatherService] Returning cached weather');
        return cached;
      }
    }
    
    try {
      // Get current position
      final position = await _getCurrentPosition();
      
      // Fetch weather from Open-Meteo (free, no API key needed)
      final weather = await _fetchFromOpenMeteo(position.latitude, position.longitude);
      
      // Cache the result
      await OfflineStorage.cacheWeather('current', weather);
      
      debugPrint('[WeatherService] Fetched and cached new weather data');
      return weather;
    } catch (e) {
      debugPrint('[WeatherService] Error: $e');
      
      // Return any cached data even if expired
      final cached = OfflineStorage.get(OfflineStorage.weatherCacheBox, 'current');
      if (cached != null) {
        return cached;
      }
      
      // Return empty placeholder
      return _getDefaultWeather();
    }
  }
  
  /// Fetches 7-day weather forecast
  Future<Map<String, dynamic>> getWeatherForecast({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = OfflineStorage.getCachedWeather('forecast');
      if (cached != null) {
        return cached;
      }
    }
    
    try {
      final position = await _getCurrentPosition();
      final forecast = await _fetchForecastFromOpenMeteo(position.latitude, position.longitude);
      
      await OfflineStorage.cacheWeather('forecast', forecast);
      return forecast;
    } catch (e) {
      debugPrint('[WeatherService] Forecast error: $e');
      return {'daily': []};
    }
  }
  
  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied');
    }
    
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 10),
    );
  }
  
  /// Fetch weather from Open-Meteo (free, no API key required)
  Future<Map<String, dynamic>> _fetchFromOpenMeteo(double lat, double lon) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat'
      '&longitude=$lon'
      '&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m'
      '&timezone=auto'
    );
    
    final response = await http.get(url).timeout(const Duration(seconds: 15));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final current = data['current'] ?? {};
      
      return {
        'current': {
          'temperature_2m': current['temperature_2m'] ?? 0,
          'humidity': current['relative_humidity_2m'] ?? 0,
          'wind_speed': current['wind_speed_10m'] ?? 0,
          'weather_code': current['weather_code'] ?? 0,
        },
        'condition': _getWeatherCondition(_asInt(current['weather_code'])),
        'description': _getWeatherDescription(_asInt(current['weather_code'])),
        'icon': _getWeatherEmoji(_asInt(current['weather_code'])),
        'latitude': lat,
        'longitude': lon,
        'fetchedAt': DateTime.now().toIso8601String(),
      };
    } else {
      throw Exception('Open-Meteo API returned ${response.statusCode}');
    }
  }
  
  /// Fetch 7-day forecast from Open-Meteo
  Future<Map<String, dynamic>> _fetchForecastFromOpenMeteo(double lat, double lon) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat'
      '&longitude=$lon'
      '&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum'
      '&timezone=auto'
      '&forecast_days=7'
    );
    
    final response = await http.get(url).timeout(const Duration(seconds: 15));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final daily = data['daily'] ?? {};
      
      final days = <Map<String, dynamic>>[];
      final dates = (daily['time'] as List?) ?? [];
      final codes = (daily['weather_code'] as List?) ?? [];
      final maxTemps = (daily['temperature_2m_max'] as List?) ?? [];
      final minTemps = (daily['temperature_2m_min'] as List?) ?? [];
      final precipitation = (daily['precipitation_sum'] as List?) ?? [];
      
      for (int i = 0; i < dates.length; i++) {
        final weatherCode = codes.length > i ? _asInt(codes[i]) : 0;
        days.add({
          'date': dates[i],
          'weather_code': weatherCode,
          'temp_max': maxTemps.length > i ? maxTemps[i] : 0,
          'temp_min': minTemps.length > i ? minTemps[i] : 0,
          'precipitation': precipitation.length > i ? precipitation[i] : 0,
          'icon': _getWeatherEmoji(weatherCode),
          'condition': _getWeatherCondition(weatherCode),
        });
      }
      
      return {
        'daily': days,
        'fetchedAt': DateTime.now().toIso8601String(),
      };
    } else {
      throw Exception('Open-Meteo forecast API returned ${response.statusCode}');
    }
  }
  
  /// Fallback to OpenWeatherMap if configured
  Future<Map<String, dynamic>> _fetchFromOpenWeatherMap(double lat, double lon) async {
    final apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('OpenWeatherMap API key not configured');
    }
    
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather'
      '?lat=$lat&lon=$lon&appid=$apiKey&units=metric'
    );
    
    final response = await http.get(url).timeout(const Duration(seconds: 15));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final main = data['main'] ?? {};
      final weather = (data['weather'] as List?)?.firstOrNull ?? {};
      
      return {
        'current': {
          'temperature_2m': main['temp'] ?? 0,
          'humidity': main['humidity'] ?? 0,
          'wind_speed': data['wind']?['speed'] ?? 0,
        },
        'condition': weather['main'] ?? 'Unknown',
        'description': weather['description'] ?? '',
        'icon': _owmIdToEmoji(_asInt(weather['id'])),
        'latitude': lat,
        'longitude': lon,
        'fetchedAt': DateTime.now().toIso8601String(),
      };
    } else {
      throw Exception('OpenWeatherMap API returned ${response.statusCode}');
    }
  }
  
  Map<String, dynamic> _getDefaultWeather() {
    return {
      'current': {
        'temperature_2m': null,
        'humidity': null,
        'wind_speed': null,
      },
      'condition': 'Unknown',
      'description': 'Weather data unavailable',
      'icon': '❓',
      'fetchedAt': DateTime.now().toIso8601String(),
    };
  }
  
  /// Helper to safely convert dynamic to int
  int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Convert WMO weather codes to human-readable condition
  String _getWeatherCondition(int code) {
    if (code == 0) return 'Clear';
    if (code == 1) return 'Mainly Clear';
    if (code == 2) return 'Partly Cloudy';
    if (code == 3) return 'Overcast';
    if (code >= 45 && code <= 48) return 'Foggy';
    if (code >= 51 && code <= 55) return 'Drizzle';
    if (code >= 56 && code <= 57) return 'Freezing Drizzle';
    if (code >= 61 && code <= 65) return 'Rain';
    if (code >= 66 && code <= 67) return 'Freezing Rain';
    if (code >= 71 && code <= 77) return 'Snow';
    if (code >= 80 && code <= 82) return 'Rain Showers';
    if (code >= 85 && code <= 86) return 'Snow Showers';
    if (code >= 95 && code <= 99) return 'Thunderstorm';
    return 'Unknown';
  }
  
  /// Convert WMO weather codes to descriptions
  String _getWeatherDescription(int code) {
    if (code == 0) return 'Clear sky';
    if (code == 1) return 'Mainly clear';
    if (code == 2) return 'Partly cloudy';
    if (code == 3) return 'Overcast';
    if (code == 45) return 'Fog';
    if (code == 48) return 'Depositing rime fog';
    if (code == 51) return 'Light drizzle';
    if (code == 53) return 'Moderate drizzle';
    if (code == 55) return 'Dense drizzle';
    if (code == 61) return 'Slight rain';
    if (code == 63) return 'Moderate rain';
    if (code == 65) return 'Heavy rain';
    if (code == 71) return 'Slight snow';
    if (code == 73) return 'Moderate snow';
    if (code == 75) return 'Heavy snow';
    if (code == 80) return 'Slight rain showers';
    if (code == 81) return 'Moderate rain showers';
    if (code == 82) return 'Heavy rain showers';
    if (code == 95) return 'Thunderstorm';
    if (code == 96 || code == 99) return 'Thunderstorm with hail';
    return 'Weather conditions';
  }
  
  /// Convert WMO weather codes to emojis
  String _getWeatherEmoji(int code) {
    if (code == 0) return '☀️';
    if (code == 1) return '🌤️';
    if (code == 2) return '⛅';
    if (code == 3) return '☁️';
    if (code >= 45 && code <= 48) return '🌫️';
    if (code >= 51 && code <= 57) return '🌧️';
    if (code >= 61 && code <= 67) return '🌧️';
    if (code >= 71 && code <= 77) return '❄️';
    if (code >= 80 && code <= 82) return '🌦️';
    if (code >= 85 && code <= 86) return '🌨️';
    if (code >= 95 && code <= 99) return '⛈️';
    return '🌡️';
  }
  
  /// Convert OpenWeatherMap weather IDs to emojis
  String _owmIdToEmoji(int id) {
    if (id >= 200 && id < 300) return '⛈️';
    if (id >= 300 && id < 400) return '🌧️';
    if (id >= 500 && id < 600) return '🌧️';
    if (id >= 600 && id < 700) return '❄️';
    if (id >= 700 && id < 800) return '🌫️';
    if (id == 800) return '☀️';
    if (id == 801) return '🌤️';
    if (id == 802) return '⛅';
    if (id >= 803) return '☁️';
    return '🌡️';
  }
}

