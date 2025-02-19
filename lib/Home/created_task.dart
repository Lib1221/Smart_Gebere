import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SlideableCreatedTasks extends StatefulWidget {
  @override
  _SlideableCreatedTasksState createState() => _SlideableCreatedTasksState();
}

class _SlideableCreatedTasksState extends State<SlideableCreatedTasks> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;

  List<Map<String, dynamic>> cropsData = [];

  @override
  void initState() {
    super.initState();
    _fetchCropsData();
  }

  Future<void> _fetchCropsData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String uid = user.uid;
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentReference userDocRef = firestore.collection('Farmers').doc(uid);

      DocumentSnapshot docSnapshot = await userDocRef.get();
      if (docSnapshot.exists) {
        var crops = docSnapshot['crops'] as List<dynamic>;
        setState(() {
          cropsData = crops
              .map((crop) => {
                    'cropName': crop['name'],
                    'id': crop['id'],
                    'weeks': crop['weeks']
                        .map((week) => {
                              'week': week['week'],
                              'dateRange': week['date_range'],
                              'stage': week['stage'],
                              'tasks': week['tasks'],
                            })
                        .toList(),
                  })
              .toList()
              .reversed
              .toList();
        });
      } else {
        setState(() {
          cropsData = [];
        });
      }
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (cropsData.isEmpty) _buildEmptyState(),
        if (cropsData.isNotEmpty)
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: (cropsData.length / 2).ceil(),
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, pageIndex) {
                var startIndex = pageIndex * 2;
                var crop1 = cropsData.length > startIndex ? cropsData[startIndex] : null;
                var crop2 = cropsData.length > startIndex + 1 ? cropsData[startIndex + 1] : null;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (crop1 != null)
                      Expanded(
                        child: _buildCard(crop1),
                      ),
                    if (crop2 != null)
                      Expanded(
                        child: _buildCard(crop2),
                      ),
                  ],
                );
              },
            ),
          ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            (cropsData.length / 2).ceil(),
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 10,
              width: _currentPage == index ? 12 : 8,
              decoration: BoxDecoration(
                color: _currentPage == index ? Colors.green.shade600 : Colors.green.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'No crops found. Please add crops.',
        style: TextStyle(fontSize: 18, color: Colors.green.shade700),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> event) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CropDetailPage(cropData: event),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade600, Colors.green.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              offset: const Offset(0, 6),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              event['cropName'],
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                event['weeks'].last['stage'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class CropDetailPage extends StatefulWidget {
  final Map<String, dynamic> cropData;

  const CropDetailPage({Key? key, required this.cropData}) : super(key: key);

  @override
  _CropDetailPageState createState() => _CropDetailPageState();
}

class _CropDetailPageState extends State<CropDetailPage> {
  late List<bool> taskCompletion;

  @override
  void initState() {
    super.initState();
    _loadTaskCompletion();
  }

  // Load the task completion states from SharedPreferences
  Future<void> _loadTaskCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    List<bool> loadedStates = [];
    for (int i = 0; i < widget.cropData['weeks'].length; i++) {
      String key = 'week_${i}_completed';
      loadedStates.add(prefs.getBool(key) ?? false); // Default to false if no value found
    }
    setState(() {
      taskCompletion = loadedStates;
    });
  }

  // Save the task completion state in SharedPreferences
  Future<void> _saveTaskCompletion(int weekIndex, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    String key = 'week_${weekIndex}_completed';
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade600,
        title: Text(
          widget.cropData['cropName'],
          style: GoogleFonts.lato(color: Colors.white),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: widget.cropData['weeks'].length,
          itemBuilder: (context, index) {
            var week = widget.cropData['weeks'][index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: TimelineTile(
                alignment: TimelineAlign.manual,
                lineXY: 0.1,
                indicatorStyle: IndicatorStyle(
                  width: 20,
                  color: Colors.green.shade600,
                  padding: const EdgeInsets.all(6),
                ),
                endChild: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.2),
                        offset: const Offset(0, 4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Week ${week['week']}: ${week['stage']}",
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Tasks:",
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...week['tasks'].map<Widget>((task) {
                        week['tasks'].indexOf(task);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Checkbox(
                                value: taskCompletion.length > index
                                    ? taskCompletion[index]
                                    : false,
                                onChanged: (bool? value) {
                                  setState(() {
                                    taskCompletion[index] = value ?? false;
                                  });
                                  _saveTaskCompletion(index, value ?? false);
                                },
                                activeColor: Colors.green.shade600,
                              ),
                              Text(
                                task,
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                isFirst: index == 0,
                isLast: index == widget.cropData['weeks'].length - 1,
              ),
            );
          },
        ),
      ),
    );
  }
}
