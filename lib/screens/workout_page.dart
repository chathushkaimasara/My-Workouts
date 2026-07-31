import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import '../state/workout_state.dart';
import '../models/workout_models.dart';
import '../widgets/bouncing_widget.dart';

class WorkoutPage extends StatefulWidget {
  final WorkoutState appState;
  final String dayId;

  const WorkoutPage({super.key, required this.appState, required this.dayId});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  String? _selectedWorkoutId;
  Offset _menuPosition = Offset.zero;
  final GlobalKey _plusButtonKey = GlobalKey();
  OverlayEntry? _addMenuOverlayEntry;

  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  int _totalRestSeconds = 60;
  bool _isResting = false;

  @override
  void initState() {
    super.initState();
    _loadRestTime();
  }

  void _loadRestTime() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _totalRestSeconds = prefs.getInt('workout_timer_duration') ?? 60;
      });
    }
  }

  @override
  void dispose() {
    _closeAddMenu();
    _restTimer?.cancel();
    super.dispose();
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _restSecondsRemaining = _totalRestSeconds;
      _isResting = true;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsRemaining > 0) {
        setState(() => _restSecondsRemaining--);
      } else {
        _stopRestTimer();
        HapticFeedback.heavyImpact(); 
      }
    });
  }

  void _stopRestTimer() {
    _restTimer?.cancel();
    if (mounted) {
      setState(() => _isResting = false);
    }
  }

  void _closeAddMenu() {
    // THE FIX: Strict mounted check strictly prevents overlay memory leaks on rapid navigation
    if (_addMenuOverlayEntry != null && _addMenuOverlayEntry!.mounted) {
      _addMenuOverlayEntry!.remove();
    }
    _addMenuOverlayEntry = null;
  }

  void _closeMenu() {
    if (_selectedWorkoutId != null) {
      setState(() => _selectedWorkoutId = null);
    }
    _closeAddMenu(); 
  }

  void _openMenu(String id, Offset position) {
    setState(() {
      _selectedWorkoutId = id;
      _menuPosition = position;
    });
  }

  void _shareWorkout(WorkoutDay day) {
    if (day.workouts.isEmpty) {
      Share.share("I'm getting ready for my ${day.name} workout!");
      return;
    }
    String shareText = '🏋️‍♂️ ${day.name}\n\n';
    for (var item in day.workouts) {
      if (item.isDivider) {
        shareText += item.name.isNotEmpty ? '\n━━━ ${item.name} ━━━\n' : '\n━━━━━━━━━━━━━━━━\n';
      } else {
        shareText += '${item.isCompleted ? '✅' : '⚪'} ${item.name} - ${item.reps}\n';
      }
    }
    Share.share(shareText.trim());
  }

  void _safeCloseDialog(BuildContext dialogContext, VoidCallback action) {
    FocusManager.instance.primaryFocus?.unfocus();
    action();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (dialogContext.mounted) Navigator.pop(dialogContext);
    });
  }

  void _showAddWorkoutDialog(BuildContext context, bool isDark, bool useMaterialYou, ColorScheme scheme, Color dialogBg, Color textColor) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController repsController = TextEditingController();
    final TextEditingController rpeController = TextEditingController(); 
    
    final Color hintColor = useMaterialYou ? scheme.onSurfaceVariant : Colors.grey;
    final Color underlineColor = useMaterialYou ? scheme.outline : Colors.grey.shade600;

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
      pageBuilder: (dialogContext, animation, secondaryAnimation) { 
        return AlertDialog(
          backgroundColor: dialogBg,
          surfaceTintColor: Colors.transparent, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Add Exercise', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThemedTextField(controller: nameController, hint: 'e.g., Bench Press', textColor: textColor, hintColor: hintColor, underlineColor: underlineColor),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildThemedTextField(controller: repsController, hint: 'Reps (e.g., 8)', textColor: textColor, hintColor: hintColor, underlineColor: underlineColor),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    flex: 1,
                    child: _buildThemedTextField(controller: rpeController, hint: 'RPE (Opt.)', textColor: textColor, hintColor: hintColor, underlineColor: underlineColor),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => _safeCloseDialog(dialogContext, () {}),
              child: Text('Cancel', style: TextStyle(color: hintColor)),
            ),
            TextButton(
              onPressed: () {
                _safeCloseDialog(dialogContext, () {
                  if (nameController.text.trim().isNotEmpty) {
                    String finalReps = repsController.text.trim();
                    if (rpeController.text.trim().isNotEmpty) {
                      finalReps += ' • RPE ${rpeController.text.trim()}';
                    }
                    widget.appState.addWorkout(widget.dayId, nameController.text.trim(), finalReps);
                  }
                });
              },
              child: Text('Add', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    ).then((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        nameController.dispose();
        repsController.dispose();
        rpeController.dispose();
      });
    });
  }

  void _showEditDialog(BuildContext context, WorkoutItem item, bool isDark, bool useMaterialYou, ColorScheme scheme, Color dialogBg, Color textColor) {
    String baseReps = item.reps;
    String baseRpe = '';
    if (item.reps.contains(' • RPE ')) {
      var parts = item.reps.split(' • RPE ');
      baseReps = parts[0];
      baseRpe = parts.length > 1 ? parts[1] : '';
    }

    final TextEditingController nameController = TextEditingController(text: item.name);
    final TextEditingController repsController = TextEditingController(text: baseReps);
    final TextEditingController rpeController = TextEditingController(text: baseRpe);
    
    final Color hintColor = useMaterialYou ? scheme.onSurfaceVariant : Colors.grey;
    final Color underlineColor = useMaterialYou ? scheme.outline : Colors.grey.shade600;

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
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return AlertDialog(
          backgroundColor: dialogBg,
          surfaceTintColor: Colors.transparent, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(item.isDivider ? 'Edit Divider Text' : 'Edit Exercise', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThemedTextField(controller: nameController, hint: item.isDivider ? 'Optional text' : 'Name', textColor: textColor, hintColor: hintColor, underlineColor: underlineColor),
              if (!item.isDivider) ...[
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildThemedTextField(controller: repsController, hint: 'Reps', textColor: textColor, hintColor: hintColor, underlineColor: underlineColor),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      flex: 1,
                      child: _buildThemedTextField(controller: rpeController, hint: 'RPE (Opt.)', textColor: textColor, hintColor: hintColor, underlineColor: underlineColor),
                    ),
                  ],
                ),
              ]
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => _safeCloseDialog(dialogContext, () {}),
              child: Text('Cancel', style: TextStyle(color: hintColor)),
            ),
            TextButton(
              onPressed: () {
                _safeCloseDialog(dialogContext, () {
                  if (item.isDivider || nameController.text.trim().isNotEmpty) {
                    String finalReps = repsController.text.trim();
                    if (!item.isDivider && rpeController.text.trim().isNotEmpty) {
                      finalReps += ' • RPE ${rpeController.text.trim()}';
                    }
                    widget.appState.renameWorkout(widget.dayId, item.id, nameController.text.trim(), item.isDivider ? '' : finalReps);
                  }
                });
              },
              child: Text('Save', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    ).then((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        nameController.dispose();
        repsController.dispose();
        rpeController.dispose();
      });
    });
  }

  Widget _buildThemedTextField({required TextEditingController controller, required String hint, required Color textColor, required Color hintColor, required Color underlineColor}) {
    return TextField(
      controller: controller,
      style: TextStyle(color: textColor),
      cursorColor: textColor,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: hintColor),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: underlineColor)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor)),
      ),
    );
  }

   void _showAddMenu(bool isDark, bool useMaterialYou, ColorScheme scheme, Color textColor) {
    if (_addMenuOverlayEntry != null) {
      _closeAddMenu();
      return;
    }

    final RenderBox? renderBox = _plusButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final position = renderBox.localToGlobal(Offset.zero);

    final Color menuBg = useMaterialYou ? scheme.surfaceContainer : (isDark ? const Color(0xFF1C1C1E) : Colors.white);
    final Color dividerColor = useMaterialYou ? scheme.outlineVariant : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1));
    final Color dialogBg = useMaterialYou ? scheme.surfaceContainerHigh : (isDark ? const Color(0xFF121212) : Colors.white);

    _addMenuOverlayEntry = OverlayEntry(
      builder: (context) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _closeAddMenu,
                  onPanStart: (_) => _closeAddMenu(),
                  child: Container(color: Colors.transparent),
                ),
              ),
              Positioned(
                top: position.dy + 50,
                right: 20,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 250), 
                  curve: Curves.easeOutBack, 
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      alignment: Alignment.topRight, 
                      child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
                    );
                  },
                  child: Container(
                    width: 200,
                    decoration: BoxDecoration(
                      color: menuBg, 
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: dividerColor, width: 1),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.6 : 0.15), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () { 
                            _closeAddMenu(); 
                            _showAddWorkoutDialog(this.context, isDark, useMaterialYou, scheme, dialogBg, textColor); 
                          },
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Icon(Icons.fitness_center, color: textColor, size: 20),
                                const SizedBox(width: 12),
                                Text('Add Workout', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                        Divider(height: 1, color: dividerColor, indent: 16, endIndent: 16),
                        InkWell(
                          onTap: () { 
                            _closeAddMenu(); 
                            widget.appState.addDivider(widget.dayId); 
                          },
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Icon(Icons.remove, color: textColor, size: 20),
                                const SizedBox(width: 12),
                                Text('Add Divider', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    Overlay.of(this.context).insert(_addMenuOverlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, child) {
        
        final bool isDark = widget.appState.isDarkMode;
        final bool useMaterialYou = widget.appState.useMaterialYou;
        final ColorScheme scheme = Theme.of(context).colorScheme;

        final bool isPremiumBlack = !useMaterialYou && widget.appState.themePresetId == 'default_black';

        final Color bgColor = isPremiumBlack ? (isDark ? Colors.black : const Color(0xFFF2F2F7)) : scheme.surface;
        final Color textColor = isPremiumBlack ? (isDark ? Colors.white : Colors.black) : scheme.onSurface;
        final Color dialogBg = isPremiumBlack ? (isDark ? const Color(0xFF121212) : Colors.white) : scheme.surfaceContainerHigh;
        final Color frostedBg = isPremiumBlack ? (isDark ? Colors.black.withOpacity(0.35) : Colors.white.withOpacity(0.7)) : scheme.surface.withOpacity(0.7);
        final Color cardColor = isPremiumBlack ? (isDark ? const Color(0xFF1C1C1E) : Colors.white) : scheme.surfaceContainerHigh;
        final Color primaryColor = isPremiumBlack ? (isDark ? Colors.white : Colors.black) : scheme.primary;
        final Color invertedColor = isPremiumBlack ? (isDark ? Colors.black : Colors.white) : scheme.onPrimary;

        final day = widget.appState.days.firstWhere((d) => d.id == widget.dayId, orElse: () => WorkoutDay(id: '', name: 'Error', workouts: []));
        final bool hasCompleted = widget.appState.hasCompletedWorkouts(widget.dayId);
        
        final int titleLength = day.name.length;
        final double extraPadding = titleLength > 30 ? 80.0 : (titleLength > 15 ? 40.0 : 0.0);
        final double topPadding = MediaQuery.of(context).padding.top + 129.0 + extraPadding;
        
        String timeFormatted = '${(_restSecondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_restSecondsRemaining % 60).toString().padLeft(2, '0')}';

        return Scaffold(
          backgroundColor: bgColor,
          body: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeMenu,
                  onPanStart: (_) => _closeMenu(),
                  behavior: HitTestBehavior.translucent,
                  child: ReorderableListView.builder(
                    padding: EdgeInsets.only(top: topPadding, bottom: 100, left: 20, right: 20),
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()), 
                    buildDefaultDragHandles: false,
                    clipBehavior: Clip.none, 
                    proxyDecorator: (Widget child, int index, Animation<double> animation) {
                      return Material(type: MaterialType.transparency, elevation: 0, color: Colors.transparent, child: child);
                    },
                    itemCount: day.workouts.length,
                    onReorder: (oldIndex, newIndex) {
                      _closeMenu();
                      widget.appState.reorderWorkouts(widget.dayId, oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final item = day.workouts[index];
                      return _WorkoutRow(
                        key: ValueKey(item.id),
                        item: item,
                        index: index,
                        isSelected: _selectedWorkoutId == item.id,
                        isDark: isDark,
                        useMaterialYou: useMaterialYou,
                        scheme: scheme,
                        textColor: textColor,
                        onToggleComplete: () {
                          _closeMenu();
                          if (!item.isDivider) {
                            bool wasCompleted = item.isCompleted;
                            widget.appState.toggleWorkoutCompletion(widget.dayId, item.id);
                            
                            if (!wasCompleted) {
                              HapticFeedback.lightImpact();
                              _startRestTimer();
                            } else {
                              if (_isResting) _stopRestTimer();
                            }
                          }
                        },
                        onOpenMenu: (pos) => _openMenu(item.id, pos),
                        onCloseMenu: _closeMenu,
                      );
                    },
                  ),
                ),
              ),

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                // THE FIX: Wrapped the expensive blur in a RepaintBoundary so the GPU doesn't recalculate it while scrolling
                child: RepaintBoundary(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), 
                      child: Container(
                        color: frostedBg, 
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 10,
                          left: 20, 
                          right: 20,
                          bottom: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                BouncingWidget(
                                  onTap: () {
                                    _closeAddMenu();
                                    Navigator.pop(context);
                                  },
                                  child: CircleAvatar(radius: 20, backgroundColor: cardColor, child: Icon(Icons.arrow_back_ios_new, color: textColor, size: 18)),
                                ),
                                SizedBox(
                                  width: 144, 
                                  height: 40,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    alignment: Alignment.centerRight,
                                    children: [
                                      AnimatedPositioned(
                                        duration: const Duration(milliseconds: 400),
                                        curve: Curves.easeOutBack,
                                        right: hasCompleted ? 104.0 : 52.0, 
                                        child: IgnorePointer(
                                          ignoring: !hasCompleted,
                                          child: AnimatedOpacity(
                                            duration: const Duration(milliseconds: 250),
                                            opacity: hasCompleted ? 1.0 : 0.0, 
                                            child: BouncingWidget(
                                              onTap: () => widget.appState.resetCompletedWorkouts(widget.dayId),
                                              child: CircleAvatar(radius: 20, backgroundColor: cardColor, child: Icon(Icons.refresh, color: textColor, size: 22)),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 52.0,
                                        child: BouncingWidget(
                                          onTap: () => _shareWorkout(day),
                                          child: CircleAvatar(radius: 20, backgroundColor: cardColor, child: Icon(Icons.ios_share, color: textColor, size: 20)),
                                        ),
                                      ),
                                      Positioned(
                                        right: 0.0,
                                        child: BouncingWidget(
                                          key: _plusButtonKey, 
                                          onTap: () => _showAddMenu(isDark, useMaterialYou, scheme, textColor),
                                          child: CircleAvatar(radius: 20, backgroundColor: cardColor, child: Icon(Icons.add, color: textColor, size: 22)),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 25),
                            
                            Text(
                              day.name, 
                              maxLines: 3, 
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textColor, 
                                fontSize: 34, 
                                fontWeight: FontWeight.bold,
                                height: 1.15, 
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // THE FIX: Changed the anchor to pop up perfectly from the bottom of the screen!
              AnimatedPositioned(
                bottom: _isResting ? MediaQuery.of(context).padding.bottom + 30 : -150,
                left: 15,
                right: 15,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutBack,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: useMaterialYou ? scheme.surfaceContainerHigh : (isDark ? const Color(0xFF141414) : Colors.white),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 1),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _stopRestTimer,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Color(0xFFB74B4B), 
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.stop_rounded, color: Colors.white, size: 28),
                        ),
                      ),
                      const SizedBox(width: 14),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'ACTIVE REST', 
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)
                            ),
                            const SizedBox(height: 2),
                            Text(
                              timeFormatted, 
                              style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)
                            ),
                          ],
                        ),
                      ),

                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _restSecondsRemaining += 15);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text('+15s', style: TextStyle(color: textColor.withOpacity(0.7), fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                      const SizedBox(width: 5),

                      GestureDetector(
                        onTap: _stopRestTimer,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: invertedColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.skip_next_rounded, color: primaryColor, size: 26), 
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              if (_selectedWorkoutId != null) ...[
                Builder(builder: (context) {
                  final w = day.workouts.firstWhere((w) => w.id == _selectedWorkoutId);
                  
                  String? highestDisplay;
                  if (!w.isDivider && w.name.trim().isNotEmpty) {
                    String cleanName = w.name.trim();
                    cleanName = cleanName[0].toUpperCase() + cleanName.substring(1).toLowerCase();
                    
                    List<WeightRecord> records = widget.appState.exerciseProgress[cleanName] ?? [];
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
                      highestDisplay = "${highest.weight} ${highest.unit}";
                    }
                  }

                  return _CustomFloatingMenu(
                    position: _menuPosition,
                    isDivider: w.isDivider,
                    dividerHasText: w.name.isNotEmpty, 
                    isDark: isDark,
                    useMaterialYou: useMaterialYou,
                    scheme: scheme,
                    textColor: textColor,
                    highestWeight: highestDisplay, 
                    onEdit: () {
                      _closeMenu();
                      _showEditDialog(context, w, isDark, useMaterialYou, scheme, dialogBg, textColor);
                    },
                    onRemove: () {
                      widget.appState.deleteWorkout(widget.dayId, _selectedWorkoutId!);
                      _closeMenu();
                    },
                  );
                })
              ],
            ],
          ),
        );
      },
    );
  }
}

class _WorkoutRow extends StatefulWidget {
  final WorkoutItem item;
  final int index;
  final bool isSelected;
  final bool isDark;
  final bool useMaterialYou;
  final ColorScheme scheme;
  final Color textColor;
  final VoidCallback onToggleComplete;
  final Function(Offset) onOpenMenu;
  final VoidCallback onCloseMenu;

  const _WorkoutRow({
    super.key,
    required this.item,
    required this.index,
    required this.isSelected,
    required this.isDark,
    required this.useMaterialYou,
    required this.scheme,
    required this.textColor,
    required this.onToggleComplete,
    required this.onOpenMenu,
    required this.onCloseMenu,
  });

  @override
  State<_WorkoutRow> createState() => _WorkoutRowState();
}

class _WorkoutRowState extends State<_WorkoutRow> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _pulseController;
  Timer? _menuTimer;
  Offset _tapPosition = Offset.zero;
  DateTime _downTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  }

  @override
  void didUpdateWidget(covariant _WorkoutRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _pulseController.animateTo(0.0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _menuTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    widget.onCloseMenu(); 
    _tapPosition = event.position; 
    _downTime = DateTime.now();
    setState(() => _isPressed = true);
    
    _menuTimer?.cancel();
    _menuTimer = Timer(const Duration(milliseconds: 300), () {
      if (_isPressed) {
        setState(() => _isPressed = false);
        widget.onOpenMenu(_tapPosition);
      }
    });
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if ((event.position - _tapPosition).distance > 10) {
      _menuTimer?.cancel();
      if (_isPressed) setState(() => _isPressed = false);
      if (widget.isSelected) widget.onCloseMenu();
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    _menuTimer?.cancel();
    if (_isPressed) setState(() => _isPressed = false);
    
    final duration = DateTime.now().difference(_downTime).inMilliseconds;
    if (duration < 300 && (event.position - _tapPosition).distance < 10) {
      widget.onToggleComplete();
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _menuTimer?.cancel();
    if (_isPressed) setState(() => _isPressed = false);
    widget.onCloseMenu(); 
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    double baseScale = _isPressed ? 0.96 : (widget.isSelected ? 1.04 : 1.0);

    return RepaintBoundary( 
      child: ReorderableDelayedDragStartListener(
        index: widget.index,
        child: Listener(
          onPointerDown: _handlePointerDown,
          onPointerMove: _handlePointerMove,
          onPointerUp: _handlePointerUp,
          onPointerCancel: _handlePointerCancel,
          behavior: HitTestBehavior.opaque, 
          child: AnimatedScale(
            scale: baseScale,
            duration: const Duration(milliseconds: 350), 
            curve: Curves.easeOutBack,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.02).animate(_pulseController),
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 5.0),
                color: Colors.transparent, 
                child: widget.item.isDivider 
                  ? _buildDividerUI() 
                  : _buildWorkoutUI(screenWidth),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutUI(double screenWidth) {
    Color itemColor = widget.item.isCompleted 
      ? (widget.useMaterialYou ? widget.scheme.onSurfaceVariant.withOpacity(0.6) : Colors.grey) 
      : widget.textColor;
      
    Color lineStrikeColor = widget.useMaterialYou ? widget.scheme.outlineVariant : (widget.isDark ? const Color(0xFF3A3A3C) : Colors.grey.shade400);
    
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(color: itemColor, fontSize: 20),
              child: Text(widget.item.name),
            ),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(color: itemColor, fontSize: 20, fontWeight: FontWeight.bold),
              child: Text(widget.item.reps),
            ),
          ],
        ),
        IgnorePointer( 
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutQuart,
            width: widget.item.isCompleted ? screenWidth - 50 : 0, 
            height: 2,
            decoration: BoxDecoration(
              color: lineStrikeColor, 
              borderRadius: BorderRadius.circular(2)
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDividerUI() {
    Color divColor = widget.useMaterialYou ? widget.scheme.outlineVariant : (widget.isDark ? Colors.white24 : Colors.black26);
    Color divTextColor = widget.useMaterialYou ? widget.scheme.onSurfaceVariant : Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(child: Divider(color: divColor, thickness: 1)),
          if (widget.item.name.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(widget.item.name, style: TextStyle(color: divTextColor, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
            Expanded(child: Divider(color: divColor, thickness: 1)),
          ]
        ],
      ),
    );
  }
}

class _CustomFloatingMenu extends StatelessWidget {
  final Offset position;
  final bool isDivider;
  final bool dividerHasText;
  final bool isDark;
  final bool useMaterialYou;
  final ColorScheme scheme;
  final Color textColor;
  final String? highestWeight; 
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _CustomFloatingMenu({
    required this.position,
    required this.isDivider,
    required this.dividerHasText,
    required this.isDark,
    required this.useMaterialYou,
    required this.scheme,
    required this.textColor,
    this.highestWeight,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    double menuHeight = highestWeight != null ? 180.0 : 115.0;
    
    double topPos = (position.dy - menuHeight - 15).clamp(50.0, MediaQuery.of(context).size.height - menuHeight);
    double leftPos = (position.dx - 100).clamp(15.0, screenWidth - 215.0);

    final String renameText = isDivider ? (dividerHasText ? 'Rename' : 'Add text') : 'Rename';
    
    final Color menuBg = useMaterialYou ? scheme.surfaceContainer : (isDark ? const Color(0xFF1C1C1E) : Colors.white);
    final Color dividerColor = useMaterialYou ? scheme.outlineVariant : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1));

    return Positioned(
      top: topPos,
      left: leftPos,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300), 
        curve: Curves.easeOutBack, 
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            alignment: Alignment.bottomCenter, 
            child: Opacity(opacity: (value * 1.5).clamp(0.0, 1.0), child: child),
          );
        },
        child: Container(
          width: 200,
          decoration: BoxDecoration(
            color: menuBg, 
            borderRadius: BorderRadius.circular(18), 
            border: Border.all(color: dividerColor, width: 1),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.6 : 0.15), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              
              if (highestWeight != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: const BoxDecoration(
                    color: Colors.transparent, 
                    borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events, color: textColor.withOpacity(0.6), size: 20),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('All-Time High', style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600)),
                            Text(highestWeight!, style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: dividerColor),
              ],
              
              _buildMenuItem(Icons.edit_outlined, renameText, textColor, onEdit),
              Divider(height: 1, color: dividerColor),
              _buildMenuItem(Icons.delete_outline, 'Remove', Colors.redAccent, onRemove),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 14),
            Text(title, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
