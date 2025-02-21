import 'package:flutter/material.dart';

class WeekDetailPage extends StatelessWidget {
  final Map<String, dynamic> week;

  const WeekDetailPage({super.key, required this.week});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade600,
        title: Text("Week ${week['week']} Details"),
        elevation: 0,
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

  // Modern Weather Forecast Section
  Widget _buildWeatherSection() {
    List<Map<String, String>> forecast = [
      {"day": "Mon", "emoji": "☀️", "temp": "28°C", "wind": "10 km/h"},
      {"day": "Tue", "emoji": "⛅", "temp": "26°C", "wind": "12 km/h"},
      {"day": "Wed", "emoji": "🌧️", "temp": "24°C", "wind": "15 km/h"},
      {"day": "Thu", "emoji": "🌦️", "temp": "25°C", "wind": "8 km/h"},
      {"day": "Fri", "emoji": "🌩️", "temp": "22°C", "wind": "20 km/h"},
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "🌦 Weekly Weather Forecast",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade800),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 120, // Fixed height for horizontal scrolling
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: forecast.length,
                itemBuilder: (context, index) {
                  final data = forecast[index];
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.green.shade200, blurRadius: 5, offset: Offset(2, 3)),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(data['day']!, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(data['emoji']!, style: TextStyle(fontSize: 30)),
                        Text(data['temp']!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        Text("💨 ${data['wind']!}", style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
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

  // Tasks Section
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
              '📝 Tasks for Week ${week['week']}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade800),
            ),
            const SizedBox(height: 10),
            ...week['tasks'].map<Widget>((task) {
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
