import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart'; 
import '../state/workout_state.dart';
import '../models/workout_models.dart';
import '../widgets/bouncing_widget.dart';
import 'workout_page.dart';
import 'settings_page.dart';
import 'progress_page.dart'; 

class HomePage extends StatefulWidget {
  final WorkoutState appState;

  const HomePage({super.key, required this.appState});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ValueNotifier<String?> _selectedDayIdNotifier = ValueNotifier(null);
  OverlayEntry? _menuOverlayEntry; 
  Offset _menuPosition = Offset.zero;
  Offset? _globalPointerPosition; 
  
  DateTime _selectedDate = DateTime.now();
  late ScrollController _calendarScrollController;
  double _lastHapticOffset = 1004.0;

  @override
  void initState() {
    super.initState();
    _calendarScrollController = ScrollController(initialScrollOffset: 1004.0);
  }

  @override
  void dispose() {
    _calendarScrollController.dispose();
    _selectedDayIdNotifier.dispose();
    _menuOverlayEntry?.remove();
    super.dispose();
  }

  void _closeMenu() {
    if (_selectedDayIdNotifier.value != null) {
      _selectedDayIdNotifier.value = null;
      _menuOverlayEntry?.remove();
      _menuOverlayEntry = null;
    }
  }

  void _openMenu(String id, Offset position) {
    if (_menuOverlayEntry != null) {
      _menuOverlayEntry!.remove();
      _menuOverlayEntry = null;
    }
    
    _menuPosition = position;
    _selectedDayIdNotifier.value = id;

    _menuOverlayEntry = OverlayEntry(
      builder: (context) {
        final d = widget.appState.days.firstWhere((day) => day.id == id, orElse: () => widget.appState.days.first);
        bool hasImage = d.imagePath != null && File(d.imagePath!).existsSync();
        final bool isDark = widget.appState.isDarkMode;
        final Color textColor = isDark ? Colors.white : Colors.black;
        final Color dialogBg = isDark ? const Color(0xFF121212) : Colors.white;

        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _closeMenu,
                  onPanStart: (_) => _closeMenu(),
                  child: Container(color: Colors.transparent),
                ),
              ),
              _DayFloatingMenu(
                position: _menuPosition,
                isPinned: d.isPinned,
                hasImage: hasImage,
                isDark: isDark,
                textColor: textColor,
                onRename: () {
                  _closeMenu();
                  _showRenameDialog(context, d, isDark, dialogBg, textColor);
                },
                onAddPicture: () {
                  _closeMenu();
                  _pickAndCropImage(d, isDark);
                },
                onChangePicture: () {
                  _closeMenu();
                  _pickAndCropImage(d, isDark);
                },
                onEditPicture: () {
                  _closeMenu();
                  _editExistingImage(d, isDark);
                },
                onRemovePicture: () {
                  _closeMenu();
                  _removeImage(d);
                },
                onPin: () {
                  widget.appState.togglePinDay(d.id);
                  _closeMenu();
                },
                onRemove: () {
                  widget.appState.deleteDay(id);
                  _closeMenu();
                },
              ),
            ],
          ),
        );
      }
    );
    Overlay.of(context).insert(_menuOverlayEntry!);
  }

  Future<void> _pickAndCropImage(WorkoutDay day, bool isDark) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _cropImage(day, image.path, isDark);
    }
  }

  Future<void> _cropImage(WorkoutDay day, String sourcePath, bool isDark) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 10), 
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Position Picture',
          toolbarColor: isDark ? const Color(0xFF121212) : Colors.white,
          toolbarWidgetColor: isDark ? Colors.white : Colors.black,
          initAspectRatio: CropAspectRatioPreset.ratio16x9,
          lockAspectRatio: false,
        ),
      ],
    );

    if (croppedFile != null) {
      widget.appState.updateDayImage(day.id, croppedFile.path);
    }
  }

  void _editExistingImage(WorkoutDay day, bool isDark) {
    if (day.imagePath != null && File(day.imagePath!).existsSync()) {
      _cropImage(day, day.imagePath!, isDark);
    }
  }

  void _removeImage(WorkoutDay day) {
    widget.appState.updateDayImage(day.id, null);
  }

  void _showAddDayDialog(BuildContext context, bool isDark, Color dialogBg, Color textColor) {
    TextEditingController nameController = TextEditingController();
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
        return AlertDialog(
          backgroundColor: dialogBg, 
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('New Workout Day', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          content: _buildThemedTextField(controller: nameController, hint: 'e.g., Pull Day, Leg Day', textColor: textColor, isDark: isDark),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  widget.appState.addDay(nameController.text.trim());
                }
                Navigator.pop(context);
              },
              child: Text('Create', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context, WorkoutDay day, bool isDark, Color dialogBg, Color textColor) {
    TextEditingController nameController = TextEditingController(text: day.name);
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
        return AlertDialog(
          backgroundColor: dialogBg, 
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Rename Day', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          content: _buildThemedTextField(controller: nameController, hint: 'Day Name', textColor: textColor, isDark: isDark),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  widget.appState.renameDay(day.id, nameController.text.trim());
                }
                Navigator.pop(context);
              },
              child: Text('Save', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThemedTextField({required TextEditingController controller, required String hint, required Color textColor, required bool isDark}) {
    return TextField(
      controller: controller,
      style: TextStyle(color: textColor),
      cursorColor: textColor, 
      autofocus: true,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade600)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor)),
      ),
    );
  }

  String _getMonthName(int month) {
    const monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
    return monthNames[month - 1];
  }

  String _getDayName(int weekday) {
    const dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return dayNames[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, child) {
        
        final bool isDark = widget.appState.isDarkMode;
        final Color bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
        final Color textColor = isDark ? Colors.white : Colors.black;
        final Color primaryColor = isDark ? Colors.white : Colors.black;
        final Color invertedColor = isDark ? Colors.black : Colors.white;
        final Color dialogBg = isDark ? const Color(0xFF121212) : Colors.white;
        final Color frostedBg = isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.6);
        final Color borderColor = isDark ? Colors.white24 : Colors.black12;
        final Color cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white; 

        bool hasProfileImage = widget.appState.profileImagePath != null && File(widget.appState.profileImagePath!).existsSync();

        final days = widget.appState.days;
        DateTime today = DateTime.now();
        String monthYear = "${_getMonthName(today.month)}, ${today.year}";
        
        final double topPadding = MediaQuery.of(context).padding.top + 285.0; 

        return Scaffold(
          backgroundColor: bgColor,
          
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              BouncingWidget(
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  
                  Future.delayed(const Duration(milliseconds: 150), () {
                    if (!mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProgressPage(appState: widget.appState)),
                    );
                  });
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: cardColor, 
                    borderRadius: BorderRadius.circular(16), 
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Icon(Icons.insert_chart_outlined, color: textColor, size: 24), 
                ),
              ),
              const SizedBox(height: 15),
              BouncingWidget(
                onTap: () => _showAddDayDialog(context, isDark, dialogBg, textColor),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Icon(Icons.add, color: invertedColor, size: 30),
                ),
              ),
            ],
          ),
          
          body: Stack(
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: GestureDetector(
                    onTap: _closeMenu,
                    behavior: HitTestBehavior.translucent,
                    child: Listener(
                      onPointerDown: (e) => _globalPointerPosition = e.position,
                      onPointerMove: (e) {
                        if (_globalPointerPosition != null && _selectedDayIdNotifier.value != null) {
                          // The second your thumb drags the card, the menu politely vanishes
                          if ((e.position - _globalPointerPosition!).distance > 15) {
                            _closeMenu();
                          }
                        }
                      },
                      child: days.isEmpty 
                        ? Padding(
                            padding: EdgeInsets.only(top: topPadding + 20),
                            child: const Align(
                              alignment: Alignment.topCenter,
                              child: Text("Tap '+' to create your first workout day", style: TextStyle(color: Colors.grey)),
                            ),
                          )
                        : ReorderableListView.builder(
                            padding: EdgeInsets.only(top: topPadding, bottom: 100, left: 20, right: 20),
                            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                            buildDefaultDragHandles: false,
                            clipBehavior: Clip.none, 
                            proxyDecorator: (Widget child, int index, Animation<double> animation) {
                              return Material(type: MaterialType.transparency, elevation: 0, color: Colors.transparent, child: child);
                            },
                            itemCount: days.length,
                            onReorderStart: (index) {
                              HapticFeedback.selectionClick();
                              
                              // THE FIX: The exact moment Flutter lifts the card into the Drag Overlay, 
                              // we wait 1 microsecond and pop the Menu Overlay back on top of it!
                              Future.microtask(() {
                                if (_menuOverlayEntry != null && _menuOverlayEntry!.mounted) {
                                  _menuOverlayEntry!.remove();
                                  Overlay.of(context).insert(_menuOverlayEntry!);
                                }
                              });
                            },
                            onReorder: (oldIndex, newIndex) {
                              _closeMenu();
                              widget.appState.reorderDays(oldIndex, newIndex);
                            },
                            itemBuilder: (context, index) {
                              final day = days[index];
                              return _DayCard(
                                key: ValueKey(day.id),
                                day: day,
                                index: index, 
                                selectedIdNotifier: _selectedDayIdNotifier, 
                                isDark: isDark,
                                textColor: textColor,
                                onTap: () {
                                  _closeMenu();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => WorkoutPage(appState: widget.appState, dayId: day.id),
                                    ),
                                  );
                                },
                                onOpenMenu: (pos) => _openMenu(day.id, pos),
                                onCloseMenu: _closeMenu,
                              );
                            },
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
                        top: MediaQuery.of(context).padding.top + 25,
                        left: 20, 
                        right: 20,
                        bottom: 15,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'My Workouts', 
                                style: TextStyle(fontFamily: 'WorkoutFont', fontSize: 42, color: textColor, height: 1.0),
                              ),
                              BouncingWidget(
                                onTap: () {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  Future.delayed(const Duration(milliseconds: 50), () {
                                    if (!mounted) return;
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        transitionDuration: const Duration(milliseconds: 250),
                                        reverseTransitionDuration: const Duration(milliseconds: 150),
                                        pageBuilder: (context, animation, secondaryAnimation) => SettingsPage(appState: widget.appState),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                          return ScaleTransition(
                                            alignment: const Alignment(0.8, -0.8),
                                            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeIn),
                                            child: FadeTransition(opacity: animation, child: child),
                                          );
                                        },
                                      ),
                                    );
                                  });
                                },
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: borderColor, width: 1.5),
                                    image: hasProfileImage
                                        ? DecorationImage(image: FileImage(File(widget.appState.profileImagePath!)), fit: BoxFit.cover)
                                        : null,
                                  ),
                                  child: !hasProfileImage ? Icon(Icons.person, color: textColor, size: 24) : null,
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 25),
                          
                          Text(monthYear, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          
                          ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                                stops: [0.0, 0.1, 0.9, 1.0], 
                              ).createShader(bounds);
                            },
                            blendMode: BlendMode.dstIn,
                            child: SizedBox(
                              height: 75,
                              child: NotificationListener<ScrollUpdateNotification>(
                                onNotification: (notification) {
                                  if ((notification.metrics.pixels - _lastHapticOffset).abs() > 40) {
                                    HapticFeedback.selectionClick();
                                    _lastHapticOffset = notification.metrics.pixels;
                                  }
                                  return false;
                                },
                                child: ListView.builder(
                                  controller: _calendarScrollController,
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: 30,
                                  itemBuilder: (context, index) {
                                    DateTime date = today.add(Duration(days: index - 15));
                                    bool isToday = date.day == today.day && date.month == today.month && date.year == today.year;
                                    
                                    return AnimatedBuilder(
                                      animation: _calendarScrollController,
                                      builder: (context, child) {
                                        double scrollOffset = _calendarScrollController.hasClients ? _calendarScrollController.offset : 1004.0;
                                        double listViewWidth = MediaQuery.of(context).size.width - 40; 
                                        
                                        double itemCenter = (index * 72.0) + 30.0; 
                                        
                                        double distanceFromLeft = itemCenter - scrollOffset;
                                        double distanceFromRight = (scrollOffset + listViewWidth) - itemCenter;
                                        double edgeDistance = distanceFromLeft < distanceFromRight ? distanceFromLeft : distanceFromRight;
                                        
                                        double scale = 1.0;
                                        if (edgeDistance < 60) {
                                          scale = (edgeDistance / 60).clamp(0.88, 1.0);
                                        }
                                        
                                        return Transform.scale(
                                          scale: scale,
                                          child: child,
                                        );
                                      },
                                      child: GestureDetector(
                                        onTap: () => HapticFeedback.lightImpact(),
                                        child: Container(
                                          margin: const EdgeInsets.only(right: 12),
                                          width: 60,
                                          decoration: BoxDecoration(
                                            color: isToday ? primaryColor : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
                                            borderRadius: BorderRadius.circular(18),
                                            boxShadow: !isDark ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] : [],
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                _getDayName(date.weekday),
                                                style: TextStyle(
                                                  color: isToday ? invertedColor : Colors.grey, 
                                                  fontSize: 13, 
                                                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${date.day}',
                                                style: TextStyle(
                                                  color: isToday ? invertedColor : textColor, 
                                                  fontSize: 18, 
                                                  fontWeight: FontWeight.bold
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          
                          Text('My Schedule >', style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
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

class _DayCard extends StatefulWidget {
  final WorkoutDay day;
  final int index; 
  final ValueNotifier<String?> selectedIdNotifier; 
  final bool isDark;
  final Color textColor;
  final VoidCallback onTap;
  final Function(Offset) onOpenMenu;
  final VoidCallback onCloseMenu;

  const _DayCard({
    super.key,
    required this.day,
    required this.index,
    required this.selectedIdNotifier,
    required this.isDark,
    required this.textColor,
    required this.onTap,
    required this.onOpenMenu,
    required this.onCloseMenu,
  });

  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _pulseController;
  Timer? _menuTimer;
  Offset _tapPosition = Offset.zero;
  DateTime _downTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..addListener(() => setState(() {}));
    widget.selectedIdNotifier.addListener(_onSelectionChanged); 
  }

  @override
  void dispose() {
    widget.selectedIdNotifier.removeListener(_onSelectionChanged);
    _menuTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _onSelectionChanged() {
    if (!mounted) return;
    bool isSelected = widget.selectedIdNotifier.value == widget.day.id;
    if (isSelected) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.animateTo(0.0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
    setState(() {}); 
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
    if ((event.position - _tapPosition).distance > 15) {
      _menuTimer?.cancel();
      if (_isPressed) setState(() => _isPressed = false);
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    _menuTimer?.cancel();
    if (_isPressed) setState(() => _isPressed = false);

    final duration = DateTime.now().difference(_downTime).inMilliseconds;
    if (duration < 300 && (event.position - _tapPosition).distance < 15) {
      widget.onTap();
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _menuTimer?.cancel();
    if (_isPressed) setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    bool isSelected = widget.selectedIdNotifier.value == widget.day.id;
    double baseScale = _isPressed ? 0.95 : (isSelected ? 1.03 : 1.0);
    double pulseScale = isSelected ? 1.0 + (_pulseController.value * 0.02) : 1.0;

    bool hasImage = widget.day.imagePath != null && File(widget.day.imagePath!).existsSync();
    Color cardColor = widget.isDark ? const Color(0xFF141414) : Colors.white;
    Color displayTextColor = hasImage ? Colors.white : widget.textColor; 

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: RepaintBoundary(
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
              child: Transform.scale(
                scale: pulseScale,
                alignment: Alignment.center,
                child: Container(
                  height: 180, 
                  decoration: BoxDecoration(
                    color: cardColor, 
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: !widget.isDark ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)] : [],
                    image: hasImage
                        ? DecorationImage(
                            image: FileImage(File(widget.day.imagePath!)),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
                          )
                        : null,
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.day.name,
                              style: TextStyle(color: displayTextColor, fontSize: 26, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (widget.day.isPinned)
                        Positioned(
                          top: 20,
                          right: 22,
                          child: Icon(Icons.push_pin, color: displayTextColor.withOpacity(0.8), size: 22),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayFloatingMenu extends StatelessWidget {
  final Offset position;
  final bool isPinned;
  final bool hasImage;
  final bool isDark;
  final Color textColor;
  final VoidCallback onRename;
  final VoidCallback onAddPicture;
  final VoidCallback onChangePicture;
  final VoidCallback onEditPicture;
  final VoidCallback onRemovePicture;
  final VoidCallback onPin;
  final VoidCallback onRemove;

  const _DayFloatingMenu({
    required this.position,
    required this.isPinned,
    required this.hasImage,
    required this.isDark,
    required this.textColor,
    required this.onRename,
    required this.onAddPicture,
    required this.onChangePicture,
    required this.onEditPicture,
    required this.onRemovePicture,
    required this.onPin,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    double menuHeight = hasImage ? 310.0 : 205.0; 
    double topPos = (position.dy - menuHeight - 15).clamp(80.0, MediaQuery.of(context).size.height - menuHeight - 20);
    double leftPos = (position.dx - 110).clamp(15.0, screenWidth - 235.0);

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
          width: 220,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white, 
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05), width: 1),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.6 : 0.15), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMenuItem(Icons.edit_outlined, 'Rename', textColor, onRename),
              Divider(height: 1, color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
              
              if (hasImage) ...[
                _buildMenuItem(Icons.image_outlined, 'Change picture', textColor, onChangePicture),
                Divider(height: 1, color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
                _buildMenuItem(Icons.crop, 'Crop & Position', textColor, onEditPicture),
                Divider(height: 1, color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
                _buildMenuItem(Icons.hide_image_outlined, 'Remove picture', textColor, onRemovePicture),
              ] else ...[
                _buildMenuItem(Icons.add_photo_alternate_outlined, 'Add picture', textColor, onAddPicture),
              ],
              
              Divider(height: 1, color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
              _buildMenuItem(Icons.push_pin_outlined, isPinned ? 'Unpin' : 'Pin to top', textColor, onPin),
              Divider(height: 1, color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
              _buildMenuItem(Icons.delete_outline, 'Delete', Colors.redAccent, onRemove),
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
