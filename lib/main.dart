// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:smart_gebere/firebase_options.dart';
// import 'package:smart_gebere/scheduling/schedule.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   ); // Ensure Firebase is initialized

//   runApp(MyApp()); // Run the app
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(title: const Text("Farming Guide")),
//         body: FutureBuilder<void>(
//           future: retrieveFarmingGuideForUser(), // Call the function to retrieve data
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             } else if (snapshot.hasError) {
//               return Center(child: Text('Error: ${snapshot.error}'));
//             } else {
//               return const Center(child: Text("Farming guide data loaded."));
//             }
//           },
//         ),
//       ),
//     );
//   }
// }

// Future<void> retrieveFarmingGuideForUser() async {
//   try {
//     User? user = FirebaseAuth.instance.currentUser;

//     if (user == null) {
//       print('No authenticated user found.');
//       return;
//     }

//     String uid = user.uid;
//     FirebaseFirestore firestore = FirebaseFirestore.instance;

//     // Get reference to the user's document in Firestore
//     DocumentReference userDocRef = firestore.collection('Farmers').doc(uid);

//     // Fetch the farming guide data stored under the user's document
//     DocumentSnapshot userDocSnapshot = await userDocRef.get();

//     if (userDocSnapshot.exists) {
//       var farmingGuideData = (userDocSnapshot.data() as Map<String, dynamic>)['farmingGuide'];

//       if (farmingGuideData != null && farmingGuideData['weeks'] != null) {
//         List<WeekTask> farmingGuide = [];

//         for (var weekData in farmingGuideData['weeks']) {
//           // Convert the data back to WeekTask objects
//           WeekTask weekTask = WeekTask.fromJson(weekData);
//           farmingGuide.add(weekTask);
//         }

//         // Display the retrieved data in the console
//         print("Retrieved Farming Guide:");
//         for (var week in farmingGuide) {
//           print("Week: ${week.week}, Stage: ${week.stage}");
//         }
//       } else {
//         print("No farming guide or weeks found.");
//       }
//     } else {
//       print("User document does not exist.");
//     }
//   } catch (e) {
//     print("Error retrieving farming guide data: $e");
//   }
// }



import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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



// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'firebase_options.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Retrieve Farming Data',
//       theme: ThemeData(primarySwatch: Colors.green),
//       home: RetrieveFarmingDataPage(),
//     );
//   }
// }

// class RetrieveFarmingDataPage extends StatefulWidget {
//   @override
//   _RetrieveFarmingDataPageState createState() =>
//       _RetrieveFarmingDataPageState();
// }

// class _RetrieveFarmingDataPageState extends State<RetrieveFarmingDataPage> {
//   Future<List<Map<String, dynamic>>> fetchData() async {
//     String? uid = FirebaseAuth.instance.currentUser?.uid;
//     if (uid == null) {
//       print("No authenticated user.");
//       return [];
//     }

//     FirebaseFirestore firestore = FirebaseFirestore.instance;
//     CollectionReference farmingGuides =
//         firestore.collection('Farmers').doc(uid).collection('farming_guides');

//     QuerySnapshot cropSnapshot = await farmingGuides.get();

//     // Print out the fetched crops
//     print("Fetched crops: ${cropSnapshot.docs.length}");

//     List<Map<String, dynamic>> cropData = [];

//     for (var cropDoc in cropSnapshot.docs) {
//       // The crop name is the document ID, e.g., 'barley', 'teff'
//       print("Crop: ${cropDoc.id}");

//       Map<String, dynamic> cropInfo = {
//         "crop": cropDoc.id,
//         "weeks": []
//       };

//       CollectionReference weeks =
//           farmingGuides.doc(cropDoc.id).collection('weeks');
//       QuerySnapshot weekSnapshot = await weeks.get();

//       // Print out the fetched weeks for each crop
//       print("Weeks for ${cropDoc.id}: ${weekSnapshot.docs.length}");

//       for (var weekDoc in weekSnapshot.docs) {
//         cropInfo["weeks"].add(weekDoc.data());
//       }

//       cropData.add(cropInfo);
//     }

//     print("Final crop data: $cropData"); // Debugging final data
//     return cropData;
//   }

//   @override
//   void initState() {
//     super.initState();
//     fetchData(); // Fetch and print data when the page loads
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Retrieve Farming Data")),
//       body: FutureBuilder<List<Map<String, dynamic>>>( 
//         future: fetchData(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
//             return const Center(child: Text("No crops found."));
//           }

//           return ListView.builder(
//             itemCount: snapshot.data!.length,
//             itemBuilder: (context, index) {
//               var crop = snapshot.data![index];
//               return ListTile(
//                 title: Text(crop['crop'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                 leading: const Icon(Icons.agriculture, color: Colors.green),
//                 subtitle: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     ...crop['weeks'].map<Widget>((week) {
//                       return Text("Week: ${week}");
//                     }).toList()
//                   ],
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }







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
