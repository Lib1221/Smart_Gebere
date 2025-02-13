import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LocationService {
  Future<Map<String, dynamic>> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are disabled.");
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permissions are permanently denied.");
      } else if (permission == LocationPermission.denied) {
        throw Exception("Location permissions are denied.");
      }
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    double latitude = position.latitude;
    double longitude = position.longitude;
    
    double elevation = await getElevation(latitude, longitude);

    Map<String, dynamic> weather = await getWeather(latitude, longitude);

    return {
      "latitude": latitude,
      "longitude": longitude,
      "elevation": elevation,
      "weather": weather,
    };
  }

  Future<double> getElevation(double lat, double lon) async {
    final elevationUrl = Uri.parse('https://api.open-elevation.com/api/v1/lookup');
    final response = await http.post(
      elevationUrl,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"locations": [{"latitude": lat, "longitude": lon}]}),
    );

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      return jsonResponse['results'][0]['elevation'] ?? 0.0;
    } else {
      throw Exception("Failed to fetch elevation data.");
    }
  }

  Future<Map<String, dynamic>> getWeather(double lat, double lon) async {
    String apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';

    if (apiKey.isEmpty) {
      throw Exception("Missing OpenWeather API Key.");
    }

    final weatherUrl = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric');

    final response = await http.get(weatherUrl);

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      return {
        "temperature": jsonResponse['main']['temp'],
        "humidity": jsonResponse['main']['humidity'],
        "weather": jsonResponse['weather'][0]['description'],
      };
    } else {
      throw Exception("Failed to fetch weather data.");
    }
  }
}
