import '../data/exercise_repository.dart';
import 'exercise.dart';

class WorkoutExercise {
  final Exercise exercise;
  final int sets;
  final int reps;
  final double weight;
  final int restSeconds;
  final String tempo;
  final String note;

  const WorkoutExercise({
    required this.exercise,
    required this.sets,
    required this.reps,
    required this.weight,
    this.restSeconds = 60,
    this.tempo = '',
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exercise.id,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'restSeconds': restSeconds,
      'tempo': tempo,
      'note': note,
    };
  }

  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    final exerciseId = map['exerciseId'] as int;
    final exercise = ExerciseRepository.getById(exerciseId);

    if (exercise == null) {
      throw Exception('לא נמצא תרגיל עם מזהה $exerciseId');
    }

    return WorkoutExercise(
      exercise: exercise,
      sets: map['sets'] as int,
      reps: map['reps'] as int,
      weight: (map['weight'] as num).toDouble(),
      restSeconds: map['restSeconds'] as int? ?? 60,
      tempo: map['tempo'] as String? ?? '',
      note: map['note'] as String? ?? '',
    );
  }

  WorkoutExercise copyWith({
    Exercise? exercise,
    int? sets,
    int? reps,
    double? weight,
    int? restSeconds,
    String? tempo,
    String? note,
  }) {
    return WorkoutExercise(
      exercise: exercise ?? this.exercise,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      restSeconds: restSeconds ?? this.restSeconds,
      tempo: tempo ?? this.tempo,
      note: note ?? this.note,
    );
  }
}