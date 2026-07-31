import 'dart:ui';
import 'dart:io';
import 'dart:math' as math; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:fl_chart/fl_chart.dart'; 
import 'package:confetti/confetti.dart'; 
import 'package:screenshot/screenshot.dart'; 
import 'package:path_provider/path_provider.dart'; 
import 'package:share_plus/share_plus.dart'; 
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

  final ValueNotifier<String?> _selectedFilterNotifier = ValueNotifier(null); 
  final ValueNotifier<bool> _pageReadyNotifier = ValueNotifier(false); 
  
  late ConfettiController _confettiController; 

  OverlayEntry? _addWeightOverlayEntry; 
  TextEditingController? _weightController; 
  TextEditingController? _repsController; 

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _pageReadyNotifier.value = true;
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _selectedFilterNotifier.dispose();
    _pageReadyNotifier.dispose(); 
    _closeAddWeightDialog(); 
    super.dispose();
  }

  void _closeAddWeightDialog() {
    if (_addWeightOverlayEntry != null && _addWeightOverlayEntry!.mounted) {
      _addWeightOverlayEntry!.remove();
    }
    _addWeightOverlayEntry = null;
    _weightController?.dispose();
    _weightController = null;
    _repsController?.dispose();
    _repsController = null;
  }

  void _showAddWeightDialog(BuildContext context, String exerciseName) {
    if (_addWeightOverlayEntry != null) return;
    
    _weightController = TextEditingController();
    _repsController = TextEditingController(text: "1"); 

    _addWeightOverlayEntry = OverlayEntry(
      builder: (context) {
        return Material(
          color: Colors.black.withOpacity(0.7),
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeAddWeightDialog,
                  behavior: HitTestBehavior.opaque,
                  child: Container(color: Colors.transparent),
                ),
              ),
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
                    );
                  },
                  child: GestureDetector(
                    onTap: () {}, 
                    child: ListenableBuilder(
                      listenable: widget.appState,
                      builder: (context, child) {
                        final bool isDark = widget.appState.isDarkMode;
                        final bool useMaterialYou = widget.appState.useMaterialYou;
                        final ColorScheme scheme = Theme.of(this.context).colorScheme;

                        final Color dialogBg = useMaterialYou ? scheme.surfaceContainerHigh : (isDark ? const Color(0xFF121212) : Colors.white);
                        final Color textColor = useMaterialYou ? scheme.onSurface : (isDark ? Colors.white : Colors.black);
                        final Color hintColor = useMaterialYou ? scheme.onSurfaceVariant : Colors.grey;
                        final Color underlineColor = useMaterialYou ? scheme.outline : Colors.grey.shade600;

                        final bool isKg = widget.appState.isKg;
                        final String currentUnit = isKg ? "kg" : "lbs";

                        return AlertDialog(
                          backgroundColor: dialogBg,
                          surfaceTintColor: Colors.transparent, 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          title: Text('Record Set', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  // WEIGHT INPUT
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: _weightController,
                                      style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
                                      cursorColor: textColor,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                                      autofocus: true,
                                      decoration: InputDecoration(
                                        labelText: 'Weight',
                                        labelStyle: TextStyle(color: hintColor, fontSize: 14, fontWeight: FontWeight.normal),
                                        suffixText: currentUnit,
                                        suffixStyle: TextStyle(color: hintColor),
                                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: underlineColor)),
                                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor, width: 2)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  // REPS INPUT
                                  Expanded(
                                    flex: 1,
                                    child: TextField(
                                      controller: _repsController,
                                      style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
                                      cursorColor: textColor,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      decoration: InputDecoration(
                                        labelText: 'Reps',
                                        labelStyle: TextStyle(color: hintColor, fontSize: 14, fontWeight: FontWeight.normal),
                                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: underlineColor)),
                                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor, width: 2)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),
                              _buildUnitToggle(isDark, isKg, useMaterialYou, scheme),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: _closeAddWeightDialog,
                              child: Text('Cancel', style: TextStyle(color: hintColor)),
                            ),
                            TextButton(
                              onPressed: () {
                                if (_weightController != null && _weightController!.text.trim().isNotEmpty) {
                                  double? weight = double.tryParse(_weightController!.text.trim());
                                  int reps = int.tryParse(_repsController?.text.trim() ?? "1") ?? 1;
                                  
                                  if (weight != null) {
                                    String activeUnit = widget.appState.isKg ? "kg" : "lbs";
                                    bool isPR = widget.appState.addWeightRecord(exerciseName, weight, activeUnit, reps);
                                    
                                    if (isPR) {
                                      HapticFeedback.heavyImpact();
                                      _confettiController.play();
                                      ScaffoldMessenger.of(this.context).showSnackBar(
                                        SnackBar(
                                          content: Text('🎉 New Personal Record on $exerciseName!', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                          backgroundColor: Colors.green.shade600,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          duration: const Duration(seconds: 3),
                                        )
                                      );
                                    }
                                  }
                                }
                                _closeAddWeightDialog();
                              },
                              child: Text('Save', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        );
                      }
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    Overlay.of(context).insert(_addWeightOverlayEntry!);
  }

  Widget _buildUnitToggle(bool isDark, bool isKg, bool useMaterialYou, ColorScheme scheme) {
    final Color bg = useMaterialYou ? scheme.surfaceContainerHighest : (isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200);
    final Color thumbBg = useMaterialYou ? scheme.primary : (isDark ? const Color(0xFF48484A) : Colors.white);
    final Color activeText = useMaterialYou ? scheme.onPrimary : (isDark ? Colors.white : Colors.black);
    final Color inactiveText = useMaterialYou ? scheme.onSurfaceVariant : Colors.grey;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.appState.toggleWeightUnit();
      },
      child: Container(
        width: 130,
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              left: isKg ? 65 : 2,
              top: 2,
              bottom: 2,
              child: Container(
                width: 63,
                decoration: BoxDecoration(
                  color: thumbBg,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]
                ),
              ),
            ),
            Row(
              children: [
                Expanded(child: Center(child: Text('lbs', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: !isKg ? activeText : inactiveText)))),
                Expanded(child: Center(child: Text('kg', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isKg ? activeText : inactiveText)))),
              ],
            ),
          ],
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
        final bool useMaterialYou = widget.appState.useMaterialYou;
        final ColorScheme scheme = Theme.of(context).colorScheme;
        
        final String globalUnit = widget.appState.isKg ? "kg" : "lbs"; 

        final bool isPremiumBlack = !useMaterialYou && widget.appState.themePresetId == 'default_black';

        final Color bgColor = isPremiumBlack ? (isDark ? Colors.black : const Color(0xFFF2F2F7)) : scheme.surface;
        final Color textColor = isPremiumBlack ? (isDark ? Colors.white : Colors.black) : scheme.onSurface;
        final Color cardColor = isPremiumBlack ? (isDark ? const Color(0xFF141414) : Colors.white) : scheme.surfaceContainer;
        final Color primaryColor = isPremiumBlack ? (isDark ? Colors.white : Colors.black) : scheme.primary;
        final Color invertedColor = isPremiumBlack ? (isDark ? Colors.black : Colors.white) : scheme.onPrimary;
        final Color frostedBg = isPremiumBlack ? (isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.6)) : scheme.surface.withOpacity(0.6);
        final Color btnBg = isPremiumBlack ? (isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200) : scheme.surfaceContainerHigh;

        final Color unselectedChipBg = isPremiumBlack ? (isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.05)) : scheme.surfaceContainerLow;
        final Color chipBorderColor = isPremiumBlack ? (isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.08)) : scheme.outlineVariant.withOpacity(0.5);

        final double topPadding = MediaQuery.of(context).padding.top + 160.0;

        return Scaffold(
          backgroundColor: bgColor,
          body: Stack(
            children: [
              Positioned.fill(
                child: ValueListenableBuilder<String?>(
                  valueListenable: _selectedFilterNotifier,
                  builder: (context, selectedFilter, child) {
                    List<String> exercises = widget.appState.getUniqueExercises(dayId: selectedFilter);
                    
                    if (exercises.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.only(top: topPadding + 20),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Text(
                            selectedFilter == null ? 'Add exercises to your schedule first' : 'No exercises in this workout', 
                            style: TextStyle(color: useMaterialYou ? scheme.onSurfaceVariant : Colors.grey.shade600)
                          ),
                        ),
                      );
                    }

                    return ValueListenableBuilder<bool>(
                      valueListenable: _pageReadyNotifier,
                      builder: (context, isReady, _) {
                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.only(top: topPadding, bottom: 40, left: 20, right: 20),
                          itemCount: exercises.length,
                          itemBuilder: (context, index) {
                            String name = exercises[index];
                            List<WeightRecord> records = widget.appState.exerciseProgress[name] ?? [];
                            
                            String displayWeight = "--";
                            if (records.isNotEmpty) {
                              WeightRecord highest = records.first;
                              double highestNorm = highest.unit == 'kg' ? highest.weight * 2.20462 : highest.weight;
                              
                              for (var r in records) {
                                double norm = r.unit == 'kg' ? r.weight * 2.20462 : r.weight;
                                if (norm >= highestNorm) {
                                  highest = r;
                                  highestNorm = norm;
                                }
                              }
                              displayWeight = "${highest.weight} ${highest.unit} x ${highest.reps}";
                            }

                            return TweenAnimationBuilder<double>(
                              key: ValueKey('${selectedFilter}_$name'), 
                              tween: Tween(begin: 0.0, end: isReady ? 1.0 : 0.0), 
                              duration: Duration(milliseconds: 300 + (index * 40).clamp(0, 300)), 
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 30 * (1 - value)), 
                                  child: Opacity(opacity: value, child: child),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: !isDark && !useMaterialYou ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] : [],
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
                                            Text('Highest: $displayWeight', style: TextStyle(color: useMaterialYou ? scheme.onSurfaceVariant : Colors.grey.shade500, fontSize: 14)),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          BouncingWidget(
                                            onTap: () => _showAddWeightDialog(context, name),
                                            child: CircleAvatar(
                                              radius: 20,
                                              backgroundColor: btnBg,
                                              child: Icon(Icons.add, color: textColor, size: 20),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          BouncingWidget(
                                            onTap: () {
                                              if (records.isNotEmpty) {
                                                // THE FIX: Provide instantaneous feedback when tapped
                                                HapticFeedback.lightImpact();
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => ChartPage(
                                                      appState: widget.appState,
                                                      exerciseName: name,
                                                      globalUnitPreference: globalUnit,
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                            child: CircleAvatar(
                                              radius: 20,
                                              backgroundColor: btnBg,
                                              child: Icon(Icons.show_chart, color: records.isNotEmpty ? textColor : (useMaterialYou ? scheme.outline : Colors.grey), size: 20),
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
                        );
                      },
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
                        right: 20,
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
                                  backgroundColor: useMaterialYou ? scheme.surfaceContainerHigh : (isDark ? const Color(0xFF1C1C1E) : Colors.white), 
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
                                _FilterChip(
                                  label: "All",
                                  dayId: null,
                                  selectedFilterNotifier: _selectedFilterNotifier,
                                  isDark: isDark,
                                  useMaterialYou: useMaterialYou,
                                  primaryColor: primaryColor,
                                  invertedColor: invertedColor,
                                  unselectedBg: unselectedChipBg,
                                  borderColor: chipBorderColor,
                                ),
                                ...widget.appState.days.map((d) => _FilterChip(
                                  label: d.name,
                                  dayId: d.id,
                                  selectedFilterNotifier: _selectedFilterNotifier,
                                  isDark: isDark,
                                  useMaterialYou: useMaterialYou,
                                  primaryColor: primaryColor,
                                  invertedColor: invertedColor,
                                  unselectedBg: unselectedChipBg,
                                  borderColor: chipBorderColor,
                                )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: math.pi / 2, 
                  maxBlastForce: 5,
                  minBlastForce: 2,
                  emissionFrequency: 0.05,
                  numberOfParticles: 20,
                  gravity: 0.1,
                  colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String? dayId;
  final ValueNotifier<String?> selectedFilterNotifier;
  final bool isDark;
  final bool useMaterialYou;
  final Color primaryColor;
  final Color invertedColor;
  final Color unselectedBg;
  final Color borderColor;

  const _FilterChip({
    required this.label,
    required this.dayId,
    required this.selectedFilterNotifier,
    required this.isDark,
    required this.useMaterialYou,
    required this.primaryColor,
    required this.invertedColor,
    required this.unselectedBg,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: selectedFilterNotifier,
      builder: (context, selectedFilter, _) {
        bool isSelected = selectedFilter == dayId;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            selectedFilterNotifier.value = dayId; 
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? primaryColor : unselectedBg,
              borderRadius: BorderRadius.circular(20),
              border: isSelected ? null : Border.all(color: borderColor, width: 0.5),
              boxShadow: !isDark && !useMaterialYou && !isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)] : [],
            ),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(color: isSelected ? invertedColor : Colors.grey.shade500, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, fontSize: 14),
                child: Text(label),
              ),
            ),
          ),
        );
      }
    );
  }
}

// -----------------------------------------------------------------------------
// ADVANCED CHART PAGE: Deferred Rendering & GPU Throttling fixes lag
// -----------------------------------------------------------------------------
class ChartPage extends StatefulWidget {
  final WorkoutState appState;
  final String exerciseName;
  final String globalUnitPreference; 

  const ChartPage({
    super.key,
    required this.appState,
    required this.exerciseName,
    required this.globalUnitPreference,
  });

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  final ValueNotifier<bool> _animateChartNotifier = ValueNotifier(false);
  final ScreenshotController _screenshotController = ScreenshotController();

  bool _show1RM = false;
  String _timeFilter = 'ALL'; 
  
  // THE FIX: Used to hide heavy content until the page sliding animation is complete!
  bool _isNavigating = true; 

  @override
  void initState() {
    super.initState();
    // THE FIX: Gives the page 300ms to smoothly slide in before computing and drawing the heavy graph
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _isNavigating = false);
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) _animateChartNotifier.value = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _animateChartNotifier.dispose();
    super.dispose();
  }

  Future<void> _captureAndShare() async {
    HapticFeedback.mediumImpact();
    try {
      final Uint8List? image = await _screenshotController.capture(delay: const Duration(milliseconds: 10));
      if (image != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = await File('${directory.path}/share_pr.png').create();
        await imagePath.writeAsBytes(image);
        await Share.shareXFiles([XFile(imagePath.path)], text: 'Check out my progress on ${widget.exerciseName}! 💪');
      }
    } catch (e) {
      debugPrint("Error sharing: $e");
    }
  }

  double _getCalculatedWeight(WeightRecord r) {
    bool targetIsKg = widget.globalUnitPreference == 'kg';
    double normW = r.weight;
    
    if (r.unit == 'kg' && !targetIsKg) normW = r.weight * 2.20462;
    if (r.unit == 'lbs' && targetIsKg) normW = r.weight / 2.20462;

    if (_show1RM && r.reps > 1) {
      return normW * (1 + (r.reps / 30.0)); 
    }
    return normW;
  }

  List<WeightRecord> _getFilteredRecords(List<WeightRecord> allRecords) {
    if (_timeFilter == 'ALL') return allRecords;
    
    DateTime now = DateTime.now();
    DateTime cutoff;
    
    if (_timeFilter == '1M') cutoff = DateTime(now.year, now.month - 1, now.day);
    else if (_timeFilter == '3M') cutoff = DateTime(now.year, now.month - 3, now.day);
    else if (_timeFilter == '6M') cutoff = DateTime(now.year, now.month - 6, now.day);
    else cutoff = DateTime(now.year, 1, 1); 

    return allRecords.where((r) => r.date.isAfter(cutoff)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, child) {
        
        List<WeightRecord> rawRecords = widget.appState.exerciseProgress[widget.exerciseName] ?? [];
        if (rawRecords.isEmpty && !_isNavigating) {
          WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) Navigator.pop(context); });
          return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
        }

        List<WeightRecord> currentRecords = _getFilteredRecords(rawRecords);

        double explicitMinY = 0, explicitMaxY = 100;
        List<FlSpot> finalChartSpots = [];
        List<FlSpot> startingSpots = [];

        if (currentRecords.isNotEmpty && !_isNavigating) {
          double minWeight = _getCalculatedWeight(currentRecords.first);
          double maxWeight = minWeight;
          
          for (var r in currentRecords) {
            double val = _getCalculatedWeight(r);
            if (val < minWeight) minWeight = val;
            if (val > maxWeight) maxWeight = val;
          }

          if (minWeight == maxWeight) {
            explicitMinY = (minWeight - 20) < 0 ? 0 : (minWeight - 20);
            explicitMaxY = maxWeight + 20;
          } else {
            double padding = (maxWeight - minWeight) * 0.15;
            explicitMinY = (minWeight - padding) < 0 ? 0 : (minWeight - padding);
            explicitMaxY = maxWeight + padding;
          }

          if (currentRecords.length == 1) {
            finalChartSpots = [
              FlSpot(0, _getCalculatedWeight(currentRecords.first)),
              FlSpot(1, _getCalculatedWeight(currentRecords.first)), 
            ];
          } else {
            finalChartSpots = currentRecords.asMap().entries.map((e) => FlSpot(e.key.toDouble(), _getCalculatedWeight(e.value))).toList();
          }
          startingSpots = finalChartSpots.map((spot) => FlSpot(spot.x, explicitMinY)).toList();
        }

        final bool isDark = widget.appState.isDarkMode;
        final bool useMaterialYou = widget.appState.useMaterialYou;
        final ColorScheme scheme = Theme.of(context).colorScheme;

        final Color bgColor = useMaterialYou ? scheme.surface : (isDark ? Colors.black : const Color(0xFFF2F2F7));
        final Color textColor = useMaterialYou ? scheme.onSurface : (isDark ? Colors.white : Colors.black);
        final Color subTextColor = useMaterialYou ? scheme.onSurfaceVariant : (isDark ? Colors.grey : Colors.grey.shade600);
        final Color cardColor = useMaterialYou ? scheme.surfaceContainer : (isDark ? const Color(0xFF1C1C1E) : Colors.white);
        final Color frostedBg = useMaterialYou ? scheme.surface.withOpacity(0.6) : (isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.6));
        
        final Color chartLineColor = useMaterialYou ? scheme.primary : textColor;
        final Color tooltipBgColor = useMaterialYou ? scheme.inverseSurface : (isDark ? Colors.white : Colors.black);
        final Color tooltipTextColor = useMaterialYou ? scheme.onInverseSurface : (isDark ? Colors.black : Colors.white);

        final double topPadding = MediaQuery.of(context).padding.top + 90.0;
        final List<String> monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

        return Scaffold(
          backgroundColor: bgColor,
          body: Stack(
            children: [
              Positioned.fill(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(top: topPadding, left: 20, right: 20, bottom: 40),
                  
                  // THE FIX: Instantly renders a blank placeholder until navigation finishes, dropping CPU load!
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isNavigating 
                      ? const SizedBox(height: 500) 
                      : Column(
                          key: const ValueKey('loadedContent'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Screenshot(
                              controller: _screenshotController,
                              child: Container(
                                padding: const EdgeInsets.all(25),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: !isDark && !useMaterialYou ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] : [],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(widget.exerciseName, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                                        GestureDetector(
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            setState(() => _show1RM = !_show1RM);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: _show1RM ? chartLineColor : Colors.transparent,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: _show1RM ? Colors.transparent : subTextColor.withOpacity(0.5)),
                                            ),
                                            child: Text('Est. 1RM', style: TextStyle(
                                              color: _show1RM ? (useMaterialYou ? scheme.onPrimary : (isDark ? Colors.black : Colors.white)) : subTextColor, 
                                              fontSize: 12, fontWeight: FontWeight.bold)
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 15),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: ['1M', '3M', '6M', 'YTD', 'ALL'].map((filter) {
                                        bool isSel = _timeFilter == filter;
                                        return GestureDetector(
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            setState(() => _timeFilter = filter);
                                          },
                                          child: Text(filter, style: TextStyle(
                                            color: isSel ? textColor : subTextColor, 
                                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                            fontSize: 13
                                          )),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 30),

                                    currentRecords.isEmpty 
                                      ? SizedBox(height: 250, child: Center(child: Text('No records in this time range', style: TextStyle(color: subTextColor))))
                                      : SizedBox(
                                          height: 250,
                                          width: double.infinity,
                                          child: ValueListenableBuilder<bool>(
                                            valueListenable: _animateChartNotifier,
                                            builder: (context, animate, child) {
                                              return RepaintBoundary(
                                                child: LineChart(
                                                  LineChartData(
                                                    minY: explicitMinY, 
                                                    maxY: explicitMaxY,
                                                    gridData: const FlGridData(show: false), 
                                                    titlesData: const FlTitlesData(show: false),
                                                    borderData: FlBorderData(show: false),
                                                    lineTouchData: LineTouchData(
                                                      touchTooltipData: LineTouchTooltipData(
                                                        getTooltipColor: (touchedSpot) => tooltipBgColor,
                                                        getTooltipItems: (touchedSpots) {
                                                          return touchedSpots.map((spot) {
                                                            int index = spot.x.toInt();
                                                            WeightRecord originalRecord = currentRecords[index];
                                                            
                                                            String lbl = _show1RM 
                                                              ? '${_getCalculatedWeight(originalRecord).toStringAsFixed(1)} ${widget.globalUnitPreference}'
                                                              : '${originalRecord.weight} ${originalRecord.unit} x ${originalRecord.reps}';
                                                            
                                                            return LineTooltipItem(lbl, TextStyle(color: tooltipTextColor, fontWeight: FontWeight.bold));
                                                          }).toList();
                                                        },
                                                      ),
                                                    ),
                                                    lineBarsData: [
                                                      LineChartBarData(
                                                        spots: animate ? finalChartSpots : startingSpots,
                                                        isCurved: true, 
                                                        curveSmoothness: 0.2,
                                                        color: chartLineColor, 
                                                        barWidth: 4,
                                                        isStrokeCapRound: true,
                                                        // THE FIX: GPU Throttling! Turns off memory-heavy dots automatically if you log > 30 records
                                                        dotData: FlDotData(
                                                          show: currentRecords.length <= 30,
                                                          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                                            radius: 4, color: chartLineColor, strokeWidth: 2, strokeColor: cardColor,
                                                          ),
                                                        ),
                                                        belowBarData: BarAreaData(show: true, color: chartLineColor.withOpacity(0.1)),
                                                      )
                                                    ],
                                                  ),
                                                  duration: const Duration(milliseconds: 1200), 
                                                  curve: Curves.easeOutCubic, 
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 35),
                            Text('Log History', style: TextStyle(color: useMaterialYou ? scheme.onSurfaceVariant : Colors.grey.shade500, fontSize: 16)),
                            const SizedBox(height: 15),

                            Column(
                              children: rawRecords.reversed.map((record) {
                                String dateStr = "${monthNames[record.date.month - 1]} ${record.date.day}, ${record.date.year}";
                                return _AnimatedLogItem(
                                  key: ObjectKey(record), 
                                  record: record,
                                  dateStr: dateStr,
                                  cardColor: cardColor,
                                  textColor: textColor,
                                  subTextColor: subTextColor,
                                  isDark: isDark,
                                  useMaterialYou: useMaterialYou,
                                  onDelete: () => widget.appState.deleteWeightRecord(widget.exerciseName, record),
                                );
                              }).toList(),
                            ),
                          ],
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
                              backgroundColor: useMaterialYou ? scheme.surfaceContainerHigh : (isDark ? const Color(0xFF1C1C1E) : Colors.white), 
                              child: Icon(Icons.arrow_back_ios_new, color: textColor, size: 18)
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              'Progress', 
                              style: TextStyle(color: textColor, fontSize: 26, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          BouncingWidget(
                            onTap: _captureAndShare,
                            child: CircleAvatar(
                              radius: 20, 
                              backgroundColor: useMaterialYou ? scheme.primaryContainer : (isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade200), 
                              child: Icon(Icons.ios_share_rounded, color: useMaterialYou ? scheme.onPrimaryContainer : textColor, size: 18)
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

class _AnimatedLogItem extends StatefulWidget {
  final WeightRecord record;
  final String dateStr;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final bool isDark;
  final bool useMaterialYou;
  final VoidCallback onDelete;

  const _AnimatedLogItem({
    super.key,
    required this.record,
    required this.dateStr,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.isDark,
    required this.useMaterialYou,
    required this.onDelete,
  });

  @override
  State<_AnimatedLogItem> createState() => _AnimatedLogItemState();
}

class _AnimatedLogItemState extends State<_AnimatedLogItem> {
  bool _isDeleting = false;

  void _handleDelete() async {
    HapticFeedback.mediumImpact();
    setState(() => _isDeleting = true);
    await Future.delayed(const Duration(milliseconds: 250));
    if (mounted) widget.onDelete();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isDeleting ? 0.0 : 1.0,
        child: _isDeleting 
          ? const SizedBox(width: double.infinity, height: 0) 
          : Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: widget.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: !widget.isDark && !widget.useMaterialYou 
                  ? [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)] 
                  : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${widget.record.weight} ${widget.record.unit} × ${widget.record.reps}', style: TextStyle(color: widget.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(widget.dateStr, style: TextStyle(color: widget.subTextColor, fontSize: 13)),
                    ],
                  ),
                  BouncingWidget(
                    onTap: _handleDelete,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.isDark ? Colors.redAccent.withOpacity(0.15) : Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
