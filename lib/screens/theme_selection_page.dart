import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart'; 
import '../state/workout_state.dart';
import '../widgets/bouncing_widget.dart';

class ThemeSelectionPage extends StatelessWidget {
  final WorkoutState appState;

  const ThemeSelectionPage({super.key, required this.appState});

  void _showColorPickerDialog(BuildContext context, bool isDark, Color dialogBg, Color textColor) {
    Color pickerColor = appState.customThemeColor; 

    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      transitionDuration: const Duration(milliseconds: 300), 
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack)
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return AlertDialog(
          backgroundColor: dialogBg,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Pick Custom Color', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: _OptimizedColorPicker(
              initialColor: pickerColor,
              onColorChanged: (color) => pickerColor = color,
            ),
          ),
          actions: [
            BouncingWidget(
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
              ),
            ),
            BouncingWidget(
              onTap: () {
                appState.setCustomThemeColor(pickerColor);
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Apply Theme', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, child) {
        
        final bool isDark = appState.isDarkMode;
        final ColorScheme scheme = Theme.of(context).colorScheme;
        final bool isPremiumBlack = !appState.useMaterialYou && appState.themePresetId == 'default_black';

        final Color bgColor = isPremiumBlack ? (isDark ? Colors.black : const Color(0xFFF2F2F7)) : scheme.surface;
        final Color textColor = isPremiumBlack ? (isDark ? Colors.white : Colors.black) : scheme.onSurface;
        final Color subTextColor = isPremiumBlack ? (isDark ? Colors.grey : Colors.grey.shade600) : scheme.onSurfaceVariant;
        final Color cardColor = isPremiumBlack ? (isDark ? const Color(0xFF141414) : Colors.white) : scheme.surfaceContainer;
        final Color dialogBg = isPremiumBlack ? (isDark ? const Color(0xFF121212) : Colors.white) : scheme.surfaceContainerHigh;
        final Color frostedBg = isPremiumBlack ? (isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.6)) : scheme.surface.withOpacity(isDark ? 0.8 : 0.7);
        final Color dividerColor = isPremiumBlack ? (isDark ? Colors.white24 : Colors.black12) : scheme.outlineVariant.withOpacity(0.5);

        final double topPadding = MediaQuery.of(context).padding.top + 80.0;
        final List<AppThemePreset> visiblePresets = appThemePresets.where((p) => p.id != 'custom_color').toList();

        return Scaffold(
          backgroundColor: bgColor,
          body: Stack(
            children: [
              Positioned.fill(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.only(top: topPadding + 20, left: 20, right: 20),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Custom Theme', style: TextStyle(color: subTextColor, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            
                            CustomThemeCard(
                              appState: appState,
                              isDark: isDark,
                              isPremiumBlack: isPremiumBlack,
                              scheme: scheme,
                              cardColor: cardColor,
                              textColor: textColor,
                              subTextColor: subTextColor,
                              dividerColor: dividerColor,
                              onTap: () => _showColorPickerDialog(context, isDark, dialogBg, textColor),
                            ),

                            if (appState.customColorHistory.isNotEmpty) ...[
                              const SizedBox(height: 35),
                              Text('Recent Colors', style: TextStyle(color: subTextColor, fontSize: 14, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 48,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  clipBehavior: Clip.none, 
                                  itemCount: appState.customColorHistory.length,
                                  itemBuilder: (context, index) {
                                    return RecentColorCircle(
                                      historyColor: appState.customColorHistory[index],
                                      appState: appState,
                                      textColor: textColor,
                                      dividerColor: dividerColor,
                                      isDark: isDark,
                                    );
                                  },
                                ),
                              ),
                            ],
                            
                            const SizedBox(height: 35),
                            Divider(color: dividerColor),
                            const SizedBox(height: 25),

                            Text('Curated Presets', style: TextStyle(color: subTextColor, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 15),
                          ],
                        ),
                      ),
                    ),
                    
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 0.85,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return CuratedPresetCard(
                              preset: visiblePresets[index],
                              appState: appState,
                              isDark: isDark,
                              isPremiumBlack: isPremiumBlack,
                              scheme: scheme,
                              cardColor: cardColor,
                              textColor: textColor,
                              subTextColor: subTextColor,
                            );
                          },
                          childCount: visiblePresets.length,
                        ),
                      ),
                    ),
                    
                    const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
                  ],
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
                      child: Row(
                        children: [
                          BouncingWidget(
                            onTap: () => Navigator.pop(context),
                            child: CircleAvatar(
                              radius: 20, 
                              backgroundColor: cardColor, 
                              child: Icon(Icons.arrow_back_ios_new, color: textColor, size: 18)
                            ),
                          ),
                          const SizedBox(width: 15),
                          Text('Theme Presets', style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.bold)),
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

// -----------------------------------------------------------------------------
// PERFORMANCE FIX: Dialog Color Picker
// -----------------------------------------------------------------------------
class _OptimizedColorPicker extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;

  const _OptimizedColorPicker({required this.initialColor, required this.onColorChanged});

  @override
  State<_OptimizedColorPicker> createState() => _OptimizedColorPickerState();
}

class _OptimizedColorPickerState extends State<_OptimizedColorPicker> {
  bool _showPicker = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _showPicker = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showPicker) {
      return const SizedBox(height: 350, child: Center(child: CircularProgressIndicator()));
    }
    return ColorPicker(
      pickerColor: widget.initialColor,
      onColorChanged: widget.onColorChanged,
      colorPickerWidth: 280.0,
      pickerAreaHeightPercent: 0.8,
      enableAlpha: false,
      displayThumbColor: true,
      paletteType: PaletteType.hsvWithHue,
      labelTypes: const [], 
      pickerAreaBorderRadius: BorderRadius.circular(16),
    );
  }
}

// -----------------------------------------------------------------------------
// HARDWARE ACCELERATED CARDS & BUTTONS WITH SCROLL PROTECTION
// -----------------------------------------------------------------------------

class CustomThemeCard extends StatefulWidget {
  final WorkoutState appState;
  final bool isDark;
  final bool isPremiumBlack;
  final ColorScheme scheme;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final Color dividerColor;
  final VoidCallback onTap;

  const CustomThemeCard({
    super.key, required this.appState, required this.isDark, required this.isPremiumBlack, 
    required this.scheme, required this.cardColor, required this.textColor, 
    required this.subTextColor, required this.dividerColor, required this.onTap
  });

  @override
  State<CustomThemeCard> createState() => _CustomThemeCardState();
}

class _CustomThemeCardState extends State<CustomThemeCard> with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _splashController;
  
  Offset _tapPosition = Offset.zero;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _splashController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _splashController.dispose();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    _tapPosition = event.position;
    _isScrolling = false;
    _bounceController.forward();
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_isScrolling && (event.position - _tapPosition).distance > 10) {
      _isScrolling = true;
      _bounceController.reverse();
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _isScrolling = false;
    _bounceController.reverse();
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (!_isScrolling) {
      HapticFeedback.selectionClick();
      _splashController.forward(from: 0.0);
      widget.onTap();
    }
    _isScrolling = false;
    _bounceController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final bool isCustomSelected = widget.appState.themePresetId == 'custom_color';
    final Color paintColor = widget.appState.customThemeColor;
    final Color dynamicBtnText = paintColor.computeLuminance() > 0.6 ? Colors.black : Colors.white;

    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove, 
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeOutCubic)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 180, 
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: widget.cardColor,
            borderRadius: BorderRadius.circular(28), 
            border: Border.all(
              color: isCustomSelected ? widget.scheme.primary : Colors.transparent,
              width: 2,
            ),
            boxShadow: !widget.isDark && widget.isPremiumBlack && !isCustomSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                // THE FIX: Replaced the layout-breaking Spacer() with fixed, predictable sizing
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Custom Color', style: TextStyle(color: widget.textColor, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('"Define an exact hex theme."', style: TextStyle(color: widget.subTextColor, fontSize: 13, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 14), 
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: isCustomSelected ? paintColor : (widget.isDark ? Colors.white12 : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.palette, color: isCustomSelected ? dynamicBtnText : widget.textColor, size: 18),
                          const SizedBox(width: 8),
                          Text('Pick', style: TextStyle(color: isCustomSelected ? dynamicBtnText : widget.textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    _GPUAcceleratedSplat(animation: _splashController, color: paintColor, baseSize: 90),
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: paintColor,
                        border: Border.all(color: widget.dividerColor, width: 2),
                        boxShadow: [
                          BoxShadow(color: paintColor.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))
                        ],
                      ),
                      child: isCustomSelected ? Icon(Icons.check, color: dynamicBtnText, size: 38) : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CuratedPresetCard extends StatefulWidget {
  final AppThemePreset preset;
  final WorkoutState appState;
  final bool isDark;
  final bool isPremiumBlack;
  final ColorScheme scheme;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;

  const CuratedPresetCard({
    super.key, required this.preset, required this.appState, required this.isDark, 
    required this.isPremiumBlack, required this.scheme, required this.cardColor, 
    required this.textColor, required this.subTextColor
  });

  @override
  State<CuratedPresetCard> createState() => _CuratedPresetCardState();
}

class _CuratedPresetCardState extends State<CuratedPresetCard> with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _splashController;

  Offset _tapPosition = Offset.zero;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _splashController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _splashController.dispose();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    _tapPosition = event.position;
    _isScrolling = false;
    _bounceController.forward();
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_isScrolling && (event.position - _tapPosition).distance > 10) {
      _isScrolling = true;
      _bounceController.reverse();
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _isScrolling = false;
    _bounceController.reverse();
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (!_isScrolling) {
      HapticFeedback.selectionClick();
      _splashController.forward(from: 0.0);
      widget.appState.setThemePreset(widget.preset.id);
    }
    _isScrolling = false;
    _bounceController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSelected = widget.appState.themePresetId == widget.preset.id;
    final Color paintColor = (widget.preset.colors.first == Colors.black && widget.isDark) 
      ? Colors.grey.shade600 
      : widget.preset.colors.first;

    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove, 
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.92).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeOutCubic)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: widget.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? widget.scheme.primary : Colors.transparent,
              width: 2,
            ),
            boxShadow: !widget.isDark && widget.isPremiumBlack && !isSelected 
              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    _GPUAcceleratedSplat(animation: _splashController, color: paintColor, baseSize: 70),
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: widget.preset.colors.length == 1 
                          ? null 
                          : (widget.preset.colors.length == 2 
                              ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: widget.preset.colors)
                              : SweepGradient(colors: [...widget.preset.colors, widget.preset.colors.first])),
                        color: widget.preset.colors.length == 1 
                          ? (widget.preset.colors.first == Colors.black && widget.isDark ? Colors.grey.shade800 : widget.preset.colors.first)
                          : null,
                        boxShadow: [
                          BoxShadow(color: widget.preset.colors.first.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))
                        ],
                      ),
                      child: isSelected 
                        ? Icon(Icons.check, color: widget.preset.id == 'default_black' ? Colors.white : Colors.white.withOpacity(0.9), size: 32) 
                        : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.preset.name,
                style: TextStyle(
                  color: isSelected ? widget.textColor : widget.subTextColor,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecentColorCircle extends StatefulWidget {
  final Color historyColor;
  final WorkoutState appState;
  final Color textColor;
  final Color dividerColor;
  final bool isDark;

  const RecentColorCircle({
    super.key, required this.historyColor, required this.appState, 
    required this.textColor, required this.dividerColor, required this.isDark
  });

  @override
  State<RecentColorCircle> createState() => _RecentColorCircleState();
}

class _RecentColorCircleState extends State<RecentColorCircle> with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _splashController;

  Offset _tapPosition = Offset.zero;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _splashController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _splashController.dispose();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    _tapPosition = event.position;
    _isScrolling = false;
    _bounceController.forward();
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_isScrolling && (event.position - _tapPosition).distance > 10) {
      _isScrolling = true;
      _bounceController.reverse();
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _isScrolling = false;
    _bounceController.reverse();
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (!_isScrolling) {
      HapticFeedback.selectionClick();
      _splashController.forward(from: 0.0);
      widget.appState.setCustomThemeColor(widget.historyColor);
    }
    _isScrolling = false;
    _bounceController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    bool isSelected = widget.appState.themePresetId == 'custom_color' && widget.appState.customThemeColor == widget.historyColor;
    Color paintColor = (widget.historyColor == Colors.black && widget.isDark) ? Colors.grey.shade600 : widget.historyColor;

    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove, 
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.85).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeOutCubic)),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              _GPUAcceleratedSplat(animation: _splashController, color: paintColor, baseSize: 48),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 48,
                height: 48,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: widget.historyColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? widget.textColor : widget.dividerColor,
                    width: isSelected ? 2.5 : 1,
                  ),
                  boxShadow: isSelected ? [BoxShadow(color: widget.historyColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))] : [],
                ),
                child: isSelected ? Icon(Icons.check, color: widget.historyColor.computeLuminance() > 0.6 ? Colors.black : Colors.white, size: 20) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// MEMORY LEAK FIX: Dynamic Path Caching
// Uses a Map to permanently save the math for different shapes (e.g. Size 70 vs 90)
// This stops the cards from constantly overriding each other's paths and wasting CPU!
// -----------------------------------------------------------------------------
class _GPUAcceleratedSplat extends StatelessWidget {
  final Animation<double> animation;
  final Color color;
  final double baseSize;

  const _GPUAcceleratedSplat({required this.animation, required this.color, required this.baseSize});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.2, end: 1.8).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: SizedBox(
          width: baseSize * 1.5,
          height: baseSize * 1.5,
          child: CustomPaint(
            painter: _SplashPainter(color: color), 
          ),
        ),
      ),
    );
  }
}

class _SplashPainter extends CustomPainter {
  final Color color;
  
  // THE FIX: Converted the single static cache into a Map so different sized cards don't fight
  static final Map<Size, Path> _cachedFillPaths = {};
  static final Map<Size, Path> _cachedStrokePaths = {};

  _SplashPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (!_cachedFillPaths.containsKey(size) || !_cachedStrokePaths.containsKey(size)) {
      Path fillPath = Path();
      Path strokePath = Path();

      final center = Offset(size.width / 2, size.height / 2);
      final radius = size.width / 2;

      fillPath.addOval(Rect.fromCircle(center: center, radius: radius * 0.45));

      final math.Random rand = math.Random(123); 
      
      for (int i = 0; i < 7; i++) {
        double angle = (i * (math.pi * 2) / 7) + (rand.nextDouble() * 0.6 - 0.3);
        double length = radius * 0.5 + (rand.nextDouble() * radius * 0.45);
        
        Offset start = Offset(
          center.dx + (radius * 0.2) * math.cos(angle),
          center.dy + (radius * 0.2) * math.sin(angle)
        );
        Offset end = Offset(
          center.dx + length * math.cos(angle),
          center.dy + length * math.sin(angle)
        );

        double ctrlAngle = angle + 0.3;
        Offset ctrl = Offset(
          center.dx + (length * 0.6) * math.cos(ctrlAngle),
          center.dy + (length * 0.6) * math.sin(ctrlAngle)
        );

        strokePath.moveTo(start.dx, start.dy);
        strokePath.quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
      }
      
      for (int i = 0; i < 3; i++) {
         double angle = rand.nextDouble() * math.pi * 2;
         double dist = radius * 0.8 + rand.nextDouble() * radius * 0.2;
         Offset drop = Offset(
            center.dx + dist * math.cos(angle),
            center.dy + dist * math.sin(angle)
         );
         fillPath.addOval(Rect.fromCircle(center: drop, radius: radius * 0.12));
      }

      _cachedFillPaths[size] = fillPath;
      _cachedStrokePaths[size] = strokePath;
    }

    final fillPaint = Paint()..color = color..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (size.width / 2) * 0.35;

    canvas.drawPath(_cachedFillPaths[size]!, fillPaint);
    canvas.drawPath(_cachedStrokePaths[size]!, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _SplashPainter oldDelegate) => oldDelegate.color != color;
}
