import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'state/workout_state.dart';
import 'screens/home_page.dart';
import 'screens/welcome_page.dart';
import 'screens/splash_screen.dart';
import 'package:dynamic_color/dynamic_color.dart'; 

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
        
        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            
            final bool useMaterialYou = appState.useMaterialYou;
            final String customPresetId = appState.themePresetId;

            late ColorScheme lightScheme;
            late ColorScheme darkScheme;

            // 1. Generate the base colors based on the user's choice
            if (customPresetId == 'default_black') {
              lightScheme = const ColorScheme.light(primary: Colors.black, surface: Color(0xFFF2F2F7));
              darkScheme = const ColorScheme.dark(primary: Colors.white, surface: Colors.black);
            } else if (customPresetId == 'custom_color') {
              Color customColor = appState.customThemeColor;
              HSVColor hsv = HSVColor.fromColor(customColor);
              bool isGrayscale = hsv.saturation < 0.15;
              
              Color darkPrimary = hsv.value < 0.3 ? Colors.grey.shade400 : customColor;
              
              lightScheme = ColorScheme.fromSeed(seedColor: customColor, primary: customColor, brightness: Brightness.light);
              darkScheme = ColorScheme.fromSeed(seedColor: customColor, primary: darkPrimary, brightness: Brightness.dark);
            } else {
              final AppThemePreset preset = appThemePresets.firstWhere((p) => p.id == customPresetId, orElse: () => appThemePresets.first);
              Color primary = preset.colors[0];
              Color secondary = preset.colors.length > 1 ? preset.colors[1] : primary;
              Color tertiary = preset.colors.length > 2 ? preset.colors[2] : secondary;

              lightScheme = ColorScheme.fromSeed(seedColor: primary, primary: primary, secondary: secondary, tertiary: tertiary, brightness: Brightness.light);
              darkScheme = ColorScheme.fromSeed(seedColor: primary, primary: primary, secondary: secondary, tertiary: tertiary, brightness: Brightness.dark);
            }

            // ------------------------------------------------------------------
            // 2. THE VITAL FIX: STRIP OUT THE MUDDY M3 BACKGROUND TINTS!
            // This guarantees that all custom colors pop beautifully against 
            // a premium, pure black or clean white background across the app.
            // ------------------------------------------------------------------
            lightScheme = lightScheme.copyWith(
              surface: const Color(0xFFF2F2F7),
              surfaceContainerLow: Colors.white,
              surfaceContainer: Colors.white,
              surfaceContainerHigh: Colors.white,
              surfaceContainerHighest: Colors.grey.shade200,
            );



            // 3. Apply Material You ONLY if the user explicitly turned it on
            if (useMaterialYou && lightDynamic != null && darkDynamic != null) {
              lightScheme = lightDynamic.harmonized();
              darkScheme = darkDynamic.harmonized();
            }

            return MaterialApp(
              title: 'Workouts',
              debugShowCheckedModeBanner: false,
              themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
              
              darkTheme: ThemeData.dark().copyWith(
                useMaterial3: true,
                colorScheme: darkScheme,
                scaffoldBackgroundColor: useMaterialYou ? darkScheme.surface : (customPresetId == 'default_black' ? Colors.black : darkScheme.surface),
                primaryColor: useMaterialYou ? darkScheme.primary : (customPresetId == 'default_black' ? Colors.white : darkScheme.primary),
                textSelectionTheme: TextSelectionThemeData(
                  cursorColor: darkScheme.primary,
                  selectionColor: darkScheme.primary.withOpacity(0.3),
                  selectionHandleColor: darkScheme.primary, 
                ),
              ),
              
              theme: ThemeData.light().copyWith(
                useMaterial3: true,
                colorScheme: lightScheme,
                scaffoldBackgroundColor: useMaterialYou ? lightScheme.surface : (customPresetId == 'default_black' ? const Color(0xFFF2F2F7) : lightScheme.surface),
                primaryColor: useMaterialYou ? lightScheme.primary : (customPresetId == 'default_black' ? Colors.black : lightScheme.primary),
                textSelectionTheme: TextSelectionThemeData(
                  cursorColor: lightScheme.primary,
                  selectionColor: lightScheme.primary.withOpacity(0.3),
                  selectionHandleColor: lightScheme.primary,
                ),
              ),
              
              home: SplashScreen(appState: appState),
            );
          },
        );

      },
    );
  }
}
