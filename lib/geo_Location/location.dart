import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smart_gebere/settings/locale_store.dart';

class LocationService {
  GenerativeModel? _model;

  void _debugPrintAiResponse(String feature, String? text) {
    if (!kDebugMode) return;
    final safeText = (text ?? '').trim();
    final preview =
        safeText.length > 1200 ? '${safeText.substring(0, 1200)}…' : safeText;
    debugPrint('[$feature] AI response (${safeText.length} chars):\n$preview');
  }

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
    final elevationUrl =
        Uri.parse('https://api.open-elevation.com/api/v1/lookup');
    final response = await http.post(
      elevationUrl,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "locations": [
          {"latitude": lat, "longitude": lon}
        ]
      }),
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

  void initializeModel() {
    String apiKey = dotenv.env['API_KEY'] ?? '';
    final preferredModel = dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.5-flash';

    if (apiKey.isEmpty) {
      throw Exception("API Key is missing. Please set it in the .env file.");
    }

    _model = GenerativeModel(
      // Prefer the newest model if available; can be overridden via .env (GEMINI_MODEL).
      model: preferredModel,
      apiKey: apiKey,
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
      ],
    );
  }

  Future<String> _aiLanguageName() async {
    final code = normalizeLocaleCode(await getLocaleStore().readLocaleCode());
    switch (code) {
      case 'am':
        return 'Amharic';
      case 'om':
        return 'Afaan Oromo';
      default:
        return 'English';
    }
  }

  Future<List<Map<String, dynamic>>> generateCropSuggestions(
      Map<String, dynamic> locationData, {
    Map<String, dynamic>? fieldData,
  }) async {
    if (_model == null) {
      throw Exception("Model is not initialized. Check your API key.");
    }

    Map<String, dynamic> locationData = await getCurrentLocation();
    DateTime now = DateTime.now();
    final language = await _aiLanguageName();
    
    // Build field info if available
    String fieldInfo = '';
    if (fieldData != null) {
      fieldInfo = '''
### **Field Information:**
- **Field Name:** ${fieldData['name'] ?? 'Unnamed'}
- **Field Size:** ${fieldData['areaHectares']?.toStringAsFixed(2) ?? 'Unknown'} hectares
- **Soil Type:** ${fieldData['soilType'] ?? 'Unknown'}
''';
    }
    
    String prompt = """
Based on the following location data, provide a **detailed** and **well-researched** list of the most suitable crops for cultivation in this area. 
also analyse from these  ${now} extract data and and from location you could know the exact location then analyse in which season are in now
### **Location Data:**
- **Latitude:** ${locationData['latitude']}
- **Longitude:** ${locationData['longitude']}
- **altitude:** ${locationData['elevation']} meters
- **Current Temperature:** ${locationData['weather']['temperature']}°C
- **Current Weather:** ${locationData['weather']['weather']}

$fieldInfo

### **Analysis Criteria:**
For each crop, analyze its suitability based on the **climate, soil conditions, temperature tolerance, precipitation needs, and elevation factors**. The response should be **scientifically accurate** and consider agricultural best practices.

### **Output Format:**
Return a **list of dictionaries**, where each dictionary contains the following fields:

- **name:** The name of the crop.
- **description:** A short, informative description of the crop's main characteristics.
- **suitability:** A **percentage score (0-100)** indicating how well this crop can thrive in the given conditions.
- **details:** A detailed explanation covering:
  - **Climate Suitability:** Why the climate and temperature range are ideal.
  - **Soil Requirements:** The type of soil needed and whether the local soil supports it.
  - **Water Needs:** How rainfall or irrigation availability aligns with this crop’s water needs.
  - **Elevation Factor:** How the altitude affects its growth.
  - **Seasonal Growth Pattern:** The best season(s) for planting in this location.

### **Example Output:**
[
  {
    "name": "Corn",
    "description": "A high-yield cereal crop requiring full sunlight and well-drained soil.",
    "suitability": 85,
    "details": "Corn is well-suited to Adama's warm climate, as it requires temperatures between 20-30°C for optimal growth. The region’s elevation (2320m) provides cooler nights, which can enhance kernel development. Corn thrives in sandy loam soil with high nitrogen content, which is commonly found in Ethiopian farmlands. It has moderate water needs, making it ideal for areas with seasonal rainfall or irrigation access."
  },
  {
    "name": "Wheat",
    "description": "A staple grain with moderate water needs, suited for high-altitude regions.",
    "suitability": 90,
    "details": "Wheat is an excellent choice for Adama due to its ability to grow in cooler temperatures (15-25°C). The high elevation improves grain quality, preventing excessive heat stress. It requires well-drained loamy soil with good organic matter content. Wheat is best grown during the dry season with controlled irrigation."
  }
]

**Output:**
don't make it markdown text

Return the list of dictionaries only. Do not include any additional text or information before or after the list.

${'Respond in $language.'}
""";

    final content = [
      Content.multi([TextPart(prompt)])
    ];

    try {
      GenerateContentResponse response;
      try {
        response = await _model!.generateContent(content);
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('is not found') || msg.contains('not supported')) {
          debugPrint('[CropSuggestions] Preferred model unavailable; falling back to gemini-1.5-flash. Error: $e');
          final apiKey = dotenv.env['API_KEY'] ?? '';
          _model = GenerativeModel(
            model: 'gemini-1.5-flash',
            apiKey: apiKey,
            safetySettings: [
              SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
              SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
            ],
          );
          response = await _model!.generateContent(content);
        } else {
          rethrow;
        }
      }

      String? responseText = response.text;
      _debugPrintAiResponse('CropSuggestions', responseText);

      if (responseText!.isEmpty) {
        throw Exception("No response generated.");
      }

      List<Map<String, dynamic>> cropList =
          List<Map<String, dynamic>>.from(jsonDecode(responseText));
      return cropList;
    } catch (e) {
      throw Exception("Failed to generate response: $e");
    }
  }
}
