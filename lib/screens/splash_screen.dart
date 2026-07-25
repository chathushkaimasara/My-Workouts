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
  
  // THE FIX: Safety flag to prevent navigating twice if tapped at the very end
  bool _isNavigating = false; 

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
    ));

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _scaleAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack)), weight: 40),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInBack)), weight: 40),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
    ]).animate(_controller);

    _controller.forward().then((_) {
      _navigateToNextScreen();
    });
  }

  void _navigateToNextScreen() {
    // Check flag to prevent double-pushing the route
    if (_isNavigating) return; 
    _isNavigating = true;

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

  // THE FIX: Stop the animation instantly and trigger the navigation
  void _skipAnimation() {
    if (!_isNavigating) {
      HapticFeedback.selectionClick(); 
      _controller.stop(); 
      _navigateToNextScreen();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildCustomDumbbell(Color color) {
    return Transform.rotate(
      angle: -0.65, 
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(width: 18, height: 55, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10))),
          Container(width: 6, height: 22, color: color),
          Container(width: 28, height: 95, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12))),
          Container(width: 65, height: 26, color: color),
          Container(width: 28, height: 95, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12))),
          Container(width: 6, height: 22, color: color),
          Container(width: 18, height: 55, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color dumbbellColor = widget.appState.isFirstLaunch 
        ? const Color(0xFFE8F54F) 
        : Colors.white;

    return Scaffold(
      backgroundColor: Colors.black, 
      // THE FIX: Wrap the body in a GestureDetector covering the entire screen
      body: GestureDetector(
        onTap: _skipAnimation, 
        behavior: HitTestBehavior.opaque, // Ensures taps register on the empty black space
        child: Center(
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
            child: _buildCustomDumbbell(dumbbellColor),
          ),
        ),
      ),
    );
  }
}
