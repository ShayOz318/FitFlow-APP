import 'package:flutter/material.dart';

import '../../../data/coach_data_repository.dart';
import '../../../models/workout.dart';
import '../../../models/workout_exercise.dart';

class TraineeWorkoutScreen extends StatefulWidget {
  final String traineeId;

  const TraineeWorkoutScreen({
    super.key,
    required this.traineeId,
  });

  @override
  State<TraineeWorkoutScreen> createState() => _TraineeWorkoutScreenState();
}

class _TraineeWorkoutScreenState extends State<TraineeWorkoutScreen> {
  final CoachDataRepository _dataRepository = CoachDataRepository.instance;

  List<Workout> workouts = [];
  Workout? selectedWorkout;
  bool isLoading = true;

  Map<String, String> traineeNotes = {};

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  String _exerciseNoteKey(String workoutId, int exerciseId) {
    return '${workoutId}_$exerciseId';
  }

  Future<void> _loadWorkouts() async {
    final loadedWorkouts = await _dataRepository.getWorkouts(widget.traineeId);
    final loadedNotes =
        await _dataRepository.getExerciseNotes(widget.traineeId);

    setState(() {
      workouts = loadedWorkouts;
      selectedWorkout = workouts.isNotEmpty ? workouts.first : null;
      traineeNotes = loadedNotes;
      isLoading = false;
    });
  }

  Future<void> _saveNotes() async {
    await _dataRepository.saveExerciseNotes(widget.traineeId, traineeNotes);
  }

  Future<void> _editExerciseNote(Workout workout, WorkoutExercise workoutExercise) async {
    final key = _exerciseNoteKey(workout.id, workoutExercise.exercise.id);
    final controller = TextEditingController(text: traineeNotes[key] ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('הערה לתרגיל ${workoutExercise.exercise.name}'),
            content: TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'כתבי איך היה לך, מה הרגשת, אם היה קשה או קל...',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ביטול'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('שמור'),
              ),
            ],
          ),
        );
      },
    );

    if (result == null) {
      return;
    }

    setState(() {
      if (result.isEmpty) {
        traineeNotes.remove(key);
      } else {
        traineeNotes[key] = result;
      }
    });

    await _saveNotes();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ההערה נשמרה'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workout = selectedWorkout;
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('האימונים שלי'),
        ),
        body: isLoading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : workouts.isEmpty
            ? const Center(
          child: Text(
            'עדיין לא נבנו אימונים',
            style: TextStyle(fontSize: 18),
          ),
        )
            : Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              DropdownButtonFormField<Workout>(
                value: workout,
                items: workouts.map((item) {
                  return DropdownMenuItem<Workout>(
                    value: item,
                    child: Text(item.title),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedWorkout = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'בחרי אימון',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: workout == null
                    ? const Center(
                  child: Text('לא נבחר אימון'),
                )
                    : ListView(
                  children: [
                    Text(
                      workout.title.trim().isEmpty
                          ? 'אימון ללא שם'
                          : workout.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    if (workout.note.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1EC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('הערת מאמן: ${workout.note}'),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ...workout.exercises.map(
                          (exercise) => _buildExerciseCard(
                        context,
                        workout,
                        exercise,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard(
      BuildContext context,
      Workout workout,
      WorkoutExercise workoutExercise,
      ) {
    final theme = Theme.of(context);
    final noteKey = _exerciseNoteKey(workout.id, workoutExercise.exercise.id);
    final traineeNote = traineeNotes[noteKey];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            workoutExercise.exercise.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${workoutExercise.sets} סטים | '
                '${workoutExercise.reps} חזרות | '
                'משקל: ${workoutExercise.weight}',
          ),
          const SizedBox(height: 4),
          Text('מנוחה: ${workoutExercise.restSeconds} שניות'),
          if (workoutExercise.tempo.trim().isNotEmpty)
            Text('קצב עבודה: ${workoutExercise.tempo}'),
          const SizedBox(height: 8),
          Text(workoutExercise.exercise.instructions),
          if (workoutExercise.note.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('הערת מאמן: ${workoutExercise.note}'),
          ],
          const SizedBox(height: 12),
          if (traineeNote != null && traineeNote.trim().isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6F3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'הערה שלי: $traineeNote',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _editExerciseNote(workout, workoutExercise),
              child: Text(
                traineeNote == null || traineeNote.trim().isEmpty
                    ? 'הוספת הערה לתרגיל'
                    : 'עריכת ההערה שלי',
              ),
            ),
          ),
        ],
      ),
    );
  }
}