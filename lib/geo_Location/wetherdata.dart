import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class WeatherDataFetcher {
  final String apiKey = dotenv.env['apiKeyW']??"no";

  Future<List<Map<String, dynamic>>> fetchWeather() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are disabled.");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permissions are denied forever.");
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    double latitude = position.latitude;
    double longitude = position.longitude;

    final url =
        'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&daily=temperature_2m_max,temperature_2m_min,weathercode&timezone=auto&apikey=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Build a forecast list for 7 days
        List<Map<String, dynamic>> forecast = List.generate(
            7,
            (index) => {
                  'date': data['daily']['time'][index],
                  'day': DateFormat('EEEE')
                      .format(DateTime.parse(data['daily']['time'][index])),
                  'max_temp': data['daily']['temperature_2m_max'][index],
                  'min_temp': data['daily']['temperature_2m_min'][index],
                  'weathercode': data['daily']['weathercode'][index],
                });
        return forecast;
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception("Error fetching weather data: $e");
    }
  }
}
