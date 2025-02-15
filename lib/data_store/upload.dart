import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_gebere/scheduling/schedule.dart';

Future<void> storeFarmingGuideForUser(List<WeekTask> farmingGuide) async {
  try {
    // Get the current user
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print("No authenticated user found.");
      return;
    }

    String uid = user.uid;
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    
    CollectionReference guidesCollection =
        firestore.collection('Farmers').doc(uid).collection('farming_guides');

    for (var week in farmingGuide) {
      await guidesCollection.add({
        'week': week.week,
        'date_range': week.dateRange,
        'stage': week.stage,
        'tasks': week.tasks,
        'created_at': FieldValue.serverTimestamp(),
      });
    }

    print("Farming guide stored successfully for user: $uid");
  } catch (e) {
    print("Error storing data: $e");
  }
}
