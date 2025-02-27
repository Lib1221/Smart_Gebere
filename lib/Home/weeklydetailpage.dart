import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:smart_gebere/geo_Location/wetherdata.dart';

class WeekDetailPage extends StatefulWidget {
  final Map<String, dynamic> week;

  const WeekDetailPage({Key? key, required this.week}) : super(key: key);

  @override
  _WeekDetailPageState createState() => _WeekDetailPageState();
}

class _WeekDetailPageState extends State<WeekDetailPage> {
  bool isLoading = false;
  List<Map<String, dynamic>> weatherData = [];

  final WeatherDataFetcher weatherService = WeatherDataFetcher();

  @override
  void initState() {
    super.initState();
    loadWeather();
  }

  Future<void> loadWeather() async {
    if (weatherData.isEmpty) {
      setState(() {
        isLoading = true;
      });

      try {
        final fetchedData = await weatherService.fetchWeather();
        setState(() {
          weatherData = fetchedData;
          isLoading = false;
        });
      } catch (e) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String getWeatherEmoji(String code) {
    switch (code) {
      case "0": return "☀️"; // Clear sky
      case "1": return "⛅"; // Partly cloudy
      case "2": return "☁️"; // Cloudy
      case "3": return "🌥️"; // Overcast
      case "45": return "🌫️"; // Foggy
      case "48": return "❄️"; // Depositing rime fog
      case "51": return "🌦️"; // Drizzle
      case "53": return "🌧️"; // Heavy drizzle
      case "55": return "🌧️"; // Continuous drizzle
      case "56": return "❄️"; // Freezing drizzle
      case "57": return "❄️"; // Heavy freezing drizzle
      case "61": return "🌧️"; // Showers
      case "63": return "🌧️"; // Heavy showers
      case "65": return "🌧️"; // Continuous showers
      case "66": return "❄️"; // Freezing showers
      case "67": return "❄️"; // Heavy freezing showers
      case "71": return "❄️"; // Snow flurries
      case "73": return "❄️"; // Light snow
      case "75": return "❄️"; // Heavy snow
      case "77": return "❄️"; // Snow grains
      case "80": return "🌧️"; // Showers of rain
      case "81": return "🌧️"; // Heavy rain showers
      case "82": return "🌧️"; // Very heavy rain showers
      case "85": return "❄️"; // Showers of snow
      case "86": return "❄️"; // Heavy snow showers
      case "95": return "🌩️"; // Thunderstorms
      case "96": return "🌩️"; // Thunderstorms with hail
      case "99": return "🌩️"; // Severe thunderstorms
      default: return "🌤️"; // Default weather emoji
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Week ${widget.week['week']} Details"),
        backgroundColor: Colors.green.shade600,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeatherSection(),
            const SizedBox(height: 20),
            _buildTasksSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherSection() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (weatherData.isEmpty) {
      return const Center(child: Text("No weather data available."));
    } else {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Weather Forecast",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: weatherData.length,
                  itemBuilder: (context, index) {
                    final data = weatherData[index];
                    String weatherCode = data['weathercode'].toString(); // Ensure it's a string
                    String weatherEmoji = getWeatherEmoji(weatherCode);

                    return Container(
                      width: 100,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.shade200,
                            blurRadius: 5,
                            offset: const Offset(2, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Display the day name (ensure it's a string)
                          Text(
                            data['day'].toString(), // Ensure it's a string
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Display the weather emoji
                          Text(
                            weatherEmoji,
                            style: const TextStyle(fontSize: 30),
                          ),
                          Text(
                            "Min: ${data['min_temp']}°",
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            "Max: ${data['max_temp']}°",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildTasksSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📝 Tasks for Week ${widget.week['week']}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 10),
            ...widget.week['tasks'].map<Widget>((task) {
              return Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 8),
                child: Text(
                  '• $task',
                  style: TextStyle(fontSize: 16, color: Colors.green.shade600),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
