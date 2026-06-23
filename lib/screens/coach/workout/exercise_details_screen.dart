import 'package:flutter/material.dart';
import '../../../models/exercise.dart';
import '../../../models/workout_exercise.dart';

class ExerciseDetailsScreen extends StatefulWidget {
  final Exercise exercise;
  final WorkoutExercise? existingExercise;

  const ExerciseDetailsScreen({
    super.key,
    required this.exercise,
    this.existingExercise,
  });

  @override
  State<ExerciseDetailsScreen> createState() => _ExerciseDetailsScreenState();
}

class _ExerciseDetailsScreenState extends State<ExerciseDetailsScreen> {
  final TextEditingController setsController = TextEditingController();
  final TextEditingController repsController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController restController = TextEditingController();
  final TextEditingController tempoController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.existingExercise != null) {
      setsController.text = widget.existingExercise!.sets.toString();
      repsController.text = widget.existingExercise!.reps.toString();
      weightController.text = widget.existingExercise!.weight.toString();
      restController.text = widget.existingExercise!.restSeconds.toString();
      tempoController.text = widget.existingExercise!.tempo;
      noteController.text = widget.existingExercise!.note;
    } else {
      restController.text = '60';
    }
  }

  @override
  void dispose() {
    setsController.dispose();
    repsController.dispose();
    weightController.dispose();
    restController.dispose();
    tempoController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void confirmSelection() {
    final sets = int.tryParse(setsController.text);
    final reps = int.tryParse(repsController.text);
    final weight = double.tryParse(weightController.text);
    final restSeconds = int.tryParse(restController.text);

    if (sets == null || sets <= 0 || reps == null || reps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('יש להזין סטים וחזרות תקינים'),
        ),
      );
      return;
    }

    if (restSeconds == null || restSeconds < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('יש להזין זמן מנוחה תקין'),
        ),
      );
      return;
    }

    final workoutExercise = WorkoutExercise(
      exercise: widget.exercise,
      sets: sets,
      reps: reps,
      weight: weight ?? 0,
      restSeconds: restSeconds,
      tempo: tempoController.text.trim(),
      note: noteController.text.trim(),
    );

    Navigator.pop(context, workoutExercise);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingExercise != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'עריכת תרגיל' : 'הוספת תרגיל'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Text(
                widget.exercise.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.exercise.category} | ${widget.exercise.muscleGroup}',
              ),
              const SizedBox(height: 12),
              Text(
                widget.exercise.instructions,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: setsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'סטים',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: repsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'חזרות',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'משקל',
                  hintText: 'אם אין משקל אפשר להשאיר 0',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: restController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'מנוחה בין סטים (בשניות)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tempoController,
                decoration: const InputDecoration(
                  labelText: 'קצב עבודה',
                  hintText: 'למשל: 3-1-1 או איטי ומבוקר',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'הערה לתרגיל',
                  hintText: 'למשל: מנח גב ישר, טווח מלא, לא לנעול ברכיים',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: confirmSelection,
                  child: Text(isEditing ? 'עדכן תרגיל' : 'הוסף לאימון'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}