class WorkoutItem {
  String id;
  String name;
  String reps;
  bool isCompleted;
  bool isDivider;

  WorkoutItem({
    required this.id, 
    required this.name, 
    required this.reps,
    this.isCompleted = false,
    this.isDivider = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 
    'name': name, 
    'reps': reps,
    'isCompleted': isCompleted,
    'isDivider': isDivider,
  };

  factory WorkoutItem.fromJson(Map<String, dynamic> json) {
    return WorkoutItem(
      id: json['id'], 
      name: json['name'], 
      reps: json['reps'] ?? '3',
      isCompleted: json['isCompleted'] ?? false,
      isDivider: json['isDivider'] ?? false,
    );
  }
}

class WorkoutDay {
  String id;
  String name;
  String? imagePath;
  bool isPinned; 
  List<WorkoutItem> workouts;

  WorkoutDay({
    required this.id, 
    required this.name, 
    this.imagePath,
    this.isPinned = false,
    required this.workouts,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imagePath': imagePath,
    'isPinned': isPinned,
    'workouts': workouts.map((w) => w.toJson()).toList(),
  };

  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    var list = json['workouts'] as List? ?? [];
    List<WorkoutItem> workoutList = list.map((i) => WorkoutItem.fromJson(i)).toList();
    return WorkoutDay(
      id: json['id'], 
      name: json['name'], 
      imagePath: json['imagePath'], 
      isPinned: json['isPinned'] ?? false,
      workouts: workoutList,
    );
  }
}

// --- NEW: WEIGHT RECORD MODEL ---
class WeightRecord {
  final DateTime date;
  final double weight;

  WeightRecord({required this.date, required this.weight});

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'weight': weight,
  };

  factory WeightRecord.fromJson(Map<String, dynamic> json) {
    return WeightRecord(
      date: DateTime.parse(json['date']),
      weight: json['weight'],
    );
  }
}
