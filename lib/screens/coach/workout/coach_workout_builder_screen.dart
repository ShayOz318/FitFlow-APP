import 'package:flutter/material.dart';

import '../../../data/coach_data_repository.dart';
import '../../../models/exercise.dart';
import '../../../models/workout.dart';
import '../../../models/workout_exercise.dart';
import 'exercise_details_screen.dart';
import 'exercise_selection_screen.dart';

class CoachWorkoutBuilderScreen extends StatefulWidget {
  final String traineeId;

  const CoachWorkoutBuilderScreen({
    super.key,
    required this.traineeId,
  });

  @override
  State<CoachWorkoutBuilderScreen> createState() =>
      _CoachWorkoutBuilderScreenState();
}

class _CoachWorkoutBuilderScreenState extends State<CoachWorkoutBuilderScreen> {
  final CoachDataRepository _dataRepository = CoachDataRepository.instance;

  final TextEditingController workoutNameController = TextEditingController();
  final TextEditingController workoutNoteController = TextEditingController();

  List<Workout> workouts = [];
  Workout? selectedWorkout;
  bool isLoading = true;

  Map<String, String> traineeNotes = {};

  List<WorkoutExercise> get currentExercises {
    return selectedWorkout?.exercises ?? [];
  }

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  @override
  void dispose() {
    workoutNameController.dispose();
    workoutNoteController.dispose();
    super.dispose();
  }

  String _exerciseNoteKey(String workoutId, int exerciseId) {
    return '${workoutId}_$exerciseId';
  }

  Future<void> _saveWorkouts() async {
    await _dataRepository.saveWorkouts(widget.traineeId, workouts);
  }

  Future<void> _loadWorkouts() async {
    final loadedWorkouts = await _dataRepository.getWorkouts(widget.traineeId);
    final loadedNotes =
        await _dataRepository.getExerciseNotes(widget.traineeId);

    setState(() {
      workouts = loadedWorkouts;
      traineeNotes = loadedNotes;
      if (workouts.isNotEmpty) {
        selectedWorkout = workouts.first;
        workoutNameController.text = selectedWorkout!.title;
        workoutNoteController.text = selectedWorkout!.note;
      } else {
        selectedWorkout = null;
      }
      isLoading = false;
    });
  }

  Future<void> _saveTraineeNotes() async {
    await _dataRepository.saveExerciseNotes(widget.traineeId, traineeNotes);
  }

  Future<void> _deleteTraineeNote(Workout workout, WorkoutExercise exercise) async {
    final noteKey = _exerciseNoteKey(workout.id, exercise.exercise.id);

    if (!traineeNotes.containsKey(noteKey)) {
      return;
    }

    setState(() {
      traineeNotes.remove(noteKey);
    });

    await _saveTraineeNotes();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('הערת המתאמן נמחקה'),
      ),
    );
  }

  String _createWorkoutId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<void> _addWorkout() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('אימון חדש'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'שם האימון',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('הוסף'),
            ),
          ],
        );
      },
    ) ??
        '';

    if (result.isEmpty) {
      return;
    }

    final alreadyExists = workouts.any(
          (workout) => workout.title.trim().toLowerCase() == result.toLowerCase(),
    );

    if (alreadyExists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('כבר קיים אימון בשם הזה'),
        ),
      );
      return;
    }

    final workout = Workout(
      id: _createWorkoutId(),
      title: result,
      exercises: [],
    );

    setState(() {
      workouts.add(workout);
      selectedWorkout = workout;
      workoutNameController.text = workout.title;
      workoutNoteController.text = workout.note;
    });

    await _saveWorkouts();
  }

  Future<void> _deleteCurrentWorkout() async {
    if (selectedWorkout == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('מחיקת אימון'),
          content: Text('למחוק את "${selectedWorkout!.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('מחק'),
            ),
          ],
        );
      },
    ) ??
        false;

    if (!confirmed) {
      return;
    }

    setState(() {
      workouts.removeWhere((workout) => workout.id == selectedWorkout!.id);
      selectedWorkout = workouts.isNotEmpty ? workouts.first : null;

      if (selectedWorkout != null) {
        workoutNameController.text = selectedWorkout!.title;
        workoutNoteController.text = selectedWorkout!.note;
      } else {
        workoutNameController.clear();
        workoutNoteController.clear();
      }
    });

    await _saveWorkouts();
  }

  Future<void> _saveSelectedWorkoutMeta() async {
    if (selectedWorkout == null) {
      return;
    }

    final updatedWorkout = selectedWorkout!.copyWith(
      title: workoutNameController.text.trim(),
      note: workoutNoteController.text.trim(),
    );

    setState(() {
      final index =
      workouts.indexWhere((workout) => workout.id == selectedWorkout!.id);
      if (index != -1) {
        workouts[index] = updatedWorkout;
        selectedWorkout = updatedWorkout;
      }
    });

    await _saveWorkouts();
  }

  Future<void> selectExerciseAndAdd() async {
    if (selectedWorkout == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('יש לבחור או ליצור אימון קודם'),
        ),
      );
      return;
    }

    final selectedExercise = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ExerciseSelectionScreen(),
      ),
    );

    if (!mounted || selectedExercise == null || selectedExercise is! Exercise) {
      return;
    }

    final alreadyExists = currentExercises.any(
          (item) => item.exercise.id == selectedExercise.id,
    );

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('התרגיל הזה כבר קיים באימון'),
        ),
      );
      return;
    }

    final workoutExercise = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseDetailsScreen(exercise: selectedExercise),
      ),
    );

    if (!mounted ||
        workoutExercise == null ||
        workoutExercise is! WorkoutExercise) {
      return;
    }

    setState(() {
      currentExercises.add(workoutExercise);
    });

    await _saveWorkouts();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${selectedExercise.name} נוסף לאימון'),
      ),
    );
  }

  Future<void> _selectWorkout(Workout? workout) async {
    if (workout == null) {
      await _addWorkout();
      return;
    }

    setState(() {
      selectedWorkout = workout;
      workoutNameController.text = workout.title;
      workoutNoteController.text = workout.note;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('בניית אימונים'),
          actions: [
            IconButton(
              tooltip: 'אימון חדש',
              onPressed: _addWorkout,
              icon: const Icon(Icons.add),
            ),
            IconButton(
              tooltip: 'מחק אימון',
              onPressed: _deleteCurrentWorkout,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              DropdownButtonFormField<Workout?>(
                value: selectedWorkout,
                items: [
                  ...workouts.map((workout) {
                    return DropdownMenuItem<Workout?>(
                      value: workout,
                      child: Text(workout.title),
                    );
                  }),
                  const DropdownMenuItem<Workout?>(
                    value: null,
                    child: Text('➕ הוסף אימון'),
                  ),
                ],
                onChanged: _selectWorkout,
                decoration: const InputDecoration(
                  labelText: 'בחרי אימון',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: workoutNameController,
                onChanged: (_) => _saveSelectedWorkoutMeta(),
                enabled: selectedWorkout != null,
                decoration: const InputDecoration(
                  labelText: 'שם האימון',
                  hintText: 'למשל: A / רגליים / PUSH',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: workoutNoteController,
                onChanged: (_) => _saveSelectedWorkoutMeta(),
                enabled: selectedWorkout != null,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'הערה כללית לאימון',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectExerciseAndAdd,
                  child: const Text('בחירת תרגיל מהמאגר'),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: selectedWorkout == null
                    ? const Center(
                  child: Text('יש ליצור או לבחור אימון'),
                )
                    : currentExercises.isEmpty
                    ? const Center(
                  child: Text('עדיין לא נוספו תרגילים לאימון'),
                )
                    : ReorderableListView(
                  buildDefaultDragHandles: false,
                  onReorder: (oldIndex, newIndex) async {
                    setState(() {
                      if (newIndex > oldIndex) {
                        newIndex--;
                      }

                      final item = currentExercises.removeAt(oldIndex);
                      currentExercises.insert(newIndex, item);
                    });

                    await _saveWorkouts();
                  },
                  children: [
                    for (int i = 0; i < currentExercises.length; i++)
                      _buildExerciseCard(
                        context,
                        selectedWorkout!,
                        currentExercises[i],
                        i,
                        theme,
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
      int index,
      ThemeData theme,
      ) {
    final noteKey = _exerciseNoteKey(workout.id, workoutExercise.exercise.id);
    final traineeNote = traineeNotes[noteKey];

    return Card(
      key: ValueKey('${workoutExercise.exercise.id}_${selectedWorkout?.id}_$index'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.drag_handle),
                  ),
                ),
                Expanded(
                  child: Text(
                    workoutExercise.exercise.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    setState(() {
                      currentExercises.removeAt(index);
                    });

                    await _saveWorkouts();
                  },
                ),
              ],
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
            const SizedBox(height: 6),
            Text(workoutExercise.exercise.instructions),
            if (workoutExercise.note.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('הערה: ${workoutExercise.note}'),
            ],
            if (traineeNote != null && traineeNote.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6F3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'הערת מתאמן: $traineeNote',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _deleteTraineeNote(workout, workoutExercise),
                      icon: Icon(
                        Icons.delete_outline,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () async {
                  final updatedExercise = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExerciseDetailsScreen(
                        exercise: workoutExercise.exercise,
                        existingExercise: workoutExercise,
                      ),
                    ),
                  );

                  if (updatedExercise != null &&
                      updatedExercise is WorkoutExercise) {
                    setState(() {
                      currentExercises[index] = updatedExercise;
                    });

                    await _saveWorkouts();
                  }
                },
                child: const Text('עריכה'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}