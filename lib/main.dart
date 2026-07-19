import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'state/workout_state.dart';
import 'screens/home_page.dart';
import 'screens/welcome_page.dart';
import 'screens/splash_screen.dart'; 

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock the app to portrait mode for a consistent UI experience
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Make the top status bar transparent so your splash screen is seamless
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, 
      systemNavigationBarColor: Colors.black,
    ),
  );

  // --- GLOBAL CRASH SCREEN ---
  // Intercepts UI build errors and replaces the red screen of death with our custom UI
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.black,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 40),
                  SizedBox(width: 15),
                  Text(
                    'Crash Detected!',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              const Text('Error Message:', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(12)),
                width: double.infinity,
                child: Text(
                  details.exceptionAsString(),
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 25),
              const Text('Stack Trace:', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(12)),
                width: double.infinity,
                child: Text(
                  details.stack.toString(),
                  style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  };

  // Intercepts background async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Async Crash Caught: $error');
    return true;
  };

  runApp(const WorkoutApp());
}

class WorkoutApp extends StatefulWidget {
  const WorkoutApp({super.key});

  @override
  State<WorkoutApp> createState() => _WorkoutAppState();
}

class _WorkoutAppState extends State<WorkoutApp> {
  final WorkoutState appState = WorkoutState();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, child) {
        return MaterialApp(
          title: 'Workouts',
          debugShowCheckedModeBanner: false,
          themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: Colors.black,
            primaryColor: Colors.white,
            textSelectionTheme: const TextSelectionThemeData(
              cursorColor: Colors.white,
              selectionColor: Colors.white38,
              selectionHandleColor: Colors.white, 
            ),
          ),
          
          theme: ThemeData.light().copyWith(
            scaffoldBackgroundColor: const Color(0xFFF2F2F7),
            primaryColor: Colors.black,
            textSelectionTheme: const TextSelectionThemeData(
              cursorColor: Colors.black,
              selectionColor: Colors.black26,
              selectionHandleColor: Colors.black,
            ),
          ),
          
          // THE FIX: Replaced the routing logic with the SplashScreen
          home: SplashScreen(appState: appState),
        );
      },
    );
  }
}
