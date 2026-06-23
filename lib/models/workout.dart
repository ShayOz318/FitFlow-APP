import 'workout_exercise.dart';

class Workout {
  final String id;
  final String title;
  final List<WorkoutExercise> exercises;
  final String note;

  Workout({
    required this.id,
    required this.title,
    required this.exercises,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'exercises': exercises.map((exercise) => exercise.toMap()).toList(),
    };
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    final exercisesList = map['exercises'] as List<dynamic>? ?? [];

    return Workout(
      id: map['id'] as String,
      title: map['title'] as String,
      note: map['note'] as String? ?? '',
      exercises: exercisesList
          .map(
            (exercise) => WorkoutExercise.fromMap(
          Map<String, dynamic>.from(exercise),
        ),
      )
          .toList(),
    );
  }

  Workout copyWith({
    String? id,
    String? title,
    List<WorkoutExercise>? exercises,
    String? note,
  }) {
    return Workout(
      id: id ?? this.id,
      title: title ?? this.title,
      exercises: exercises ?? this.exercises,
      note: note ?? this.note,
    );
  }
}