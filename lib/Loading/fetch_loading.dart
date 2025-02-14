// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:smart_gebere/task_management/list_suggestion.dart';
// import 'dart:async';
// import 'package:animated_text_kit/animated_text_kit.dart';

// class LoadingPage extends StatefulWidget {
//   @override
//   _LoadingPageState createState() => _LoadingPageState();
// }

// class _LoadingPageState extends State<LoadingPage> {
//   // List of tasks with title and status
//   List<Map<String, dynamic>> tasks = [
//     {'title': 'Fetching location data', 'completed': false, 'progress': 0.0},
//     {'title': 'Fetching elevation data', 'completed': false, 'progress': 0.0},
//     {'title': 'Fetching weather data', 'completed': false, 'progress': 0.0},
//     {'title': 'Analyzing data', 'completed': false, 'progress': 0.0},
//     {'title': 'Choosing the best option', 'completed': false, 'progress': 0.0},
//   ];

//   int currentTaskIndex = 0;
//   Timer? _timer;

//   @override
//   void initState() {
//     super.initState();
//     _simulateLoading();
//   }

//   // Function to simulate task completion with progress update
//   void _simulateLoading() {
//     _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
//       if (!mounted) {
//         timer.cancel(); // Cancel the timer if the widget is not mounted
//         return;
//       }

//       if (currentTaskIndex < tasks.length) {
//         setState(() {
//           tasks[currentTaskIndex]['progress'] = (currentTaskIndex + 1) * 0.2; // Update progress
//           tasks[currentTaskIndex]['completed'] = true;
//           currentTaskIndex++;
//         });
//       } else {
//         timer.cancel(); // Stop the timer once all tasks are done
//         Future.delayed(const Duration(seconds: 2), () {
//           if (mounted) { // Ensure the widget is still mounted before navigation
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (context) => CropListPage()), // Navigate to CropListPage
//             );
//           }
//         });
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _timer?.cancel(); // Cancel the timer when the widget is disposed
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.green[50], // Soft green background
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             // Plant Icon
//             Icon(
//               Icons.nature, // Simple plant icon
//               size: 80,
//               color: Colors.green[700],
//             ),
//             const SizedBox(height: 20),

//             // Header text with animation
//             AnimatedTextKit(
//               animatedTexts: [
//                 FadeAnimatedText(
//                   'Processing Data...',
//                   duration: const Duration(seconds: 2),
//                   textStyle: GoogleFonts.roboto(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.green[700],
//                   ),
//                 ),
//               ],
//               isRepeatingAnimation: false,
//             ),
//             const SizedBox(height: 30),

//             // Animated progress bar (slower)
//             AnimatedContainer(
//               duration: const Duration(seconds: 2),
//               curve: Curves.easeInOut,
//               child: LinearProgressIndicator(
//                 value: tasks.isNotEmpty ? tasks[currentTaskIndex]['progress'] : 1.0,
//                 backgroundColor: Colors.green[100],
//                 color: Colors.green[700],
//               ),
//             ),
//             const SizedBox(height: 20),

//             // Animated Task Details with delay
//             Column(
//               children: tasks.map((task) {
//                 return AnimatedOpacity(
//                   opacity: task['completed'] ? 1.0 : 0.5,
//                   duration: const Duration(seconds: 1),
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20),
//                     child: Row(
//                       children: [
//                         Icon(
//                           task['completed'] ? Icons.check_circle : Icons.radio_button_unchecked,
//                           color: task['completed'] ? Colors.green : Colors.grey,
//                           size: 24,
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Text(
//                             task['title'],
//                             style: GoogleFonts.roboto(fontSize: 16, color: Colors.black87),
//                           ),
//                         ),
//                         // Show progress percentage for each task
//                         Text(
//                           "${(task['progress'] * 100).toStringAsFixed(0)}%",
//                           style: GoogleFonts.roboto(fontSize: 16, color: Colors.black87),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               }).toList(),
//             ),

//             const SizedBox(height: 20),

//             // Animated Text (Data Processing)
//             if (currentTaskIndex == tasks.length - 1)
//               AnimatedTextKit(
//                 animatedTexts: [
//                   FadeAnimatedText(
//                     'We are analyzing your data...',
//                     duration: const Duration(seconds: 2),
//                     textStyle: GoogleFonts.roboto(fontSize: 18, color: Colors.green[600]),
//                   ),
//                 ],
//                 isRepeatingAnimation: false,
//               ),
//             const SizedBox(height: 30),
//           ],
//         ),
//       ),
//     );
//   }
// }
