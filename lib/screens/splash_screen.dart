import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/workout_state.dart';
import 'welcome_page.dart';
import 'home_page.dart';

class SplashScreen extends StatefulWidget {
  final WorkoutState appState;

  const SplashScreen({super.key, required this.appState});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // Forces the status bar to be transparent so the splash screen is truly full-screen
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
    ));

    // The total duration of the splash sequence
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // Sequence: Pop in (bounce) -> Hold -> Shrink away
    _scaleAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack)), weight: 40),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInBack)), weight: 40),
    ]).animate(_controller);

    // Sequence: Fade in -> Hold -> Fade out
    _opacityAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
    ]).animate(_controller);

    // Start the animation, then navigate when it's done
    _controller.forward().then((_) {
      _navigateToNextScreen();
    });
  }

  void _navigateToNextScreen() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) => 
            widget.appState.isFirstLaunch 
                ? WelcomePage(appState: widget.appState) 
                : HomePage(appState: widget.appState),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- CUSTOM VECTOR DUMBBELL ---
  // A pixel-perfect replica of the silhouette from your 3D logo
  Widget _buildCustomDumbbell(Color color) {
    return Transform.rotate(
      angle: -0.65, // Matches the diagonal tilt of your logo
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Outer Plate
          Container(width: 18, height: 55, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10))),
          // Left Connector
          Container(width: 6, height: 22, color: color),
          // Left Inner Plate
          Container(width: 28, height: 95, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12))),
          // Main Handle
          Container(width: 65, height: 26, color: color),
          // Right Inner Plate
          Container(width: 28, height: 95, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12))),
          // Right Connector
          Container(width: 6, height: 22, color: color),
          // Right Outer Plate
          Container(width: 18, height: 55, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    
    // Dynamic color logic: Yellow for first launch, White for returning users
    final Color dumbbellColor = widget.appState.isFirstLaunch 
        ? const Color(0xFFE8F54F) 
        : Colors.white;

    return Scaffold(
      backgroundColor: Colors.black, 
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          // Uses our newly drawn vector dumbbell instead of the default Material Icon
          child: _buildCustomDumbbell(dumbbellColor),
        ),
      ),
    );
  }
}
