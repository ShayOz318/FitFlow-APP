import 'package:flutter/material.dart';

import '../../data/trainee_repository.dart';
import '../../models/trainee.dart';
import '../../services/trainee_invite_service.dart';
import 'coach_trainee_profile_screen.dart';
import 'menu/menu_type_selection_screen.dart';
import 'workout/coach_workout_builder_screen.dart';

class CoachHomeScreen extends StatefulWidget {
  const CoachHomeScreen({super.key});

  @override
  State<CoachHomeScreen> createState() => _CoachHomeScreenState();
}

class _CoachHomeScreenState extends State<CoachHomeScreen> {
  final TraineeRepository _repository = TraineeRepository.instance;

  List<Trainee> trainees = [];
  String? selectedTraineeId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrainees();
  }

  Future<void> _loadTrainees() async {
    final loadedTrainees = await _repository.getTrainees();
    final activeId = await _repository.getActiveTraineeId();

    setState(() {
      trainees = loadedTrainees;
      if (loadedTrainees.isEmpty) {
        selectedTraineeId = null;
      } else if (activeId != null &&
          loadedTrainees.any((trainee) => trainee.id == activeId)) {
        selectedTraineeId = activeId;
      } else {
        selectedTraineeId = loadedTrainees.first.id;
      }
      isLoading = false;
    });

    if (selectedTraineeId != null) {
      await _repository.setActiveTrainee(selectedTraineeId!);
    }
  }

  Trainee? get selectedTrainee {
    if (selectedTraineeId == null) {
      return null;
    }
    for (final trainee in trainees) {
      if (trainee.id == selectedTraineeId) {
        return trainee;
      }
    }
    return null;
  }

  Future<void> _selectTrainee(String traineeId) async {
    await _repository.setActiveTrainee(traineeId);
    setState(() {
      selectedTraineeId = traineeId;
    });
  }

  Future<void> _addTrainee() async {
    final nameController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('הוספת מתאמן'),
            content: TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'שם המתאמן',
                hintText: 'למשל: שי',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('ביטול'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('הוסף'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) {
      nameController.dispose();
      return;
    }

    final name = nameController.text.trim();
    nameController.dispose();

    if (name.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('יש למלא שם למתאמן')),
      );
      return;
    }

    try {
      final trainee = await _repository.addTrainee(name: name);
      await _loadTrainees();
      await _selectTrainee(trainee.id);

      if (!mounted) {
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CoachTraineeProfileScreen(
            traineeId: trainee.id,
            isNewTrainee: true,
          ),
        ),
      );

      if (!mounted) {
        return;
      }

      await _loadTrainees();
    } on TraineeInviteException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _deleteSelectedTrainee() async {
    final trainee = selectedTrainee;
    if (trainee == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('מחיקת מתאמן'),
            content: Text(
              'למחוק את ${trainee.name} ואת כל הנתונים שלו/ה?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('ביטול'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('מחק'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _repository.deleteTrainee(trainee.id);
    await _loadTrainees();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${trainee.name} נמחק/ה')),
    );
  }

  void _openWithSelectedTrainee(Widget Function(String traineeId) builder) {
    final traineeId = selectedTraineeId;
    if (traineeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('יש לבחור או להוסיף מתאמן קודם')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => builder(traineeId)),
    ).then((_) => _loadTrainees());
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            _buildBackground(),
            SafeArea(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTopBar(context),
                          const SizedBox(height: 20),
                          const Text(
                            'אזור מאמן',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'בחרי מתאמן ונהלי עבורו תפריט, אימון ופרופיל',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildTraineeSection(),
                          const SizedBox(height: 16),
                          Expanded(
                            child: ListView(
                              children: [
                                _buildInfoCard(),
                                const SizedBox(height: 22),
                                _buildActionCard(
                                  title: 'בניית תפריט',
                                  subtitle:
                                      'יצירת תפריט אמצע שבוע או סופ״ש, ארוחות, מזונות והערות',
                                  icon: Icons.restaurant_menu,
                                  accent: const Color(0xFFFF6F61),
                                  enabled: selectedTraineeId != null,
                                  onTap: () {
                                    _openWithSelectedTrainee(
                                      (traineeId) => MenuTypeSelectionScreen(
                                        traineeId: traineeId,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildActionCard(
                                  title: 'בניית אימון',
                                  subtitle:
                                      'יצירת כמה אימונים שונים, תרגילים, זמני מנוחה וקצב עבודה',
                                  icon: Icons.sports_gymnastics,
                                  accent: const Color(0xFFFF9B8E),
                                  enabled: selectedTraineeId != null,
                                  onTap: () {
                                    _openWithSelectedTrainee(
                                      (traineeId) => CoachWorkoutBuilderScreen(
                                        traineeId: traineeId,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildActionCard(
                                  title: 'פרופיל מתאמן',
                                  subtitle:
                                      'עדכון שם, גיל, גובה, מטרה, משקל נוכחי ומשקל יעד',
                                  icon: Icons.person_outline,
                                  accent: const Color(0xFFFFB199),
                                  enabled: selectedTraineeId != null,
                                  onTap: () {
                                    _openWithSelectedTrainee(
                                      (traineeId) => CoachTraineeProfileScreen(
                                        traineeId: traineeId,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTraineeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'המתאמנים שלי',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _addTrainee,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('הוסף'),
            ),
            if (selectedTraineeId != null)
              IconButton(
                onPressed: _deleteSelectedTrainee,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                tooltip: 'מחק מתאמן',
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (trainees.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1EC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'עדיין אין מתאמנים. לחצי על "הוסף" כדי להתחיל.',
              style: TextStyle(color: Colors.black54),
            ),
          )
        else
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: trainees.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final trainee = trainees[index];
                final isSelected = trainee.id == selectedTraineeId;

                return GestureDetector(
                  onTap: () => _selectTrainee(trainee.id),
                  child: Container(
                    width: 120,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF6F61)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFF6F61)
                            : Colors.black12,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person,
                          color: isSelected ? Colors.white : const Color(0xFFFF6F61),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          trainee.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned(
          top: -70,
          left: -50,
          child: Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEFEA),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
        Positioned(
          bottom: -60,
          right: -40,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE2DA),
              borderRadius: BorderRadius.circular(110),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_forward_ios),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    final trainee = selectedTrainee;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFFFF1EC),
            child: Icon(
              trainee == null ? Icons.auto_awesome : Icons.person,
              color: const Color(0xFFFF6F61),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trainee == null ? 'ניהול חכם' : 'עובדים על: ${trainee.name}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  trainee == null
                      ? 'הוסיפי מתאמן ראשון כדי להתחיל לבנות תוכן'
                      : 'כל השינויים יישמרו רק עבור ${trainee.name}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: Colors.black45,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
