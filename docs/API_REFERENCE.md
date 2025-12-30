# API Reference

This document provides detailed information about the APIs and services used in Smart Gebere.

---

## Table of Contents

1. [Gemini AI API](#gemini-ai-api)
2. [OpenWeather API](#openweather-api)
3. [Open-Elevation API](#open-elevation-api)
4. [Firebase Services](#firebase-services)
5. [Internal Services](#internal-services)

---

## Gemini AI API

### Overview

Smart Gebere uses Google's Gemini AI for all artificial intelligence features including crop recommendations, disease detection, chat, and yield prediction.

### Configuration

```dart
final model = GenerativeModel(
  model: 'gemini-1.5-flash',
  apiKey: dotenv.env['API_KEY'],
  safetySettings: [
    SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
    SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
  ],
);
```

### Features Using Gemini

#### 1. Crop Recommendations

**Purpose:** Generate personalized crop suggestions based on location and environmental data.

**Input:**
```dart
String prompt = """
Based on the following location data, provide crop recommendations:
- Latitude: ${locationData['latitude']}
- Longitude: ${locationData['longitude']}
- Altitude: ${locationData['elevation']} meters
- Temperature: ${locationData['weather']['temperature']}°C
- Weather: ${locationData['weather']['weather']}

Field Information (optional):
- Field Name: ${fieldData['name']}
- Field Size: ${fieldData['areaHectares']} hectares
- Soil Type: ${fieldData['soilType']}

Provide a list of suitable crops with:
- name: Crop name
- description: Short description
- suitability: Percentage (0-100)
- details: Detailed analysis

Return as JSON array only.
Respond in ${language}.
""";
```

**Output Format:**
```json
[
  {
    "name": "Teff",
    "description": "A staple grain native to Ethiopia",
    "suitability": 95,
    "details": "Teff is ideal for this region due to..."
  }
]
```

#### 2. Disease Detection

**Purpose:** Analyze plant images to detect diseases and provide treatment recommendations.

**Input:**
```dart
final content = [
  Content.multi([
    TextPart("""
      Analyze this plant image and provide:
      1. Plant identification
      2. Disease/problem detection
      3. Severity (mild/moderate/severe)
      4. Treatment recommendations
      5. Prevention tips
      
      Respond in ${language}.
    """),
    DataPart('image/jpeg', imageBytes),
  ])
];
```

**Output Format:**
```json
{
  "plant": "Tomato",
  "disease": "Early Blight",
  "severity": "moderate",
  "confidence": 85,
  "treatment": [
    "Remove infected leaves",
    "Apply copper-based fungicide"
  ],
  "prevention": [
    "Ensure proper spacing",
    "Water at soil level"
  ]
}
```

#### 3. Crop Planning

**Purpose:** Generate week-by-week farming guides.

**Input:**
```dart
String prompt = """
Provide a week-by-week planting guide for ${crop}:
- Today's date: ${DateTime.now()}
- Field Size: ${fieldData['areaHectares']} hectares
- Soil Type: ${fieldData['soilType']}

Include for each week:
- week: Week number
- date_range: [start_date, end_date]
- stage: Farming stage
- tasks: List of specific tasks

Respond in ${language}.
""";
```

**Output Format:**
```json
[
  {
    "week": 1,
    "date_range": ["2025-01-01", "2025-01-07"],
    "stage": "Land Preparation",
    "tasks": [
      "Test soil pH",
      "Plow to 15cm depth",
      "Add organic compost"
    ]
  }
]
```

#### 4. AI Crop Doctor Chat

**Purpose:** Interactive chat for farming questions.

**System Instruction:**
```dart
Content.text('''
You are an expert agricultural advisor for Ethiopian farmers.
Your role:
- Diagnose plant diseases
- Provide pest control solutions (prefer organic)
- Advise on irrigation, fertilization, soil
- Recommend planting schedules
- Answer crop-specific questions

Guidelines:
- Give practical, actionable advice
- Consider Ethiopian climate
- Suggest locally available solutions
- If unsure, recommend local experts
''')
```

#### 5. Yield Prediction

**Purpose:** Predict harvest yield and market value.

**Input:**
```dart
String prompt = """
Predict yield for this Ethiopian crop:
- Crop: ${cropName}
- Land Size: ${landSize} ${landUnit}
- Growing Period: ${weeks.length} weeks
- Seed Amount: ${seedAmount}
- Fertilizer: ${fertilizer}

Provide JSON response:
{
  "estimated_yield_min": <kg>,
  "estimated_yield_max": <kg>,
  "yield_per_hectare": <kg>,
  "confidence_percentage": <0-100>,
  "market_value_estimate_min": <ETB>,
  "market_value_estimate_max": <ETB>,
  "harvest_quality_prediction": "excellent/good/average",
  "optimal_harvest_timing": "description",
  "factors_affecting_yield": ["factor1", ...],
  "recommendations": ["rec1", ...]
}
""";
```

### Error Handling

```dart
try {
  response = await model.generateContent(content);
} catch (e) {
  final msg = e.toString();
  if (msg.contains('is not found') || msg.contains('not supported')) {
    // Fallback to stable model
    model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    response = await model.generateContent(content);
  } else {
    rethrow;
  }
}
```

### Rate Limits

- Free tier: 15 requests/minute
- Paid tier: Variable based on plan
- Implement retry logic for 429 errors

---

## OpenWeather API

### Overview

Provides real-time weather data for the farmer's location.

### Endpoint

```
GET https://api.openweathermap.org/data/2.5/weather
```

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `lat` | float | Latitude |
| `lon` | float | Longitude |
| `appid` | string | API key |
| `units` | string | `metric` for Celsius |

### Request Example

```dart
final weatherUrl = Uri.parse(
  'https://api.openweathermap.org/data/2.5/weather'
  '?lat=$lat&lon=$lon&appid=$apiKey&units=metric'
);

final response = await http.get(weatherUrl);
```

### Response Example

```json
{
  "coord": {
    "lon": 38.75,
    "lat": 9.0
  },
  "weather": [
    {
      "id": 800,
      "main": "Clear",
      "description": "clear sky",
      "icon": "01d"
    }
  ],
  "main": {
    "temp": 25.5,
    "feels_like": 24.8,
    "temp_min": 24.0,
    "temp_max": 27.0,
    "pressure": 1015,
    "humidity": 45
  },
  "wind": {
    "speed": 3.5,
    "deg": 180
  },
  "name": "Addis Ababa"
}
```

### Data Extraction

```dart
Map<String, dynamic> getWeather(response) {
  var json = jsonDecode(response.body);
  return {
    "temperature": json['main']['temp'],
    "humidity": json['main']['humidity'],
    "weather": json['weather'][0]['description'],
  };
}
```

---

## Open-Elevation API

### Overview

Provides elevation data based on GPS coordinates.

### Endpoint

```
POST https://api.open-elevation.com/api/v1/lookup
```

### Request

```dart
final response = await http.post(
  Uri.parse('https://api.open-elevation.com/api/v1/lookup'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    "locations": [
      {"latitude": lat, "longitude": lon}
    ]
  }),
);
```

### Response

```json
{
  "results": [
    {
      "latitude": 9.0,
      "longitude": 38.75,
      "elevation": 2355
    }
  ]
}
```

### Notes

- Free to use, no API key required
- May have occasional downtime
- Consider caching elevation data

---

## Firebase Services

### Firebase Authentication

#### Sign Up

```dart
UserCredential credential = await FirebaseAuth.instance
    .createUserWithEmailAndPassword(
  email: email,
  password: password,
);
String uid = credential.user!.uid;
```

#### Sign In

```dart
UserCredential credential = await FirebaseAuth.instance
    .signInWithEmailAndPassword(
  email: email,
  password: password,
);
```

#### Sign Out

```dart
await FirebaseAuth.instance.signOut();
```

#### Auth State

```dart
FirebaseAuth.instance.authStateChanges().listen((User? user) {
  if (user == null) {
    // User signed out
  } else {
    // User signed in
  }
});
```

### Cloud Firestore

#### Collection Structure

```
Firestore Database
├── Farmers/{userId}
│   ├── name: string
│   ├── phone: string
│   ├── region: string
│   ├── fields: array<Field>
│   └── crops: array<Crop>
│
├── users/{userId}
│   ├── email: string
│   ├── createdAt: timestamp
│   └── settings: map
│
└── content/{docId}
    ├── title: string
    ├── body: string
    └── category: string
```

#### Read Document

```dart
DocumentSnapshot doc = await FirebaseFirestore.instance
    .collection('Farmers')
    .doc(userId)
    .get();

if (doc.exists) {
  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
}
```

#### Write Document

```dart
await FirebaseFirestore.instance
    .collection('Farmers')
    .doc(userId)
    .set({
  'crops': FieldValue.arrayUnion([cropData]),
}, SetOptions(merge: true));
```

#### Update Document

```dart
await FirebaseFirestore.instance
    .collection('Farmers')
    .doc(userId)
    .update({
  'crops': updatedCrops,
});
```

#### Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /Farmers/{userId} {
      allow read, write: if request.auth != null 
                         && request.auth.uid == userId;
    }
  }
}
```

---

## Internal Services

### LocationService

**File:** `lib/geo_Location/location.dart`

```dart
class LocationService {
  // Get comprehensive location data
  Future<Map<String, dynamic>> getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition();
    double elevation = await getElevation(
      position.latitude, 
      position.longitude
    );
    Map<String, dynamic> weather = await getWeather(
      position.latitude, 
      position.longitude
    );
    
    return {
      "latitude": position.latitude,
      "longitude": position.longitude,
      "elevation": elevation,
      "weather": weather,
    };
  }
  
  // Generate AI crop suggestions
  Future<List<Map<String, dynamic>>> generateCropSuggestions(
    Map<String, dynamic> locationData, {
    Map<String, dynamic>? fieldData,
  });
}
```

### ConnectivityService

**File:** `lib/core/services/connectivity_service.dart`

```dart
abstract class ConnectivityService {
  // Stream of connectivity changes
  Stream<bool> get onConnectivityChanged;
  
  // Check current status
  Future<bool> isConnected();
}

// Usage
final connectivity = getConnectivityService();
connectivity.onConnectivityChanged.listen((isConnected) {
  if (!isConnected) {
    showOfflineIndicator();
  }
});
```

### OfflineStorage

**File:** `lib/core/services/offline_storage.dart`

```dart
class OfflineStorage {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox('smart_gebere');
  }
  
  static Future<void> saveCrops(List<Map<String, dynamic>> crops);
  static Future<List<Map<String, dynamic>>> getCrops();
  static Future<void> savePendingSync(Map<String, dynamic> data);
  static Future<List<Map<String, dynamic>>> getPendingSync();
  static Future<void> clearPendingSync();
}
```

### AppSettings

**File:** `lib/settings/app_settings.dart`

```dart
class AppSettings extends ChangeNotifier {
  Locale _locale = const Locale('en');
  
  Locale get locale => _locale;
  
  Future<void> loadSavedLocale() async {
    String code = await getLocaleStore().readLocaleCode();
    _locale = Locale(normalizeLocaleCode(code));
    notifyListeners();
  }
  
  Future<void> setLocale(Locale newLocale) async {
    _locale = newLocale;
    await getLocaleStore().writeLocaleCode(newLocale.languageCode);
    notifyListeners();
  }
  
  String aiLanguageName() {
    switch (_locale.languageCode) {
      case 'am': return 'Amharic';
      case 'om': return 'Afaan Oromo';
      default: return 'English';
    }
  }
}
```

---

## Error Codes

### Firebase Auth

| Code | Description | User Message |
|------|-------------|--------------|
| `user-not-found` | No account exists | "No account found with this email" |
| `wrong-password` | Incorrect password | "Incorrect password" |
| `email-already-in-use` | Email registered | "Email already registered" |
| `weak-password` | Password too weak | "Password must be 6+ characters" |

### Firestore

| Code | Description | Solution |
|------|-------------|----------|
| `permission-denied` | Security rules blocked | Check auth state, verify rules |
| `unavailable` | Network error | Check connectivity, retry |
| `not-found` | Document missing | Handle gracefully, create if needed |

### Gemini AI

| Error | Description | Solution |
|-------|-------------|----------|
| Model not found | Invalid model name | Fallback to `gemini-1.5-flash` |
| Rate limited | Too many requests | Implement exponential backoff |
| Safety blocked | Content flagged | Rephrase prompt |

---

## Best Practices

### API Calls

1. **Always check connectivity before API calls**
2. **Implement retry logic with exponential backoff**
3. **Cache responses where appropriate**
4. **Handle all error cases gracefully**
5. **Show loading states during API calls**

### Security

1. **Never hardcode API keys**
2. **Use environment variables**
3. **Validate all user input**
4. **Implement proper auth checks**
5. **Keep Firebase rules restrictive**

### Performance

1. **Paginate large data sets**
2. **Use Firestore indexes for queries**
3. **Compress images before upload**
4. **Cache AI responses when appropriate**
5. **Minimize API calls on startup**

---

*For more information, see the main [README.md](../README.md)*

