import 'package:flutter/material.dart';
import '../../../data/exercise_repository.dart';
import '../../../models/exercise.dart';

class ExerciseSelectionScreen extends StatefulWidget {
  const ExerciseSelectionScreen({super.key});

  @override
  State<ExerciseSelectionScreen> createState() =>
      _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
  String searchText = '';
  Set<String> selectedCategories = {'הכל'};

  final List<String> categories = [
    'הכל',
    'רגליים',
    'ישבן',
    'חזה',
    'גב',
    'כתפיים',
    'ידיים',
    'בטן',
  ];

  @override
  Widget build(BuildContext context) {
    final exercises = ExerciseRepository.exercises.where((exercise) {
      final matchesSearch = exercise.name.contains(searchText);

      final matchesCategory = selectedCategories.contains('הכל') ||
          selectedCategories.contains(exercise.category);

      return matchesSearch && matchesCategory;
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('בחירת תרגיל'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'חיפוש תרגיל...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    searchText = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategories.contains(category);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (category == 'הכל') {
                              selectedCategories = {'הכל'};
                            } else {
                              selectedCategories.remove('הכל');

                              if (selected) {
                                selectedCategories.add(category);
                              } else {
                                selectedCategories.remove(category);
                              }

                              if (selectedCategories.isEmpty) {
                                selectedCategories.add('הכל');
                              }
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: exercises.isEmpty
                    ? const Center(
                  child: Text('לא נמצאו תוצאות'),
                )
                    : ListView.builder(
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];

                    return Card(
                      child: ListTile(
                        title: Text(exercise.name),
                        subtitle: Text(
                          '${exercise.category} | ${exercise.muscleGroup}',
                        ),
                        trailing: const Icon(Icons.arrow_back_ios_new),
                        onTap: () {
                          Navigator.pop(context, exercise);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}