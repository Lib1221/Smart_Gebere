import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:smart_gebere/geo_Location/location.dart';

class CropSuggestionPage extends StatefulWidget {
  @override
  _CropSuggestionPageState createState() => _CropSuggestionPageState();
}

class _CropSuggestionPageState extends State<CropSuggestionPage> {
  late GenerativeModel? _model;
  String suggestionText = '';
  bool _isLoading = false;
  String datavalue = '';
  String locationData = '';

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  void _initializeModel() {
    String apiKey = dotenv.env['API_KEY'] ?? 'No API Key Found';

    if (apiKey.isEmpty) {
      setState(() {
        suggestionText = "API Key is missing. Please set it in the code.";
      });
      return;
    }

    _model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: apiKey,
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
      ],
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationService locationService = LocationService();
      var location = await locationService.getCurrentLocation();
      
      setState(() {
        locationData = 'Latitude: ${location['latitude']}, Longitude: ${location['longitude']}, Elevation: ${location['elevation']}, Weather: ${location['weather']['weather']}, Temperature: ${location['weather']['temperature']}°C';
      });
    } catch (e) {
      setState(() {
        locationData = 'Error fetching location: $e';
      });
    }
  }

  void _generateCropSuggestions() async {
    if (_model == null) {
      setState(() {
        suggestionText = "Model is not initialized. Check your API key.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String prompt = """
    Based on the following location data, please determine the current season for this area:
    Location Data: $locationData
    
    Consider factors like latitude, longitude, typical climate, and any other relevant data to determine the season.
    The season should be one of the following: Winter, Spring, Summer, or Fall.
    
    Please provide the current season for the location.

    Additionally, based on the location data and season, suggest the best crops to grow in this area. Provide the following details in a dictionary format:
    
    1. Crop Name
    2. Sustainability Description (Why it is sustainable in this area considering the season)
    3. Why it is suitable for the location (soil, climate, season, and other factors)
    4. Best Season for Planting
    
    Format:
    [
      {
        "crop_name": "Crop 1",
        "sustainability_description": "Description of sustainability for Crop 1",
        "why_suitable": "Reasons why Crop 1 is suitable for this location and season",
        "best_season_for_planting": "Best season for planting Crop 1"
      },
      {
        "crop_name": "Crop 2",
        "sustainability_description": "Description of sustainability for Crop 2",
        "why_suitable": "Reasons why Crop 2 is suitable for this location and season",
        "best_season_for_planting": "Best season for planting Crop 2"
      }
    ]
    Return the crops in a list of dictionaries format based on the location and inferred season.
    $datavalue
    """;

    final content = [
      Content.multi([TextPart(prompt)]),
    ];

    try {
      final response = await _model!.generateContent(content);
      setState(() {
        suggestionText = response.text ?? "No response generated.";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        suggestionText = "Failed to generate response: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Suggestions'),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      await _getCurrentLocation();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 15.0),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Get Current Location'),
            ),
            const SizedBox(height: 20.0),

            if (locationData.isNotEmpty)
              Text(
                'Location: $locationData',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            
            const SizedBox(height: 20.0),
            
            TextField(
              decoration: const InputDecoration(
                labelText: 'Enter additional conditions (e.g., soil type)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              onChanged: (value) {
                setState(() {
                  datavalue = value;
                });
              },
            ),
            const SizedBox(height: 20.0),

            ElevatedButton(
              onPressed: _isLoading || locationData.isEmpty
                  ? null
                  : _generateCropSuggestions,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 15.0),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Get Crop Suggestions'),
            ),
            const SizedBox(height: 20.0),

            if (suggestionText.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    suggestionText,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
