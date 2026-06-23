import 'weight_entry.dart';

class TraineeProfileData {
  final String name;
  final int? age;
  final double? height;
  final String goal;
  final double? currentWeight;
  final double? targetWeight;
  final double? startingWeight;
  final List<WeightEntry> weightHistory;

  const TraineeProfileData({
    this.name = '',
    this.age,
    this.height,
    this.goal = '',
    this.currentWeight,
    this.targetWeight,
    this.startingWeight,
    this.weightHistory = const [],
  });

  TraineeProfileData copyWith({
    String? name,
    int? age,
    double? height,
    String? goal,
    double? currentWeight,
    double? targetWeight,
    double? startingWeight,
    List<WeightEntry>? weightHistory,
  }) {
    return TraineeProfileData(
      name: name ?? this.name,
      age: age ?? this.age,
      height: height ?? this.height,
      goal: goal ?? this.goal,
      currentWeight: currentWeight ?? this.currentWeight,
      targetWeight: targetWeight ?? this.targetWeight,
      startingWeight: startingWeight ?? this.startingWeight,
      weightHistory: weightHistory ?? this.weightHistory,
    );
  }

  Map<String, dynamic> toFirestoreFields() {
    return {
      'name': name,
      if (age != null) 'age': age,
      if (height != null) 'height': height,
      'goal': goal,
      if (currentWeight != null) 'currentWeight': currentWeight,
      if (targetWeight != null) 'targetWeight': targetWeight,
      if (startingWeight != null) 'startingWeight': startingWeight,
      'weightHistory': weightHistory.map((entry) => entry.toMap()).toList(),
    };
  }

  factory TraineeProfileData.fromFirestore(Map<String, dynamic> data) {
    final historyRaw = data['weightHistory'] as List<dynamic>? ?? [];

    return TraineeProfileData(
      name: data['name'] as String? ?? '',
      age: data['age'] as int?,
      height: (data['height'] as num?)?.toDouble(),
      goal: data['goal'] as String? ?? '',
      currentWeight: (data['currentWeight'] as num?)?.toDouble(),
      targetWeight: (data['targetWeight'] as num?)?.toDouble(),
      startingWeight: (data['startingWeight'] as num?)?.toDouble(),
      weightHistory: historyRaw
          .map((item) => WeightEntry.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}
