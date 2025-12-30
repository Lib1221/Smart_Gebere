import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_gebere/Home/Home.dart';
import 'package:smart_gebere/Home/weeklydetailpage.dart';

class CropDetailPage extends StatefulWidget {
  final Map<String, dynamic> event;

  const CropDetailPage({super.key, required this.event});

  @override
  State<CropDetailPage> createState() => _CropDetailPageState();
}

class _CropDetailPageState extends State<CropDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  int? _expandedWeekIndex;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _getStageColor(String stage) {
    final lower = stage.toLowerCase();
    if (lower.contains('preparation') || lower.contains('ዝግጅት')) {
      return const Color(0xFF795548);
    } else if (lower.contains('planting') || lower.contains('sowing') || lower.contains('መዝራት')) {
      return const Color(0xFF4CAF50);
    } else if (lower.contains('growth') || lower.contains('vegetative') || lower.contains('እድገት')) {
      return const Color(0xFF8BC34A);
    } else if (lower.contains('flower') || lower.contains('አበባ')) {
      return const Color(0xFFE91E63);
    } else if (lower.contains('harvest') || lower.contains('ምርት')) {
      return const Color(0xFFFF9800);
    } else if (lower.contains('care') || lower.contains('maintenance')) {
      return const Color(0xFF2196F3);
    }
    return const Color(0xFF009688);
  }

  IconData _getStageIcon(String stage) {
    final lower = stage.toLowerCase();
    if (lower.contains('preparation')) return Icons.construction;
    if (lower.contains('planting') || lower.contains('sowing')) return Icons.grass;
    if (lower.contains('growth') || lower.contains('vegetative')) return Icons.trending_up;
    if (lower.contains('flower')) return Icons.local_florist;
    if (lower.contains('harvest')) return Icons.agriculture;
    if (lower.contains('care') || lower.contains('maintenance')) return Icons.eco;
    return Icons.check_circle_outline;
  }

  int _getCurrentWeekIndex() {
    final weeks = widget.event['weeks'] as List? ?? [];
    final now = DateTime.now();
    for (int i = 0; i < weeks.length; i++) {
      final dateRange = weeks[i]['dateRange'] as List<dynamic>?;
      if (dateRange != null && dateRange.length >= 2) {
        final start = DateTime.tryParse(dateRange[0].toString());
        final end = DateTime.tryParse(dateRange[1].toString());
        if (start != null && end != null) {
          if (now.isAfter(start.subtract(const Duration(days: 1))) &&
              now.isBefore(end.add(const Duration(days: 1)))) {
            return i;
          }
        }
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final cropName = widget.event['cropName'] ?? 'Crop';
    final progressPercentage = widget.event['progressPercentage'] ?? 0;
    final daysSincePlanted = widget.event['daysSinceFirstPlanting'] ?? 0;
    final weeks = widget.event['weeks'] as List? ?? [];
    final currentWeekIndex = _getCurrentWeekIndex();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Beautiful App Bar with Crop Info
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: const Color(0xFF2E7D32),
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.share, color: Colors.white, size: 20),
                  ),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                  ),
                  onPressed: () => _showDeleteConfirmation(context),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gradient background
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                        ),
                      ),
                    ),
                    // Pattern overlay
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Icon(
                        Icons.eco,
                        size: 250,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    // Content
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Crop icon
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.eco,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Crop name
                            Text(
                              cropName,
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Stats row
                            Row(
                              children: [
                                _buildHeaderStat(
                                  icon: Icons.calendar_today,
                                  value: '$daysSincePlanted',
                                  label: 'days',
                                ),
                                const SizedBox(width: 20),
                                _buildHeaderStat(
                                  icon: Icons.layers,
                                  value: '${weeks.length}',
                                  label: 'weeks',
                                ),
                                const SizedBox(width: 20),
                                _buildHeaderStat(
                                  icon: Icons.trending_up,
                                  value: '$progressPercentage%',
                                  label: 'progress',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Progress Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress Card
                    _buildProgressCard(progressPercentage, weeks.length, currentWeekIndex),
                    const SizedBox(height: 24),

                    // Weeks Timeline
                    Text(
                      'Development Stages',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Weeks List
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final week = weeks[index];
                  final isCurrentWeek = index == currentWeekIndex;
                  final isExpanded = _expandedWeekIndex == index;
                  
                  return _buildWeekCard(
                    week: week,
                    index: index,
                    totalWeeks: weeks.length,
                    isCurrentWeek: isCurrentWeek,
                    isExpanded: isExpanded,
                  );
                },
                childCount: weeks.length,
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(int progress, int totalWeeks, int currentWeek) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF43A047), const Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF43A047).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Circular progress
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: progress / 100,
                        strokeWidth: 10,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$progress%',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Complete',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Progress',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildProgressStat(
                      'Current Week',
                      '${currentWeek + 1} of $totalWeeks',
                      Icons.calendar_today,
                    ),
                    const SizedBox(height: 8),
                    _buildProgressStat(
                      'Weeks Remaining',
                      '${totalWeeks - currentWeek - 1}',
                      Icons.timelapse,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekCard({
    required Map<String, dynamic> week,
    required int index,
    required int totalWeeks,
    required bool isCurrentWeek,
    required bool isExpanded,
  }) {
    final stage = week['stage']?.toString() ?? 'Stage ${index + 1}';
    final stageColor = _getStageColor(stage);
    final stageIcon = _getStageIcon(stage);
    final tasks = week['tasks'] as List<dynamic>? ?? [];
    final dateRange = week['dateRange'] as List<dynamic>?;
    String dateText = '';
    if (dateRange != null && dateRange.length >= 2) {
      dateText = '${dateRange[0]} - ${dateRange[1]}';
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedWeekIndex = isExpanded ? null : index;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isCurrentWeek
              ? Border.all(color: stageColor, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: isCurrentWeek
                  ? stageColor.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isCurrentWeek ? 15 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Week header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Week indicator
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [stageColor.withOpacity(0.8), stageColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: stageColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Week info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Week ${index + 1}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                            if (isCurrentWeek) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: stageColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'CURRENT',
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: stageColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(stageIcon, size: 14, color: stageColor),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                stage,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: stageColor,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Task count & expand icon
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${tasks.length} tasks',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 200),
                        turns: isExpanded ? 0.5 : 0,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Expanded content
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date range
                    if (dateText.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.date_range,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Text(
                              dateText,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Tasks list
                    ...tasks.asMap().entries.map((entry) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: stageColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: stageColor.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: stageColor.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: stageColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.value.toString(),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    // View details button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WeekDetailPage(week: week),
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('View Full Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: stageColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCrop(BuildContext context, String cropId) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackbar(context, 'No authenticated user found.', isError: true);
        return;
      }

      String uid = user.uid;
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentReference userDocRef = firestore.collection('Farmers').doc(uid);

      DocumentSnapshot userDoc = await userDocRef.get();
      if (!userDoc.exists || !(userDoc.data() as Map<String, dynamic>).containsKey('crops')) {
        _showSnackbar(context, 'No crops found to delete.', isError: true);
        return;
      }

      List<dynamic> crops = List.from(userDoc['crops']);
      crops.removeWhere((crop) => crop['id'] == cropId);

      await userDocRef.update({'crops': crops});

      _showSnackbar(context, 'Crop deleted successfully!');
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Home_Screen()),
          (route) => false,
        );
      }
    } catch (e) {
      _showSnackbar(context, 'Failed to delete crop: $e', isError: true);
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline, color: Colors.red),
              ),
              const SizedBox(width: 12),
              Text(
                'Delete Crop',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${widget.event['cropName']}"? This action cannot be undone.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteCrop(context, widget.event['id']);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showSnackbar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
