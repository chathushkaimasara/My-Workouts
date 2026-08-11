import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; 
import 'package:flutter/services.dart'; 
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart'; 
import 'package:shared_preferences/shared_preferences.dart'; 
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

  @override
  void dispose() {
    _selectedDayIdNotifier.dispose();
    _closeMenu(); 
    super.dispose();
  }

  void _closeMenu() {
    if (_selectedDayIdNotifier.value != null) {
      _selectedDayIdNotifier.value = null;
      if (_menuOverlayEntry != null && _menuOverlayEntry!.mounted) {
        _menuOverlayEntry!.remove();
      }
      _menuOverlayEntry = null;
    }
  }

  void _openMenu(String id, Offset position) {
    if (_menuOverlayEntry != null && _menuOverlayEntry!.mounted) {
      _menuOverlayEntry!.remove();
      _menuOverlayEntry = null;
    }
    
    _menuPosition = position;
    _selectedDayIdNotifier.value = id;

    _menuOverlayEntry = OverlayEntry(
      builder: (context) {
        final d = widget.appState.days.firstWhere((day) => day.id == id, orElse: () => widget.appState.days.first);
        
        bool hasImage = d.imagePath != null && d.imagePath!.isNotEmpty;
        final bool isDark = widget.appState.isDarkMode;
        final bool useMaterialYou = widget.appState.useMaterialYou;
        final ColorScheme scheme = Theme.of(context).colorScheme;

        final Color textColor = useMaterialYou ? scheme.onSurface : (isDark ? Colors.white : Colors.black);
        final Color dialogBg = useMaterialYou ? scheme.surfaceContainerHigh : (isDark ? const Color(0xFF121212) : Colors.white);

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
                useMaterialYou: useMaterialYou,
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
    if (day.imagePath != null && day.imagePath!.isNotEmpty) {
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
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return AlertDialog(
          backgroundColor: dialogBg, 
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('New Workout Day', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          content: _buildThemedTextField(controller: nameController, hint: 'e.g., Pull Day, Leg Day', textColor: textColor, isDark: isDark),
          actions: [
            TextButton(
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                if (nameController.text.trim().isNotEmpty) {
                  widget.appState.addDay(nameController.text.trim());
                }
                Navigator.pop(dialogContext);
              },
              child: Text('Create', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    ).then((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        nameController.dispose();
      });
    });
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
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return AlertDialog(
          backgroundColor: dialogBg, 
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Rename Day', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          content: _buildThemedTextField(controller: nameController, hint: 'Day Name', textColor: textColor, isDark: isDark),
          actions: [
            TextButton(
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                if (nameController.text.trim().isNotEmpty) {
                  widget.appState.renameDay(day.id, nameController.text.trim());
                }
                Navigator.pop(dialogContext);
              },
              child: Text('Save', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    ).then((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        nameController.dispose();
      });
    });
  }

  void _showEditQuoteDialog(BuildContext context, Color dialogBg, Color textColor, Color schemePrimary) {
    TextEditingController quoteController = TextEditingController(text: widget.appState.customQuote);
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
          title: Text('Motivational Quote', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: quoteController,
            style: TextStyle(color: textColor),
            cursorColor: textColor, 
            autofocus: true,
            maxLines: null,
            decoration: InputDecoration(
              hintText: 'Enter your quote here...',
              hintStyle: const TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade600)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: schemePrimary)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                if (quoteController.text.trim().isNotEmpty) {
                  widget.appState.updateCustomQuote(quoteController.text.trim());
                }
                Navigator.pop(dialogContext);
              },
              child: Text('Save', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    ).then((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        quoteController.dispose();
      });
    });
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

  Widget _buildQuoteWidget(ColorScheme scheme, Color dialogBg, Color textColor) {
    return BouncingWidget(
      onTap: () => _showEditQuoteDialog(context, dialogBg, textColor, scheme.primary),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: scheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.primary.withOpacity(0.3)),
        ),
        child: Text(
          '"${widget.appState.customQuote}"',
          style: TextStyle(color: scheme.primary, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, fontSize: 15),
          textAlign: TextAlign.center,
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

        final bool isPremiumBlack = !useMaterialYou && widget.appState.themePresetId == 'default_black';

        final Color bgColor = isPremiumBlack ? (isDark ? Colors.black : const Color(0xFFF2F2F7)) : scheme.surface;
        final Color textColor = isPremiumBlack ? (isDark ? Colors.white : Colors.black) : scheme.onSurface;
        final Color primaryColor = isPremiumBlack ? (isDark ? Colors.white : Colors.black) : scheme.primary;
        final Color invertedColor = isPremiumBlack ? (isDark ? Colors.black : Colors.white) : scheme.onPrimary;
        final Color dialogBg = isPremiumBlack ? (isDark ? const Color(0xFF121212) : Colors.white) : scheme.surfaceContainerHigh;
        final Color frostedBg = isPremiumBlack ? (isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.6)) : scheme.surface.withOpacity(0.6);
        final Color borderColor = isPremiumBlack ? (isDark ? Colors.white24 : Colors.black12) : scheme.outlineVariant;
        final Color progressBtnBg = isPremiumBlack ? (isDark ? const Color(0xFF2C2C2E).withOpacity(0.9) : Colors.white.withOpacity(0.9)) : scheme.surfaceContainerHigh.withOpacity(0.9);

        bool hasProfileImage = widget.appState.profileImagePath != null && widget.appState.profileImagePath!.isNotEmpty;
        final days = widget.appState.days;
        
        double dynamicTopPadding = MediaQuery.of(context).padding.top + 145.0; 
        if (widget.appState.showQuote) dynamicTopPadding += 70.0;
        if (widget.appState.showCalendar) dynamicTopPadding += 132.0;
        if (widget.appState.showTimer) dynamicTopPadding += 73.0;

        return Scaffold(
          backgroundColor: bgColor,
          
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              BouncingWidget(
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProgressPage(appState: widget.appState)),
                  );
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: progressBtnBg,
                    border: Border.all(
                      color: useMaterialYou ? scheme.outline.withOpacity(0.2) : (isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.08)), 
                      width: 0.5
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.4 : 0.15), 
                        blurRadius: 12, 
                        offset: const Offset(0, 4)
                      )
                    ],
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
                child: GestureDetector(
                  onTap: _closeMenu,
                  behavior: HitTestBehavior.translucent,
                  child: Listener(
                    onPointerDown: (e) => _globalPointerPosition = e.position,
                    onPointerMove: (e) {
                      if (_globalPointerPosition != null && _selectedDayIdNotifier.value != null) {
                        if ((e.position - _globalPointerPosition!).distance > 15) {
                          _closeMenu();
                        }
                      }
                    },
                    child: days.isEmpty 
                      ? Padding(
                          padding: EdgeInsets.only(top: dynamicTopPadding + 20),
                          child: const Align(
                            alignment: Alignment.topCenter,
                            child: Text("Tap '+' to create your first workout day", style: TextStyle(color: Colors.grey)),
                          ),
                        )
                      : ReorderableListView.builder(
                          padding: EdgeInsets.only(top: dynamicTopPadding, bottom: 100, left: 20, right: 20),
                          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                          buildDefaultDragHandles: false,
                          clipBehavior: Clip.none, 
                          proxyDecorator: (Widget child, int index, Animation<double> animation) {
                            return Material(type: MaterialType.transparency, elevation: 0, color: Colors.transparent, child: child);
                          },
                          itemCount: days.length,
                          onReorderStart: (index) {
                            HapticFeedback.selectionClick();
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
                            return Padding(
                              key: ValueKey(day.id),
                              padding: const EdgeInsets.only(bottom: 20.0),
                              child: RepaintBoundary(
                                child: _DayCard(
                                  day: day,
                                  index: index, 
                                  selectedIdNotifier: _selectedDayIdNotifier, 
                                  isDark: isDark,
                                  useMaterialYou: useMaterialYou,
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
                                ),
                              ),
                            );
                          },
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
                              Expanded(
                                child: Text(
                                  'My Workouts', 
                                  style: TextStyle(
                                    fontFamily: 'WorkoutFont', 
                                    fontSize: 34, 
                                    color: textColor, 
                                    height: 1.0
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 15),
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
                                    border: Border.all(color: borderColor, width: 0.5),
                                    color: hasProfileImage ? null : Colors.transparent,
                                  ),
                                  child: hasProfileImage 
                                    ? ClipOval(
                                        child: Image.file(
                                          File(widget.appState.profileImagePath!),
                                          fit: BoxFit.cover,
                                          cacheWidth: 100,
                                          gaplessPlayback: true,
                                        ),
                                      )
                                    : Icon(Icons.person, color: textColor, size: 24),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 25),
                          
                          ...widget.appState.homeWidgetOrder.map((widgetName) {
                            if (widgetName == 'quote' && widget.appState.showQuote) {
                              return Padding(
                                key: const ValueKey('home_widget_quote'),
                                padding: const EdgeInsets.only(bottom: 20),
                                child: _buildQuoteWidget(scheme, dialogBg, textColor),
                              );
                            } else if (widgetName == 'calendar' && widget.appState.showCalendar) {
                              return Padding(
                                key: const ValueKey('home_widget_calendar'),
                                padding: const EdgeInsets.only(bottom: 20),
                                child: _HomeCalendarWidget(
                                  isDark: isDark,
                                  useMaterialYou: useMaterialYou,
                                  scheme: scheme,
                                  primaryColor: primaryColor,
                                  invertedColor: invertedColor,
                                  textColor: textColor,
                                ),
                              );
                            } else if (widgetName == 'timer' && widget.appState.showTimer) {
                              return Padding(
                                key: const ValueKey('home_widget_timer'),
                                padding: const EdgeInsets.only(bottom: 20),
                                child: _WorkoutTimerWidget(
                                  isDark: isDark,
                                  useMaterialYou: useMaterialYou,
                                  scheme: scheme,
                                  textColor: textColor,
                                  primaryColor: primaryColor,
                                  invertedColor: invertedColor,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }).toList(),
                          
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

// ---------------------------------------------------------
// ISOLATED CALENDAR WIDGET 
// ---------------------------------------------------------
class _HomeCalendarWidget extends StatefulWidget {
  final bool isDark;
  final bool useMaterialYou;
  final ColorScheme scheme;
  final Color primaryColor;
  final Color invertedColor;
  final Color textColor;

  const _HomeCalendarWidget({
    super.key,
    required this.isDark,
    required this.useMaterialYou,
    required this.scheme,
    required this.primaryColor,
    required this.invertedColor,
    required this.textColor,
  });

  @override
  State<_HomeCalendarWidget> createState() => _HomeCalendarWidgetState();
}

class _HomeCalendarWidgetState extends State<_HomeCalendarWidget> {
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
    super.dispose();
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
    DateTime today = DateTime.now();
    String monthYear = "${_getMonthName(today.month)}, ${today.year}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(monthYear, style: TextStyle(color: widget.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        // THE FIX: Isolated ShaderMask in a RepaintBoundary to eliminate 60fps GPU recalculations
        RepaintBoundary(
          child: ShaderMask(
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
                    
                    final Color unselectedChipBg = widget.useMaterialYou
                        ? widget.scheme.surfaceContainerLow
                        : (widget.isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.05));
          
                    return AnimatedBuilder(
                      animation: _calendarScrollController,
                      builder: (context, child) {
                        double scrollOffset = (_calendarScrollController.hasClients && _calendarScrollController.positions.length == 1)
                            ? _calendarScrollController.offset
                            : 1004.0;
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
                            borderRadius: BorderRadius.circular(18),
                            color: isToday ? widget.primaryColor : unselectedChipBg,
                            border: isToday 
                              ? null 
                              : Border.all(
                                  color: widget.useMaterialYou ? widget.scheme.outlineVariant.withOpacity(0.5) : (widget.isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.08)), 
                                  width: 0.5
                                ),
                            boxShadow: !widget.isDark && !isToday ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)] : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getDayName(date.weekday),
                                style: TextStyle(
                                  color: isToday ? widget.invertedColor : Colors.grey, 
                                  fontSize: 13, 
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${date.day}',
                                style: TextStyle(
                                  color: isToday ? widget.invertedColor : widget.textColor, 
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
        ),
      ],
    );
  }
}

// ---------------------------------------------------------
// CUSTOM WORKOUT REST TIMER WIDGET
// ---------------------------------------------------------
class _WorkoutTimerWidget extends StatefulWidget {
  final bool isDark;
  final bool useMaterialYou;
  final ColorScheme scheme;
  final Color textColor;
  final Color primaryColor;
  final Color invertedColor;

  const _WorkoutTimerWidget({
    required this.isDark,
    required this.useMaterialYou,
    required this.scheme,
    required this.textColor,
    required this.primaryColor,
    required this.invertedColor,
  });

  @override
  State<_WorkoutTimerWidget> createState() => _WorkoutTimerWidgetState();
}

enum TimerState { stopped, running, paused, finished }

class _WorkoutTimerWidgetState extends State<_WorkoutTimerWidget> with SingleTickerProviderStateMixin {
  TimerState _state = TimerState.stopped;
  int _durationSeconds = 40; 
  int _remainingSeconds = 40;
  Timer? _timer;
  late FixedExtentScrollController _pickerController;

  DateTime _lastTapTime = DateTime.now();
  double _buttonScale = 1.0;

  @override
  void initState() {
    super.initState();
    _pickerController = FixedExtentScrollController(initialItem: 7); 
    _loadSavedDuration();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pickerController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedDuration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSecs = prefs.getInt('workout_timer_duration') ?? 40;
      if (mounted) {
        setState(() {
          _durationSeconds = savedSecs;
          _remainingSeconds = savedSecs;
          _pickerController.jumpToItem((savedSecs ~/ 5) - 1);
        });
      }
    } catch (e) {
      debugPrint('Error loading timer pref: $e');
    }
  }

  void _triggerBounceAnimation() {
    setState(() => _buttonScale = 1.15);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _buttonScale = 1.0);
    });
  }

  void _handleTap() {
    final now = DateTime.now();
    final isDoubleTap = now.difference(_lastTapTime).inMilliseconds < 300;
    _lastTapTime = now;

    _triggerBounceAnimation();

    if (isDoubleTap && _state != TimerState.stopped) {
      HapticFeedback.mediumImpact();
      _resetTimer();
    } else {
      HapticFeedback.lightImpact();
      if (_state == TimerState.stopped || _state == TimerState.paused) {
        _startTimer();
      } else if (_state == TimerState.running) {
        _pauseTimer();
      } else if (_state == TimerState.finished) {
        _resetTimer();
      }
    }
  }

  void _startTimer() {
    setState(() => _state = TimerState.running);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // THE FIX: Strict unmounted checks prevent the timer from triggering setState on disposed widgets!
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _state = TimerState.finished;
          _timer?.cancel();
          HapticFeedback.heavyImpact(); 
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _state = TimerState.paused);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _state = TimerState.stopped;
      _remainingSeconds = _durationSeconds;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color trackColor = widget.useMaterialYou
        ? widget.scheme.surfaceContainerHigh
        : (widget.isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.05));

    return SizedBox(
      height: 48, 
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _handleTap,
            onLongPress: () {
              if (_state != TimerState.stopped) {
                HapticFeedback.mediumImpact();
                _triggerBounceAnimation();
                _resetTimer();
              }
            },
            behavior: HitTestBehavior.opaque,
            child: AnimatedScale(
              scale: _buttonScale,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _state == TimerState.running ? trackColor : widget.primaryColor,
                  border: Border.all(
                    color: _state == TimerState.running ? widget.textColor.withOpacity(0.1) : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                    child: child,
                  ),
                  child: Icon(
                    _state == TimerState.running
                        ? Icons.pause_rounded
                        : _state == TimerState.finished
                            ? Icons.replay_rounded
                            : Icons.play_arrow_rounded,
                    key: ValueKey(_state),
                    color: _state == TimerState.running ? widget.textColor : widget.invertedColor,
                    size: 24, 
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                double targetSeconds = _remainingSeconds.toDouble();
                if (_state == TimerState.running && _remainingSeconds > 0) {
                  targetSeconds -= 1.0;
                }

                double fillPercentage = _durationSeconds == 0 ? 0 : 1.0 - (targetSeconds / _durationSeconds);
                if (_state == TimerState.stopped) fillPercentage = 0.0;

                return Container(
                  height: 24, 
                  decoration: BoxDecoration(
                    color: trackColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: _state == TimerState.running ? 1000 : 300),
                    curve: _state == TimerState.running ? Curves.linear : Curves.easeOutCubic,
                    width: constraints.maxWidth * fillPercentage,
                    height: 24,
                    decoration: BoxDecoration(
                      color: widget.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),

          SizedBox(
            width: 60,
            height: 48,
            child: IgnorePointer(
              ignoring: _state == TimerState.running,
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                    stops: [0.0, 0.35, 0.65, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: CupertinoPicker(
                  scrollController: _pickerController,
                  itemExtent: 32,
                  diameterRatio: 1.2,
                  squeeze: 1.1,
                  selectionOverlay: const CupertinoPickerDefaultSelectionOverlay(background: Colors.transparent),
                  onSelectedItemChanged: (index) async {
                    HapticFeedback.selectionClick(); 
                    
                    int newSecs = (index + 1) * 5;
                    setState(() {
                      _durationSeconds = newSecs;
                      _remainingSeconds = newSecs; 
                      _state = TimerState.stopped;
                    });
                    
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt('workout_timer_duration', newSecs);
                    } catch (e) {
                      debugPrint('Error saving timer pref: $e');
                    }
                  },
                  children: List.generate(60, (index) {
                    int secs = (index + 1) * 5;
                    return Center(
                      child: Text(
                        '${secs}s',
                        style: TextStyle(
                          color: widget.textColor, 
                          fontSize: 24, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// CUSTOM DAY CARD WIDGET
// ---------------------------------------------------------
class _DayCard extends StatefulWidget {
  final WorkoutDay day;
  final int index; 
  final ValueNotifier<String?> selectedIdNotifier; 
  final bool isDark;
  final bool useMaterialYou;
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
    required this.useMaterialYou,
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
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
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

    bool hasImage = widget.day.imagePath != null && widget.day.imagePath!.isNotEmpty;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    
    Color cardColor = widget.useMaterialYou ? scheme.surfaceContainer : (widget.isDark ? const Color(0xFF141414) : Colors.white);
    Color displayTextColor = hasImage ? Colors.white : widget.textColor; 

    return ReorderableDelayedDragStartListener(
      index: widget.index,
      child: Listener(
        onPointerDown: _handlePointerDown,
        onPointerMove: _handlePointerMove,
        onPointerUp: _handlePointerUp,
        onPointerCancel: _handlePointerCancel,
        behavior: HitTestBehavior.opaque,
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 1.02).animate(_pulseController),
          child: AnimatedScale(
            scale: baseScale,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            child: Container(
              height: 180, 
              decoration: BoxDecoration(
                color: cardColor, 
                borderRadius: BorderRadius.circular(24),
                boxShadow: !widget.isDark && !widget.useMaterialYou ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)] : [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasImage)
                      Image.file(
                        File(widget.day.imagePath!),
                        fit: BoxFit.cover,
                        cacheWidth: 500,
                        gaplessPlayback: true,
                        colorBlendMode: BlendMode.darken,
                        color: Colors.black.withOpacity(0.4),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.day.name,
                            maxLines: 3, 
                            style: TextStyle(
                              color: displayTextColor, 
                              fontSize: 22, 
                              fontWeight: FontWeight.bold,
                              height: 1.15, 
                            ),
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
    );
  }
}

class _DayFloatingMenu extends StatelessWidget {
  final Offset position;
  final bool isPinned;
  final bool hasImage;
  final bool isDark;
  final bool useMaterialYou;
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
    required this.useMaterialYou,
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
    final ColorScheme scheme = Theme.of(context).colorScheme;

    double menuHeight = hasImage ? 310.0 : 205.0; 
    double topPos = (position.dy - menuHeight - 15).clamp(80.0, MediaQuery.of(context).size.height - menuHeight - 20);
    double leftPos = (position.dx - 110).clamp(15.0, screenWidth - 235.0);

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
          width: 220,
          decoration: BoxDecoration(
            color: menuBg, 
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: dividerColor, width: 1),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.6 : 0.15), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMenuItem(Icons.edit_outlined, 'Rename', textColor, onRename),
              Divider(height: 1, color: dividerColor),
              
              if (hasImage) ...[
                _buildMenuItem(Icons.image_outlined, 'Change picture', textColor, onChangePicture),
                Divider(height: 1, color: dividerColor),
                _buildMenuItem(Icons.crop, 'Crop & Position', textColor, onEditPicture),
                Divider(height: 1, color: dividerColor),
                _buildMenuItem(Icons.hide_image_outlined, 'Remove picture', textColor, onRemovePicture),
              ] else ...[
                _buildMenuItem(Icons.add_photo_alternate_outlined, 'Add picture', textColor, onAddPicture),
              ],
              
              Divider(height: 1, color: dividerColor),
              _buildMenuItem(Icons.push_pin_outlined, isPinned ? 'Unpin' : 'Pin to top', textColor, onPin),
              Divider(height: 1, color: dividerColor),
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
