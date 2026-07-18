import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/workout_models.dart';

class WorkoutState extends ChangeNotifier {
  List<WorkoutDay> days = [];
  bool isDarkMode = true; 
  bool isKg = false; 
  
  String userName = "My Name";
  String? profileImagePath;

  Map<String, List<WeightRecord>> exerciseProgress = {};

  WorkoutState() {
    loadData();
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

  void addWeightRecord(String exerciseName, double weight) {
    if (!exerciseProgress.containsKey(exerciseName)) {
      exerciseProgress[exerciseName] = [];
    }
    exerciseProgress[exerciseName]!.add(WeightRecord(date: DateTime.now(), weight: weight));
    _saveData();
  }

  Future<void> exportData() async {
    try {
      Map<String, dynamic> backup = {
        'userName': userName,
        'isDarkMode': isDarkMode,
        'isKg': isKg, 
        'exerciseProgress': exerciseProgress.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList())), 
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

  // THE FIX: Enables manual drag-and-drop sorting on the Home Screen!
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
    workout.name = newName;
    if (!workout.isDivider) workout.reps = newReps;
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
    
    await prefs.setBool('is_dark_mode', isDarkMode);
    await prefs.setBool('is_kg', isKg); 
    await prefs.setString('user_name', userName);
    
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
    
    isDarkMode = prefs.getBool('is_dark_mode') ?? true;
    isKg = prefs.getBool('is_kg') ?? false; 
    userName = prefs.getString('user_name') ?? "My Name";
    profileImagePath = prefs.getString('profile_image');
    
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
