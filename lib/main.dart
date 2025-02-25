import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:smart_gebere/firebase_options.dart';
import 'package:smart_gebere/stream/stream_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Lock the orientation to **portrait mode only**
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamProviderClass(),
    ),
  );
}


// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:geolocator/geolocator.dart';
// import 'package:intl/intl.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Weather Forecast',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: WeatherScreen(),
//     );
//   }
// }

// class WeatherScreen extends StatefulWidget {
//   @override
//   _WeatherScreenState createState() => _WeatherScreenState();
// }

// class _WeatherScreenState extends State<WeatherScreen> {
//   List<dynamic> forecast = [];
//   bool isLoading = true;
//   double latitude = 0.0;
//   double longitude = 0.0;
//   final String apiKey = "	OmMZHyDcjE5ugeB0";

//   @override
//   void initState() {
//     super.initState();
//     getCurrentLocation();
//   }

//   Future<void> getCurrentLocation() async {
//     bool serviceEnabled;
//     LocationPermission permission;

//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       return;
//     }

//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.deniedForever) {
//         return;
//       }
//     }

//     Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
//     setState(() {
//       latitude = position.latitude;
//       longitude = position.longitude;
//       fetchWeather();
//     });
//   }

//   Future<void> fetchWeather() async {
//     final url = 'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&daily=temperature_2m_max,temperature_2m_min,weathercode&timezone=auto&apikey=$apiKey';
    
//     try {
//       final response = await http.get(Uri.parse(url));
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         setState(() {
//           forecast = List.generate(7, (index) => {
//             'date': data['daily']['time'][index],
//             'day': DateFormat('EEEE').format(DateTime.parse(data['daily']['time'][index])),
//             'max_temp': data['daily']['temperature_2m_max'][index],
//             'min_temp': data['daily']['temperature_2m_min'][index],
//             'weathercode': data['daily']['weathercode'][index],
//           });
//           isLoading = false;
//         });
//       } else {
//         throw Exception('Failed to load weather data');
//       }
//     } catch (e) {
//       print(e);
//       setState(() => isLoading = false);
//     }
//   }

//   @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     appBar: AppBar(title: Text("7-Day Weather Forecast")),
//     body: isLoading
//         ? Center(child: CircularProgressIndicator())
//         : ListView.builder(
//             itemCount: forecast.length,
//             itemBuilder: (context, index) {
//               final day = forecast[index];
//               String emoji = '';

//               // Adding weather emojis based on weather condition
//               switch (day['weather']) {
//                 case 'sunny':
//                   emoji = '☀️';
//                   break;
//                 case 'rainy':
//                   emoji = '🌧️';
//                   break;
//                 case 'cloudy':
//                   emoji = '☁️';
//                   break;
//                 default:
//                   emoji = '🌈';
//               }

//               return Card(
//                 margin: EdgeInsets.all(8.0),
//                 child: Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       // Weather Day and Date
//                       Expanded(
//                         child: Text(
//                           "${day['day']} (${day['date']})",
//                           style: const TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                       // Weather emoji
//                       Text(
//                         emoji,
//                         style: TextStyle(fontSize: 30),
//                       ),
//                       // Min and Max temperature
//                       Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text("Min: ${day['min_temp']}°C"),
//                           Text("Max: ${day['max_temp']}°C"),
//                         ],
//                       ),
//                       // Icon for weather
//                       Icon(Icons.wb_sunny, color: Colors.orange),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//   );
// }

// }




