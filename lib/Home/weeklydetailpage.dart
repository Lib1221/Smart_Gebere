import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_gebere/geo_Location/wetherdata.dart';
import 'package:smart_gebere/l10n/app_localizations.dart';

class WeekDetailPage extends StatefulWidget {
  final Map<String, dynamic> week;

  const WeekDetailPage({super.key, required this.week});

  @override
  State<WeekDetailPage> createState() => _WeekDetailPageState();
}

class _WeekDetailPageState extends State<WeekDetailPage>
    with SingleTickerProviderStateMixin {
  bool isLoading = false;
  List<Map<String, dynamic>> weatherData = [];
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  Set<int> _completedTasks = {};

  final WeatherDataFetcher weatherService = WeatherDataFetcher();

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
    loadWeather();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> loadWeather() async {
    if (weatherData.isEmpty) {
      setState(() => isLoading = true);

      try {
        final fetchedData = await weatherService.fetchWeather();
        if (mounted) {
          setState(() {
            weatherData = fetchedData;
            isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    }
  }

  String getWeatherEmoji(String code) {
    switch (code) {
      case "0": return "☀️";
      case "1": return "⛅";
      case "2": return "☁️";
      case "3": return "🌥️";
      case "45": return "🌫️";
      case "48": return "❄️";
      case "51": case "53": case "55": return "🌦️";
      case "56": case "57": return "❄️";
      case "61": case "63": case "65": return "🌧️";
      case "66": case "67": return "❄️";
      case "71": case "73": case "75": case "77": return "❄️";
      case "80": case "81": case "82": return "🌧️";
      case "85": case "86": return "❄️";
      case "95": case "96": case "99": return "🌩️";
      default: return "🌤️";
    }
  }

  Color _getWeatherColor(String code) {
    final int c = int.tryParse(code) ?? 0;
    if (c == 0) return const Color(0xFFFF9800);
    if (c <= 3) return const Color(0xFF2196F3);
    if (c <= 48) return const Color(0xFF9E9E9E);
    if (c <= 67) return const Color(0xFF42A5F5);
    if (c <= 86) return const Color(0xFF90CAF9);
    return const Color(0xFFE91E63);
  }

  Color _getStageColor(String stage) {
    final lower = stage.toLowerCase();
    if (lower.contains('preparation')) return const Color(0xFF795548);
    if (lower.contains('planting') || lower.contains('sowing')) return const Color(0xFF4CAF50);
    if (lower.contains('growth') || lower.contains('vegetative')) return const Color(0xFF8BC34A);
    if (lower.contains('flower')) return const Color(0xFFE91E63);
    if (lower.contains('harvest')) return const Color(0xFFFF9800);
    if (lower.contains('care') || lower.contains('maintenance')) return const Color(0xFF2196F3);
    return const Color(0xFF009688);
  }

  @override
  Widget build(BuildContext context) {
    final weekNum = widget.week['week']?.toString() ?? '1';
    final stage = widget.week['stage']?.toString() ?? 'Development Stage';
    final stageColor = _getStageColor(stage);
    final tasks = widget.week['tasks'] as List<dynamic>? ?? [];
    final dateRange = widget.week['dateRange'] as List<dynamic>?;
    String dateText = '';
    if (dateRange != null && dateRange.length >= 2) {
      dateText = '${dateRange[0]} - ${dateRange[1]}';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: stageColor,
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
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [stageColor.withOpacity(0.8), stageColor],
                        ),
                      ),
                    ),
                    // Pattern
                    Positioned(
                      right: -30,
                      bottom: -30,
                      child: Icon(
                        Icons.calendar_today,
                        size: 180,
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Week $weekNum',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              stage,
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (dateText.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.date_range,
                                      color: Colors.white70, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    dateText,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Weather Section
                    _buildWeatherSection(stageColor),
                    const SizedBox(height: 24),

                    // Tasks Section
                    _buildTasksSection(tasks, stageColor),
                    const SizedBox(height: 24),

                    // Tips Section
                    _buildTipsSection(stage, stageColor),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherSection(Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.cloud, color: Color(0xFF2196F3)),
              ),
              const SizedBox(width: 12),
              Text(
                'Weather Forecast',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (weatherData.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.cloud_off, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'Weather data unavailable',
                      style: GoogleFonts.poppins(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: weatherData.length > 7 ? 7 : weatherData.length,
                itemBuilder: (context, index) {
                  final data = weatherData[index];
                  String weatherCode = data['weathercode'].toString();
                  String weatherEmoji = getWeatherEmoji(weatherCode);
                  Color weatherColor = _getWeatherColor(weatherCode);

                  return Container(
                    width: 90,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          weatherColor.withOpacity(0.1),
                          weatherColor.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: weatherColor.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          data['day'].toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          weatherEmoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${data['min_temp']}°',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              ' / ',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                            Text(
                              '${data['max_temp']}°',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTasksSection(List<dynamic> tasks, Color accentColor) {
    final completedCount = _completedTasks.length;
    final totalCount = tasks.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.checklist, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tasks for This Week',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      '$completedCount of $totalCount completed',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              // Progress indicator
              SizedBox(
                width: 50,
                height: 50,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 5,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
          const SizedBox(height: 20),
          // Tasks list
          ...tasks.asMap().entries.map((entry) {
            final index = entry.key;
            final task = entry.value.toString();
            final isCompleted = _completedTasks.contains(index);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isCompleted) {
                    _completedTasks.remove(index);
                  } else {
                    _completedTasks.add(index);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? accentColor.withOpacity(0.1)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isCompleted
                        ? accentColor.withOpacity(0.3)
                        : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    // Checkbox
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isCompleted ? accentColor : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCompleted ? accentColor : Colors.grey[400]!,
                          width: 2,
                        ),
                        boxShadow: isCompleted
                            ? [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.4),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    // Task text
                    Expanded(
                      child: Text(
                        task,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isCompleted ? Colors.grey[500] : Colors.grey[800],
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTipsSection(String stage, Color accentColor) {
    final tips = _getTipsForStage(stage);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor.withOpacity(0.8), accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lightbulb_outline, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                'Farming Tips',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tip,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  List<String> _getTipsForStage(String stage) {
    final lower = stage.toLowerCase();
    
    if (lower.contains('preparation')) {
      return [
        'Test soil pH levels before planting',
        'Remove weeds and debris from the field',
        'Add organic compost to improve soil fertility',
        'Ensure proper drainage in the field',
      ];
    } else if (lower.contains('planting') || lower.contains('sowing')) {
      return [
        'Plant seeds at the recommended depth',
        'Maintain proper spacing between plants',
        'Water immediately after planting',
        'Consider weather conditions before planting',
      ];
    } else if (lower.contains('growth') || lower.contains('vegetative')) {
      return [
        'Monitor plant health regularly',
        'Apply fertilizer as needed',
        'Watch for pest infestations',
        'Ensure adequate water supply',
      ];
    } else if (lower.contains('flower')) {
      return [
        'Avoid excessive nitrogen during flowering',
        'Ensure pollination is occurring',
        'Protect flowers from harsh weather',
        'Monitor for flower-eating pests',
      ];
    } else if (lower.contains('harvest')) {
      return [
        'Harvest at the right maturity stage',
        'Use proper harvesting techniques',
        'Handle produce carefully to avoid damage',
        'Store harvested crops properly',
      ];
    }
    
    return [
      'Monitor your crops regularly',
      'Keep the field free of weeds',
      'Ensure proper irrigation',
      'Check for signs of disease or pests',
    ];
  }
}
