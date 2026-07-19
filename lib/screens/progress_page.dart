import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:fl_chart/fl_chart.dart'; 
import '../state/workout_state.dart';
import '../models/workout_models.dart';
import '../widgets/bouncing_widget.dart';

class ProgressPage extends StatefulWidget {
  final WorkoutState appState;

  const ProgressPage({super.key, required this.appState});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {

  String? _selectedDayFilter; 

  // THE FIX: Removed the static 'unit' parameter so the dialog can read it live
  void _showAddWeightDialog(BuildContext context, String exerciseName, bool isDark, Color dialogBg, Color textColor) {
    TextEditingController weightController = TextEditingController();
    
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7), 
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      transitionDuration: const Duration(milliseconds: 350), 
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return Transform.scale(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack).value,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        // THE FIX: ListenableBuilder allows the popup to instantly react to the toggle switch
        return ListenableBuilder(
          listenable: widget.appState,
          builder: (context, child) {
            final bool isKg = widget.appState.isKg;
            final String currentUnit = isKg ? "kg" : "lbs";

            return AlertDialog(
              backgroundColor: dialogBg,
              surfaceTintColor: Colors.transparent, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Record Weight', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: weightController,
                    style: TextStyle(color: textColor),
                    cursorColor: textColor,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: isKg ? 'e.g., 100' : 'e.g., 225',
                      suffixText: currentUnit,
                      hintStyle: const TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade600)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor)),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // THE FIX: Injected the iOS Style Toggle
                  _buildUnitToggle(isDark, isKg),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    if (weightController.text.trim().isNotEmpty) {
                      double? weight = double.tryParse(weightController.text.trim());
                      if (weight != null) {
                        widget.appState.addWeightRecord(exerciseName, weight);
                      }
                    }
                    Navigator.pop(context);
                  },
                  child: Text('Save', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  // THE FIX: Premium Segmented Slider
  Widget _buildUnitToggle(bool isDark, bool isKg) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.appState.toggleWeightUnit();
      },
      child: Container(
        width: 130,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // The Sliding Thumb
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              left: isKg ? 65 : 2,
              top: 2,
              bottom: 2,
              child: Container(
                width: 63,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF48484A) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
              ),
            ),
            
            // The Text Labels
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      'lbs',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: !isKg ? (isDark ? Colors.white : Colors.black) : Colors.grey,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'kg',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isKg ? (isDark ? Colors.white : Colors.black) : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? dayId, bool isDark, Color textColor, Color cardColor, Color primaryColor, Color invertedColor) {
    bool isSelected = _selectedDayFilter == dayId;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedDayFilter = dayId);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          boxShadow: !isDark && !isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)] : [],
        ),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              color: isSelected ? invertedColor : Colors.grey.shade500,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 14,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, child) {
        
        final bool isDark = widget.appState.isDarkMode;
        final String unit = widget.appState.isKg ? "kg" : "lbs"; 
        
        final Color bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
        final Color textColor = isDark ? Colors.white : Colors.black;
        final Color cardColor = isDark ? const Color(0xFF141414) : Colors.white;
        final Color dialogBg = isDark ? const Color(0xFF121212) : Colors.white;
        final Color primaryColor = isDark ? Colors.white : Colors.black;
        final Color invertedColor = isDark ? Colors.black : Colors.white;
        final Color frostedBg = isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.6);

        List<String> exercises = widget.appState.getUniqueExercises(dayId: _selectedDayFilter);
        final double topPadding = MediaQuery.of(context).padding.top + 160.0;

        return Scaffold(
          backgroundColor: bgColor,
          body: Stack(
            children: [
              Positioned.fill(
                child: exercises.isEmpty 
                  ? Padding(
                      padding: EdgeInsets.only(top: topPadding + 20),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                          _selectedDayFilter == null ? 'Add exercises to your schedule first' : 'No exercises in this workout', 
                          style: TextStyle(color: Colors.grey.shade600)
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.only(top: topPadding, bottom: 40, left: 20, right: 20),
                      itemCount: exercises.length,
                      itemBuilder: (context, index) {
                        String name = exercises[index];
                        List<WeightRecord> records = widget.appState.exerciseProgress[name] ?? [];
                        
                        String displayWeight = records.isNotEmpty ? "${records.last.weight} $unit" : "--";

                        return TweenAnimationBuilder<double>(
                          key: ValueKey('${_selectedDayFilter}_$name'), 
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 350 + (index * 50).clamp(0, 400)), 
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 40 * (1 - value)), 
                              child: Opacity(
                                opacity: value, 
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: !isDark ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] : [],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Text('Highest: $displayWeight', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      BouncingWidget(
                                        // THE FIX: Removed the static 'unit' argument here
                                        onTap: () => _showAddWeightDialog(context, name, isDark, dialogBg, textColor),
                                        child: CircleAvatar(
                                          radius: 20,
                                          backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200,
                                          child: Icon(Icons.add, color: textColor, size: 20),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      BouncingWidget(
                                        onTap: () {
                                          if (records.isNotEmpty) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ChartPage(
                                                  appState: widget.appState,
                                                  exerciseName: name,
                                                  records: records,
                                                  unit: unit,
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        child: CircleAvatar(
                                          radius: 20,
                                          backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200,
                                          child: Icon(Icons.show_chart, color: records.isNotEmpty ? textColor : Colors.grey, size: 20),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              ),

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                    child: Container(
                      color: frostedBg, 
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 10,
                        left: 20, 
                        bottom: 15,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              BouncingWidget(
                                onTap: () => Navigator.pop(context),
                                child: CircleAvatar(
                                  radius: 20, 
                                  backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white, 
                                  child: Icon(Icons.arrow_back_ios_new, color: textColor, size: 18)
                                ),
                              ),
                              const SizedBox(width: 15),
                              Text('Progress', style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 25),
                          
                          SizedBox(
                            height: 40,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              clipBehavior: Clip.none,
                              children: [
                                _buildFilterChip("All", null, isDark, textColor, cardColor, primaryColor, invertedColor),
                                ...widget.appState.days.map((d) => _buildFilterChip(d.name, d.id, isDark, textColor, cardColor, primaryColor, invertedColor)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ChartPage extends StatefulWidget {
  final WorkoutState appState;
  final String exerciseName;
  final List<WeightRecord> records;
  final String unit; 

  const ChartPage({
    super.key,
    required this.appState,
    required this.exerciseName,
    required this.records,
    required this.unit,
  });

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  bool _animateChart = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _animateChart = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, child) {
        
        final bool isDark = widget.appState.isDarkMode;
        final Color bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
        final Color textColor = isDark ? Colors.white : Colors.black;
        final Color cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
        final Color frostedBg = isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.6);

        double minWeight = widget.records.first.weight;
        double maxWeight = widget.records.first.weight;
        for (var r in widget.records) {
          if (r.weight < minWeight) minWeight = r.weight;
          if (r.weight > maxWeight) maxWeight = r.weight;
        }

        if (minWeight == maxWeight) {
          minWeight = (minWeight - 20) < 0 ? 0 : (minWeight - 20);
          maxWeight = maxWeight + 20;
        } else {
          double padding = (maxWeight - minWeight) * 0.15;
          minWeight = (minWeight - padding) < 0 ? 0 : (minWeight - padding);
          maxWeight = maxWeight + padding;
        }

        List<FlSpot> finalChartSpots = [];
        if (widget.records.length == 1) {
          finalChartSpots = [
            FlSpot(0, widget.records.first.weight),
            FlSpot(1, widget.records.first.weight), 
          ];
        } else {
          finalChartSpots = widget.records.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.weight)).toList();
        }

        List<FlSpot> startingSpots = finalChartSpots.map((spot) => FlSpot(spot.x, minWeight)).toList();

        bool isSameY = widget.records.every((r) => r.weight == widget.records.first.weight);
        double? explicitMinY = isSameY ? (widget.records.first.weight - 20).clamp(0, double.infinity).toDouble() : null;
        double? explicitMaxY = isSameY ? widget.records.first.weight + 20 : null;

        final double topPadding = MediaQuery.of(context).padding.top + 90.0;

        return Scaffold(
          backgroundColor: bgColor,
          body: Stack(
            children: [
              Positioned.fill(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(top: topPadding, left: 20, right: 20, bottom: 40),
                  
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.95 + (0.05 * value),
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: !isDark ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] : [],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Weight History', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                          const SizedBox(height: 30),
                          SizedBox(
                            height: 300,
                            width: double.infinity,
                            child: LineChart(
                              LineChartData(
                                minY: explicitMinY ?? minWeight, 
                                maxY: explicitMaxY ?? maxWeight,
                                gridData: const FlGridData(show: false), 
                                titlesData: const FlTitlesData(show: false),
                                borderData: FlBorderData(show: false),
                                lineTouchData: LineTouchData(
                                  touchTooltipData: LineTouchTooltipData(
                                    getTooltipColor: (touchedSpot) => isDark ? Colors.white : Colors.black,
                                    getTooltipItems: (touchedSpots) {
                                      return touchedSpots.map((spot) {
                                        return LineTooltipItem(
                                          '${spot.y} ${widget.unit}',
                                          TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                                        );
                                      }).toList();
                                    },
                                  ),
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _animateChart ? finalChartSpots : startingSpots,
                                    isCurved: false, 
                                    color: textColor, 
                                    barWidth: 4,
                                    isStrokeCapRound: true,
                                    dotData: FlDotData(
                                      show: true,
                                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                        radius: 4,
                                        color: textColor,
                                        strokeWidth: 2,
                                        strokeColor: cardColor,
                                      ),
                                    ),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: textColor.withOpacity(0.1), 
                                    ),
                                  )
                                ],
                              ),
                              duration: const Duration(milliseconds: 1200), 
                              curve: Curves.easeOutCubic, 
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                    child: Container(
                      color: frostedBg, 
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 10,
                        left: 20, 
                        right: 20,
                        bottom: 15,
                      ),
                      child: Row(
                        children: [
                          BouncingWidget(
                            onTap: () => Navigator.pop(context),
                            child: CircleAvatar(
                              radius: 20, 
                              backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white, 
                              child: Icon(Icons.arrow_back_ios_new, color: textColor, size: 18)
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              widget.exerciseName, 
                              style: TextStyle(color: textColor, fontSize: 26, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
