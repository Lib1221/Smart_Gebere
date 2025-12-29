import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/services/offline_storage.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/ai_reliability.dart';
import '../../settings/app_settings.dart';
import '../../l10n/app_localizations.dart';

class WeatherAdvisorPage extends StatefulWidget {
  const WeatherAdvisorPage({super.key});

  @override
  State<WeatherAdvisorPage> createState() => _WeatherAdvisorPageState();
}

class _WeatherAdvisorPageState extends State<WeatherAdvisorPage> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _currentWeather;
  List<Map<String, dynamic>> _forecast = [];
  List<WeatherAlert> _alerts = [];
  List<FarmingAdvice> _advice = [];
  GenerativeModel? _model;
  Position? _position;

  @override
  void initState() {
    super.initState();
    _initializeModel();
    _loadWeatherData();
  }

  Future<void> _initializeModel() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty) {
      final modelName = dotenv.env['GEMINI_MODEL'] ?? 'gemini-1.5-flash';
      _model = GenerativeModel(model: modelName, apiKey: apiKey);
    }
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get location
      await _getLocation();
      
      if (_position != null) {
        // Check cache first
        final cacheKey = '${_position!.latitude.toStringAsFixed(2)}_${_position!.longitude.toStringAsFixed(2)}';
        final cached = OfflineStorage.getCachedWeather(cacheKey);
        
        if (cached != null) {
          _processWeatherData(cached);
        }
        
        // Fetch fresh data if online
        final connectivity = Provider.of<ConnectivityService>(context, listen: false);
        if (connectivity.isOnline) {
          await _fetchWeatherData();
        }
      }
    } catch (e) {
      debugPrint('[WeatherAdvisor] Error: $e');
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      _position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
    } catch (e) {
      debugPrint('[WeatherAdvisor] Location error: $e');
      // Use default Ethiopian coordinates (Addis Ababa)
      _position = Position(
        latitude: 9.0192,
        longitude: 38.7525,
        timestamp: DateTime.now(),
        accuracy: 100,
        altitude: 2355,
        altitudeAccuracy: 10,
        heading: 0,
        headingAccuracy: 10,
        speed: 0,
        speedAccuracy: 0,
      );
    }
  }

  Future<void> _fetchWeatherData() async {
    if (_position == null) return;

    // Fetch from Open-Meteo (free, no API key needed)
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=${_position!.latitude}'
      '&longitude=${_position!.longitude}'
      '&current=temperature_2m,relative_humidity_2m,precipitation,weather_code,wind_speed_10m'
      '&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,wind_speed_10m_max'
      '&timezone=auto'
      '&forecast_days=7',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Cache the data
        final cacheKey = '${_position!.latitude.toStringAsFixed(2)}_${_position!.longitude.toStringAsFixed(2)}';
        await OfflineStorage.cacheWeather(cacheKey, data);
        
        _processWeatherData(data);
        await _generateAIAdvice(data);
      }
    } catch (e) {
      debugPrint('[WeatherAdvisor] API error: $e');
    }
  }

  void _processWeatherData(Map<String, dynamic> data) {
    // Parse current weather
    if (data['current'] != null) {
      _currentWeather = {
        'temperature': data['current']['temperature_2m'],
        'humidity': data['current']['relative_humidity_2m'],
        'precipitation': data['current']['precipitation'],
        'weather_code': data['current']['weather_code'],
        'wind_speed': data['current']['wind_speed_10m'],
      };
    }

    // Parse daily forecast
    if (data['daily'] != null) {
      final daily = data['daily'];
      _forecast = [];
      
      for (int i = 0; i < (daily['time'] as List).length; i++) {
        _forecast.add({
          'date': daily['time'][i],
          'weather_code': daily['weather_code'][i],
          'temp_max': daily['temperature_2m_max'][i],
          'temp_min': daily['temperature_2m_min'][i],
          'precipitation': daily['precipitation_sum'][i],
          'precipitation_probability': daily['precipitation_probability_max'][i],
          'wind_speed': daily['wind_speed_10m_max'][i],
        });
      }

      // Generate alerts from forecast
      _generateAlerts();
    }

    if (mounted) setState(() {});
  }

  void _generateAlerts() {
    _alerts = [];

    for (final day in _forecast) {
      final date = day['date'];
      final precip = day['precipitation'] ?? 0.0;
      final precipProb = day['precipitation_probability'] ?? 0;
      final tempMax = day['temp_max'] ?? 25.0;
      final tempMin = day['temp_min'] ?? 15.0;
      final windSpeed = day['wind_speed'] ?? 0.0;

      // Heavy rain alert
      if (precip > 20 || precipProb > 80) {
        _alerts.add(WeatherAlert(
          type: AlertType.heavyRain,
          date: date,
          message: 'Heavy rainfall expected ($precip mm)',
          severity: precip > 40 ? AlertSeverity.high : AlertSeverity.medium,
          advice: [
            'Ensure proper field drainage',
            'Delay fertilizer application',
            'Protect young seedlings',
            'Check for waterlogging risk',
          ],
        ));
      }

      // Heat alert
      if (tempMax > 35) {
        _alerts.add(WeatherAlert(
          type: AlertType.heat,
          date: date,
          message: 'High temperature expected (${tempMax}°C)',
          severity: tempMax > 40 ? AlertSeverity.high : AlertSeverity.medium,
          advice: [
            'Irrigate early morning or evening',
            'Apply mulch to reduce evaporation',
            'Provide shade for sensitive crops',
            'Avoid midday field work',
          ],
        ));
      }

      // Cold alert
      if (tempMin < 5) {
        _alerts.add(WeatherAlert(
          type: AlertType.cold,
          date: date,
          message: 'Low temperature expected (${tempMin}°C)',
          severity: tempMin < 0 ? AlertSeverity.high : AlertSeverity.medium,
          advice: [
            'Cover sensitive crops overnight',
            'Delay planting if frost risk',
            'Protect flowering plants',
            'Harvest mature crops early',
          ],
        ));
      }

      // Wind alert
      if (windSpeed > 30) {
        _alerts.add(WeatherAlert(
          type: AlertType.wind,
          date: date,
          message: 'Strong winds expected (${windSpeed} km/h)',
          severity: windSpeed > 50 ? AlertSeverity.high : AlertSeverity.medium,
          advice: [
            'Stake tall plants',
            'Delay spraying operations',
            'Secure loose materials',
            'Check for lodging risk',
          ],
        ));
      }
    }
  }

  Future<void> _generateAIAdvice(Map<String, dynamic> weatherData) async {
    if (_model == null) return;

    final settings = Provider.of<AppSettings>(context, listen: false);
    final language = settings.aiLanguageName();

    final prompt = '''
You are an Ethiopian agricultural advisor. Based on the current weather conditions, provide specific farming advice.

Current Weather:
- Temperature: ${_currentWeather?['temperature']}°C
- Humidity: ${_currentWeather?['humidity']}%
- Precipitation: ${_currentWeather?['precipitation']} mm
- Wind Speed: ${_currentWeather?['wind_speed']} km/h

7-Day Forecast Summary:
${_forecast.take(3).map((f) => '${f['date']}: ${f['temp_min']}°C - ${f['temp_max']}°C, Rain: ${f['precipitation']}mm').join('\n')}

Respond in $language.

Provide exactly 4 pieces of practical farming advice based on these conditions. Focus on:
1. Irrigation timing
2. Planting/harvesting activities
3. Pest/disease prevention based on weather
4. Field work recommendations

Return a JSON array:
[
  {"title": "advice title", "description": "detailed advice", "icon": "irrigation|planting|pest|fieldwork"},
  ...
]

Return ONLY the JSON array.
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      
      debugPrint('[WeatherAdvisor] AI Response: $text');
      
      final parsed = AIReliability.extractJsonArray(text);
      if (parsed != null && mounted) {
        setState(() {
          _advice = parsed.map((a) => FarmingAdvice.fromJson(a)).toList();
        });
      }
    } catch (e) {
      debugPrint('[WeatherAdvisor] AI error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final connectivity = Provider.of<ConnectivityService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.weatherAdvisor),
        backgroundColor: const Color(0xFF0277BD),
        foregroundColor: Colors.white,
        actions: [
          if (!connectivity.isOnline)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.cloud_off, color: Colors.orange),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWeatherData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadWeatherData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Current Weather Card
                      _buildCurrentWeatherCard(),
                      const SizedBox(height: 20),

                      // Weather Alerts
                      if (_alerts.isNotEmpty) ...[
                        _buildAlertSection(),
                        const SizedBox(height: 20),
                      ],

                      // AI Advice
                      if (_advice.isNotEmpty) ...[
                        _buildAdviceSection(),
                        const SizedBox(height: 20),
                      ],

                      // 7-Day Forecast
                      _buildForecastSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCurrentWeatherCard() {
    final loc = AppLocalizations.of(context);
    final temp = _currentWeather?['temperature'] ?? '--';
    final humidity = _currentWeather?['humidity'] ?? '--';
    final precipitation = _currentWeather?['precipitation'] ?? 0;
    final windSpeed = _currentWeather?['wind_speed'] ?? '--';
    final weatherCode = _currentWeather?['weather_code'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0277BD), Color(0xFF01579B)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0277BD).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.currentWeather,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$temp',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const Text(
                        '°C',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Icon(
                _getWeatherIcon(weatherCode),
                size: 80,
                color: Colors.white.withOpacity(0.9),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherStat(Icons.water_drop, '$humidity%', loc.humidity),
              _buildWeatherStat(Icons.grain, '${precipitation}mm', loc.rain),
              _buildWeatherStat(Icons.air, '$windSpeed km/h', loc.wind),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertSection() {
    final loc = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              loc.weatherAlerts,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._alerts.take(3).map((alert) => _buildAlertCard(alert)),
      ],
    );
  }

  Widget _buildAlertCard(WeatherAlert alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alert.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: alert.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(alert.icon, color: alert.color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert.message,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: alert.color,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: alert.color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  alert.severityLabel,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alert.date,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 8),
          ...alert.advice.map((a) => Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: alert.color)),
                Expanded(child: Text(a, style: const TextStyle(fontSize: 13))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAdviceSection() {
    final loc = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lightbulb, color: Color(0xFF4CAF50)),
            const SizedBox(width: 8),
            Text(
              loc.farmingAdvice,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._advice.map((advice) => _buildAdviceCard(advice)),
      ],
    );
  }

  Widget _buildAdviceCard(FarmingAdvice advice) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF4CAF50).withOpacity(0.1),
          child: Icon(advice.iconData, color: const Color(0xFF4CAF50)),
        ),
        title: Text(
          advice.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(advice.description),
        ),
      ),
    );
  }

  Widget _buildForecastSection() {
    final loc = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.sevenDayForecast,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _forecast.length,
            itemBuilder: (context, index) {
              final day = _forecast[index];
              return _buildForecastCard(day, index == 0);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildForecastCard(Map<String, dynamic> day, bool isToday) {
    final loc = AppLocalizations.of(context);
    final date = DateTime.tryParse(day['date'] ?? '') ?? DateTime.now();
    final dayName = isToday
        ? loc.today
        : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isToday ? const Color(0xFF0277BD) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            dayName,
            style: TextStyle(
              color: isToday ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Icon(
            _getWeatherIcon(day['weather_code'] ?? 0),
            size: 32,
            color: isToday ? Colors.white : const Color(0xFF0277BD),
          ),
          const SizedBox(height: 8),
          Text(
            '${day['temp_max']?.toStringAsFixed(0) ?? '--'}°',
            style: TextStyle(
              color: isToday ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${day['temp_min']?.toStringAsFixed(0) ?? '--'}°',
            style: TextStyle(
              color: isToday ? Colors.white70 : Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(int code) {
    // WMO Weather interpretation codes
    if (code == 0) return Icons.wb_sunny;
    if (code <= 3) return Icons.cloud;
    if (code <= 49) return Icons.foggy;
    if (code <= 69) return Icons.grain;
    if (code <= 79) return Icons.ac_unit;
    if (code <= 99) return Icons.thunderstorm;
    return Icons.cloud;
  }
}

// Supporting classes
enum AlertType { heavyRain, heat, cold, wind, drought }
enum AlertSeverity { low, medium, high }

class WeatherAlert {
  final AlertType type;
  final String date;
  final String message;
  final AlertSeverity severity;
  final List<String> advice;

  WeatherAlert({
    required this.type,
    required this.date,
    required this.message,
    required this.severity,
    required this.advice,
  });

  Color get color {
    switch (severity) {
      case AlertSeverity.high:
        return Colors.red;
      case AlertSeverity.medium:
        return Colors.orange;
      case AlertSeverity.low:
        return Colors.yellow[700]!;
    }
  }

  String get severityLabel {
    switch (severity) {
      case AlertSeverity.high:
        return 'HIGH';
      case AlertSeverity.medium:
        return 'MEDIUM';
      case AlertSeverity.low:
        return 'LOW';
    }
  }

  IconData get icon {
    switch (type) {
      case AlertType.heavyRain:
        return Icons.water;
      case AlertType.heat:
        return Icons.wb_sunny;
      case AlertType.cold:
        return Icons.ac_unit;
      case AlertType.wind:
        return Icons.air;
      case AlertType.drought:
        return Icons.water_drop_outlined;
    }
  }
}

class FarmingAdvice {
  final String title;
  final String description;
  final String icon;

  FarmingAdvice({
    required this.title,
    required this.description,
    required this.icon,
  });

  factory FarmingAdvice.fromJson(Map<String, dynamic> json) {
    return FarmingAdvice(
      title: json['title']?.toString() ?? 'Advice',
      description: json['description']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'fieldwork',
    );
  }

  IconData get iconData {
    switch (icon.toLowerCase()) {
      case 'irrigation':
        return Icons.water_drop;
      case 'planting':
        return Icons.grass;
      case 'pest':
        return Icons.bug_report;
      case 'fieldwork':
      default:
        return Icons.agriculture;
    }
  }
}

