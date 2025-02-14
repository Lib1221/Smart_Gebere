import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smart_gebere/firebase_options.dart';
import 'package:smart_gebere/stream/stream_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home:StreamProviderClass(),
    )
    );
}










// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter_dotenv/flutter_dotenv.dart';

// void main() async {
//   await dotenv.load(fileName: ".env"); // Load API Key
//   runApp(SoilApp());
// }

// class SoilApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Soil Data Finder',
//       theme: ThemeData(primarySwatch: Colors.green),
//       home: SoilDataScreen(),
//     );
//   }
// }

// class SoilDataScreen extends StatefulWidget {
//   @override
//   _SoilDataScreenState createState() => _SoilDataScreenState();
// }

// class _SoilDataScreenState extends State<SoilDataScreen> {
//   String _result = '';
//   bool _isLoading = false;

//   final String apiKey = dotenv.env['ISDA_API_KEY'] ?? '';

//   Future<void> _fetchSoilData() async {
//     String lat = "8.5145"; // Adama latitude
//     String lon = "39.2693"; // Adama longitude

//     setState(() => _isLoading = true);
//     String apiUrl =
//         "https://api.isda-africa.com/v1/soilproperty?key=$apiKey&lat=$lat&lon=$lon";

//     try {
//       final response = await http.get(Uri.parse(apiUrl));

//       if (response.statusCode == 200) {

//        final data = json.decode(response.body);
//         var soilProperties = data["property"];

// // Handle the case where data might be missing
// var aluminium = soilProperties["aluminium_extractable"]?[0]["value"] ?? "Data not available";
// var ph = soilProperties["ph_in_water"]?[0]["value"] ?? "Data not available";
// var nitrogen = soilProperties["nitrogen"]?[0]["value"] ?? "Data not available";
// var organicCarbon = soilProperties["organic_carbon"]?[0]["value"] ?? "Data not available";
// var phosphorus = soilProperties["phosphorus"]?[0]["value"] ?? "Data not available";
// var potassium = soilProperties["potassium"]?[0]["value"] ?? "Data not available";
// var magnesium = soilProperties["magnesium"]?[0]["value"] ?? "Data not available";
// var calcium = soilProperties["calcium"]?[0]["value"] ?? "Data not available";
// var sodium = soilProperties["sodium"]?[0]["value"] ?? "Data not available";
// var sulfur = soilProperties["sulfur"]?[0]["value"] ?? "Data not available";
// var soilTexture = soilProperties["soil_texture"] ?? "Data not available";
// var soilClass = soilProperties["soil_class"] ?? "Data not available";
// var soilFertility = soilProperties["soil_fertility"] ?? "Data not available";
// var depthRange = soilProperties["depth_range"] ?? "Data not available";
// var bulkDensity = soilProperties["bulk_density"] ?? "Data not available";

//       // Printing the extracted values vertically
//       print("Aluminium Extractable: $aluminium");
//       print("pH Level: $ph");
//       print("Nitrogen: $nitrogen");
//       print("Organic Carbon: $organicCarbon");
//       print("Phosphorus: $phosphorus");
//       print("Potassium: $potassium");
//       print("Magnesium: $magnesium");
//       print("Calcium: $calcium");
//       print("Sodium: $sodium");
//       print("Sulfur: $sulfur");
//       print("Soil Texture: $soilTexture");
//       print("Soil Class: $soilClass");
//       print("Soil Fertility: $soilFertility");
//       print("Depth Range: $depthRange");
//       print("Bulk Density: $bulkDensity");

//       } else {
//         setState(() => _result = "❌ Error: ${response.body}");
//       }
//     } catch (e) {
//       setState(() => _result = "⚠️ Failed to fetch data.");
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("ISDA Soil Data")),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             ElevatedButton(
//                 onPressed: _fetchSoilData, child: Text("Fetch Soil Data")),
//             SizedBox(height: 20),
//             _isLoading
//                 ? CircularProgressIndicator()
//                 : Text(_result,
//                     textAlign: TextAlign.left,
//                     style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.green)),
//           ],
//         ),
//       ),
//     );
//   }
// }
