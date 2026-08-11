import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; 
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/workout_models.dart';

class AppThemePreset {
  final String id;
  final String name;
  final List<Color> colors; 

  const AppThemePreset({required this.id, required this.name, required this.colors});
}

const List<AppThemePreset> appThemePresets = [
  AppThemePreset(id: 'default_black', name: 'Premium Midnight', colors: [Colors.black, Colors.grey]),
  AppThemePreset(id: 'blue_ocean', name: 'Deep Ocean', colors: [Color(0xFF007AFF), Color(0xFF00C6FF)]),
  AppThemePreset(id: 'sunset', name: 'Sunset Glow', colors: [Color(0xFFFF512F), Color(0xFFDD2476)]),
  AppThemePreset(id: 'cyberpunk', name: 'Cyberpunk Edge', colors: [Color(0xFF00F2FE), Color(0xFF4FACFE), Color(0xFFF093FB)]),
  AppThemePreset(id: 'forest', name: 'Lush Forest', colors: [Color(0xFF11998E), Color(0xFF38EF7D)]),
  AppThemePreset(id: 'lavender', name: 'Lavender Dream', colors: [Color(0xFFB224EF), Color(0xFF7579FF)]),
  AppThemePreset(id: 'ember', name: 'Ember Flame', colors: [Color(0xFFFF416C), Color(0xFFFF4B2B), Color(0xFFFF9068)]),
  AppThemePreset(id: 'neon_lime', name: 'Neon Lime', colors: [Color(0xFF00FF87), Color(0xFF60EFFF)]),
  AppThemePreset(id: 'custom_color', name: 'Custom Theme', colors: [Colors.transparent]), 
];

class WorkoutState extends ChangeNotifier {
  List<WorkoutDay> days = [];
  bool isDarkMode = true; 
  bool isKg = false; 
  bool isFirstLaunch = true; 
  
  String userName = "My Name";
  String? profileImagePath;

  bool _useMaterialYou = false; 
  bool get useMaterialYou => _useMaterialYou;

  String _themePresetId = 'default_black'; 
  String get themePresetId => _themePresetId;

  Color _customThemeColor = const Color(0xFF6200EE); 
  Color get customThemeColor => _customThemeColor;

  List<int> _customColorHistory = [];
  List<Color> get customColorHistory => _customColorHistory.map((v) => Color(v)).toList();

  Map<String, List<WeightRecord>> exerciseProgress = {};

  // THE FIX: Changed default toggles and widget order
  bool showCalendar = true;
  bool showTimer = true;
  bool showQuote = false; // Now turned off by default
  String customQuote = "Push harder than yesterday.";
  List<String> homeWidgetOrder = ['calendar', 'timer', 'quote']; // Quote is now at the bottom

  WorkoutState() {
    loadData();
  }

  void completeFirstLaunch() {
    isFirstLaunch = false;
    _saveData();
  }

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    _saveData();
  }

  void setDarkMode(bool value) {
    isDarkMode = value;
    _saveData();
  }

  void toggleWeightUnit() {
    isKg = !isKg;
    _saveData();
  }

  void updateUserName(String name) {
    userName = name;
    _saveData();
  }

  void updateProfileImage(String? path) {
    profileImagePath = path;
    _saveData();
  }

  void toggleMaterialYou() {
    _useMaterialYou = !_useMaterialYou;
    _saveData();
  }

  void setThemePreset(String id) {
    _themePresetId = id;
    if (_useMaterialYou) {
      _useMaterialYou = false; 
    }
    _saveData();
  }

  void setCustomThemeColor(Color color) {
    _customThemeColor = color;
    _themePresetId = 'custom_color';
    if (_useMaterialYou) _useMaterialYou = false;

    _customColorHistory.remove(color.value);
    _customColorHistory.insert(0, color.value);
    if (_customColorHistory.length > 8) {
      _customColorHistory.removeLast();
    }

    _saveData();
  }

  void toggleCalendar() {
    showCalendar = !showCalendar;
    _saveData();
  }

  void toggleTimer() {
    showTimer = !showTimer;
    _saveData();
  }

  void toggleQuote() {
    showQuote = !showQuote;
    _saveData();
  }

  void updateCustomQuote(String quote) {
    customQuote = quote;
    _saveData();
  }

  void reorderHomeWidgets(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final item = homeWidgetOrder.removeAt(oldIndex);
    homeWidgetOrder.insert(newIndex, item);
    _saveData();
  }

  List<String> getUniqueExercises({String? dayId}) {
    Set<String> uniqueNames = {};
    var daysToScan = dayId == null ? days : days.where((d) => d.id == dayId);
    
    for (var day in daysToScan) {
      for (var workout in day.workouts) {
        if (!workout.isDivider && workout.name.trim().isNotEmpty) {
          String cleanName = workout.name.trim();
          cleanName = cleanName[0].toUpperCase() + cleanName.substring(1).toLowerCase();
          uniqueNames.add(cleanName);
        }
      }
    }
    List<String> sortedList = uniqueNames.toList();
    sortedList.sort();
    return sortedList;
  }

  double _calculateUniversal1RM(double weight, String unit, int reps) {
    double normKg = unit == 'lbs' ? weight / 2.20462 : weight;
    if (reps <= 1) return normKg;
    return normKg * (1 + (reps / 30.0)); 
  }

  bool addWeightRecord(String exerciseName, double weight, String unit, int reps) {
    bool isNewPR = false;
    double new1RM = _calculateUniversal1RM(weight, unit, reps);

    if (!exerciseProgress.containsKey(exerciseName) || exerciseProgress[exerciseName]!.isEmpty) {
      isNewPR = true;
      exerciseProgress[exerciseName] = [];
    } else {
      double currentMax1RM = exerciseProgress[exerciseName]!.map((r) => _calculateUniversal1RM(r.weight, r.unit, r.reps)).reduce(math.max);
      if (new1RM > currentMax1RM) isNewPR = true;
    }

    exerciseProgress[exerciseName]!.add(WeightRecord(date: DateTime.now(), weight: weight, unit: unit, reps: reps));
    _saveData();
    return isNewPR;
  }

  void deleteWeightRecord(String exerciseName, WeightRecord record) {
    if (exerciseProgress.containsKey(exerciseName)) {
      exerciseProgress[exerciseName]!.remove(record);
      if (exerciseProgress[exerciseName]!.isEmpty) {
        exerciseProgress.remove(exerciseName); 
      }
      _saveData();
    }
  }

  Future<void> exportData() async {
    try {
      Map<String, dynamic> backup = {
        'userName': userName,
        'isDarkMode': isDarkMode,
        'isKg': isKg, 
        'isFirstLaunch': isFirstLaunch,
        'useMaterialYou': _useMaterialYou,
        'themePresetId': _themePresetId, 
        'customThemeColor': _customThemeColor.value,
        'customColorHistory': _customColorHistory,
        'exerciseProgress': exerciseProgress.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList())), 
        'showCalendar': showCalendar,
        'showTimer': showTimer,
        'showQuote': showQuote,
        'customQuote': customQuote,
        'homeWidgetOrder': homeWidgetOrder,
      };

      if (profileImagePath != null && File(profileImagePath!).existsSync()) {
        backup['profileImageBase64'] = base64Encode(File(profileImagePath!).readAsBytesSync());
      }

      List<Map<String, dynamic>> daysBackup = [];
      for (var day in days) {
        var dayJson = day.toJson();
        if (day.imagePath != null && File(day.imagePath!).existsSync()) {
          dayJson['imageBase64'] = base64Encode(File(day.imagePath!).readAsBytesSync());
        }
        daysBackup.add(dayJson);
      }
      backup['days'] = daysBackup;

      String backupData = jsonEncode(backup);

      try {
        Uint8List fileBytes = Uint8List.fromList(utf8.encode(backupData));
        String? outputFile = await FilePicker.saveFile(
          dialogTitle: 'Save Workout Backup',
          fileName: 'WorkoutBackup.json',
          bytes: fileBytes, 
        );

        if (outputFile != null) {
          try {
            File file = File(outputFile);
            if (!file.existsSync() || file.lengthSync() == 0) {
              await file.writeAsString(backupData);
            }
          } catch (_) {}
        }
      } catch (e) {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/WorkoutBackup.json');
        await file.writeAsString(backupData);
        await Share.shareXFiles([XFile(file.path)], subject: 'My Workout Backup');
      }
    } catch (e) {
      debugPrint("Error exporting data: $e");
    }
  }

  Future<void> importData() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(type: FileType.any);
      
      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        Map<String, dynamic> backup = jsonDecode(content);

        final dir = await getApplicationDocumentsDirectory();

        userName = backup['userName'] ?? "My Name";
        isDarkMode = backup['isDarkMode'] ?? true;
        isKg = backup['isKg'] ?? false; 
        isFirstLaunch = backup['isFirstLaunch'] ?? false;
        _useMaterialYou = backup['useMaterialYou'] ?? false;
        
        // THE FIX: Set fallback settings identically
        showCalendar = backup['showCalendar'] ?? true;
        showTimer = backup['showTimer'] ?? true;
        showQuote = backup['showQuote'] ?? false;
        customQuote = backup['customQuote'] ?? "Push harder than yesterday.";
        homeWidgetOrder = backup['homeWidgetOrder'] != null ? List<String>.from(backup['homeWidgetOrder']) : ['calendar', 'timer', 'quote'];

        if (backup['themePresetId'] != null && backup['themePresetId'] is String) {
          _themePresetId = backup['themePresetId'];
        } else {
          _themePresetId = 'default_black';
        }

        if (backup['customThemeColor'] != null) {
          _customThemeColor = Color(backup['customThemeColor']);
        }

        if (backup['customColorHistory'] != null) {
          _customColorHistory = List<int>.from(backup['customColorHistory']);
        }

        if (backup['exerciseProgress'] != null) {
          Map<String, dynamic> epMap = backup['exerciseProgress'];
          exerciseProgress = epMap.map((k, v) => MapEntry(k, (v as List).map((e) => WeightRecord.fromJson(e)).toList()));
        }

        if (backup['profileImageBase64'] != null) {
          File imgFile = File('${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg');
          await imgFile.writeAsBytes(base64Decode(backup['profileImageBase64']));
          profileImagePath = imgFile.path;
        }

        if (backup['days'] != null) {
          List<WorkoutDay> importedDays = [];
          for (var d in backup['days']) {
            if (d['imageBase64'] != null) {
              File imgFile = File('${dir.path}/day_${d['id']}_${DateTime.now().millisecondsSinceEpoch}.jpg');
              await imgFile.writeAsBytes(base64Decode(d['imageBase64']));
              d['imagePath'] = imgFile.path;
            }
            importedDays.add(WorkoutDay.fromJson(d));
          }
          days = importedDays;
        }

        _sortDays();
        await _saveData();
      }
    } catch (e) {
      debugPrint("Error importing data: $e");
    }
  }

  void addDay(String name) {
    days.add(WorkoutDay(id: DateTime.now().toString(), name: name, workouts: []));
    _sortDays();
    _saveData();
  }

  void renameDay(String dayId, String newName) {
    var day = days.firstWhere((d) => d.id == dayId);
    day.name = newName;
    _saveData();
  }

  void updateDayImage(String dayId, String? imagePath) {
    var day = days.firstWhere((d) => d.id == dayId);
    day.imagePath = imagePath;
    _saveData();
  }

  void togglePinDay(String dayId) {
    var day = days.firstWhere((d) => d.id == dayId);
    day.isPinned = !day.isPinned;
    _sortDays();
    _saveData();
  }

  void deleteDay(String dayId) {
    days.removeWhere((d) => d.id == dayId);
    _saveData();
  }

  void _sortDays() {
    List<WorkoutDay> pinned = days.where((d) => d.isPinned).toList();
    List<WorkoutDay> unpinned = days.where((d) => !d.isPinned).toList();
    days = [...pinned, ...unpinned];
  }

  void reorderDays(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final item = days.removeAt(oldIndex);
    days.insert(newIndex, item);
    _saveData();
  }

  void addWorkout(String dayId, String name, String reps) {
    var day = days.firstWhere((d) => d.id == dayId);
    day.workouts.add(WorkoutItem(id: DateTime.now().toString(), name: name, reps: reps));
    _saveData();
  }

  void addDivider(String dayId) {
    var day = days.firstWhere((d) => d.id == dayId);
    day.workouts.add(WorkoutItem(id: DateTime.now().toString(), name: '', reps: '', isDivider: true));
    _saveData();
  }

  void renameWorkout(String dayId, String workoutId, String newName, String newReps) {
    var day = days.firstWhere((d) => d.id == dayId);
    var workout = day.workouts.firstWhere((w) => w.id == workoutId);

    String oldNameClean = workout.name.trim();
    if (oldNameClean.isNotEmpty) {
      oldNameClean = oldNameClean[0].toUpperCase() + oldNameClean.substring(1).toLowerCase();
    }

    workout.name = newName;
    if (!workout.isDivider) workout.reps = newReps;

    String newNameClean = newName.trim();
    if (newNameClean.isNotEmpty) {
      newNameClean = newNameClean[0].toUpperCase() + newNameClean.substring(1).toLowerCase();
    }

    if (!workout.isDivider && oldNameClean != newNameClean && oldNameClean.isNotEmpty) {
      if (exerciseProgress.containsKey(oldNameClean)) {
        bool isStillUsed = false;
        for (var d in days) {
          for (var w in d.workouts) {
            if (!w.isDivider && w.id != workoutId) {
              String wName = w.name.trim();
              if (wName.isNotEmpty) {
                wName = wName[0].toUpperCase() + wName.substring(1).toLowerCase();
                if (wName == oldNameClean) {
                  isStillUsed = true;
                  break;
                }
              }
            }
          }
          if (isStillUsed) break;
        }

        if (!isStillUsed) {
          if (!exerciseProgress.containsKey(newNameClean)) {
            exerciseProgress[newNameClean] = [];
          }
          exerciseProgress[newNameClean]!.addAll(exerciseProgress[oldNameClean]!);
          exerciseProgress[newNameClean]!.sort((a, b) => a.date.compareTo(b.date));
          exerciseProgress.remove(oldNameClean);
        }
      }
    }
    _saveData();
  }

  void deleteWorkout(String dayId, String workoutId) {
    var day = days.firstWhere((d) => d.id == dayId);
    day.workouts.removeWhere((w) => w.id == workoutId);
    _saveData();
  }

  void toggleWorkoutCompletion(String dayId, String workoutId) {
    var day = days.firstWhere((d) => d.id == dayId);
    var workout = day.workouts.firstWhere((w) => w.id == workoutId);
    workout.isCompleted = !workout.isCompleted;
    _saveData();
  }

  void resetCompletedWorkouts(String dayId) {
    var day = days.firstWhere((d) => d.id == dayId);
    for (var w in day.workouts) {
      w.isCompleted = false;
    }
    _saveData();
  }

  bool hasCompletedWorkouts(String dayId) {
    var day = days.firstWhere((d) => d.id == dayId, orElse: () => WorkoutDay(id: '', name: '', workouts: []));
    return day.workouts.any((w) => w.isCompleted && !w.isDivider);
  }

  void reorderWorkouts(String dayId, int oldIndex, int newIndex) {
    var day = days.firstWhere((d) => d.id == dayId);
    if (oldIndex < newIndex) newIndex -= 1;
    final item = day.workouts.removeAt(oldIndex);
    day.workouts.insert(newIndex, item);
    _saveData();
  }

  Future<void> _saveData() async {
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool('is_first_launch', isFirstLaunch);
    await prefs.setBool('is_dark_mode', isDarkMode);
    await prefs.setBool('is_kg', isKg); 
    await prefs.setString('user_name', userName);
    await prefs.setBool('use_material_you', _useMaterialYou);
    await prefs.setString('theme_preset', _themePresetId);
    await prefs.setInt('custom_theme_color', _customThemeColor.value);
    await prefs.setString('custom_color_history', jsonEncode(_customColorHistory)); 
    
    await prefs.setBool('show_calendar', showCalendar);
    await prefs.setBool('show_timer', showTimer);
    await prefs.setBool('show_quote', showQuote);
    await prefs.setString('custom_quote', customQuote);
    await prefs.setStringList('home_widget_order', homeWidgetOrder);

    if (profileImagePath != null) {
      await prefs.setString('profile_image', profileImagePath!);
    } else {
      await prefs.remove('profile_image');
    }
    
    List<String> jsonList = days.map((d) => jsonEncode(d.toJson())).toList();
    await prefs.setStringList('workout_days', jsonList);

    await prefs.setString('exercise_progress', jsonEncode(exerciseProgress.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()))));
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    isFirstLaunch = prefs.getBool('is_first_launch') ?? true; 
    isDarkMode = prefs.getBool('is_dark_mode') ?? true;
    isKg = prefs.getBool('is_kg') ?? false; 
    userName = prefs.getString('user_name') ?? "My Name";
    profileImagePath = prefs.getString('profile_image');
    
    _useMaterialYou = prefs.getBool('use_material_you') ?? false;
    _themePresetId = prefs.getString('theme_preset') ?? 'default_black';
    
    showCalendar = prefs.getBool('show_calendar') ?? true;
    showTimer = prefs.getBool('show_timer') ?? true;
    showQuote = prefs.getBool('show_quote') ?? false; // THE FIX: Default Off
    customQuote = prefs.getString('custom_quote') ?? "Push harder than yesterday.";
    homeWidgetOrder = prefs.getStringList('home_widget_order') ?? ['calendar', 'timer', 'quote']; // THE FIX: Order

    int? customColorVal = prefs.getInt('custom_theme_color');
    _customThemeColor = customColorVal != null ? Color(customColorVal) : const Color(0xFF6200EE);

    String? historyJson = prefs.getString('custom_color_history');
    if (historyJson != null) {
      _customColorHistory = List<int>.from(jsonDecode(historyJson));
    }

    List<String>? jsonList = prefs.getStringList('workout_days');
    if (jsonList != null && jsonList.isNotEmpty) {
      days = jsonList.map((j) => WorkoutDay.fromJson(jsonDecode(j))).toList();
      _sortDays(); 
    } else {
      days = []; 
    }

    String? progressJson = prefs.getString('exercise_progress');
    if (progressJson != null) {
      Map<String, dynamic> decoded = jsonDecode(progressJson);
      exerciseProgress = decoded.map((k, v) => MapEntry(k, (v as List).map((e) => WeightRecord.fromJson(e)).toList()));
    }

    notifyListeners();
  }
}
