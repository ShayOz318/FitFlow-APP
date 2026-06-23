import 'package:flutter/material.dart';

import '../../data/coach_data_repository.dart';
import '../../data/trainee_repository.dart';
import '../../models/trainee_profile_data.dart';
import '../../models/weight_entry.dart';
import '../../services/trainee_invite_service.dart';

class CoachTraineeProfileScreen extends StatefulWidget {
  final String traineeId;
  final bool isNewTrainee;

  const CoachTraineeProfileScreen({
    super.key,
    required this.traineeId,
    this.isNewTrainee = false,
  });

  @override
  State<CoachTraineeProfileScreen> createState() =>
      _CoachTraineeProfileScreenState();
}

class _CoachTraineeProfileScreenState extends State<CoachTraineeProfileScreen> {
  final TraineeRepository _repository = TraineeRepository.instance;
  final CoachDataRepository _dataRepository = CoachDataRepository.instance;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController goalController = TextEditingController();
  final TextEditingController currentWeightController = TextEditingController();
  final TextEditingController targetWeightController = TextEditingController();

  bool isLoading = true;
  List<WeightEntry> weightHistory = [];
  bool _inviteReady = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    ageController.dispose();
    heightController.dispose();
    goalController.dispose();
    currentWeightController.dispose();
    targetWeightController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await _dataRepository.getProfile(widget.traineeId);
    final trainees = await _repository.getTrainees();
    var email = '';
    for (final trainee in trainees) {
      if (trainee.id == widget.traineeId) {
        email = trainee.email;
        break;
      }
    }

    setState(() {
      nameController.text = profile.name;
      emailController.text = email;
      ageController.text = profile.age?.toString() ?? '';
      heightController.text = profile.height?.toString() ?? '';
      goalController.text = profile.goal;
      currentWeightController.text = profile.currentWeight?.toString() ?? '';
      targetWeightController.text = profile.targetWeight?.toString() ?? '';
      weightHistory = profile.weightHistory;
      _inviteReady = email.isNotEmpty;
      isLoading = false;
    });
  }

  String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  List<WeightEntry> _updatedWeightHistory(
    List<WeightEntry> history,
    double currentWeight,
  ) {
    final today = _todayKey();
    final updated = [...history];
    final existingIndex = updated.indexWhere((entry) => entry.date == today);

    if (existingIndex != -1) {
      updated[existingIndex] = WeightEntry(date: today, weight: currentWeight);
    } else {
      updated.add(WeightEntry(date: today, weight: currentWeight));
    }

    return updated;
  }

  Future<void> _saveProfile() async {

    final age = int.tryParse(ageController.text.trim());
    final height = double.tryParse(heightController.text.trim());
    final currentWeight = double.tryParse(currentWeightController.text.trim());
    final targetWeight = double.tryParse(targetWeightController.text.trim());

    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('יש להזין שם מתאמן'),
        ),
      );
      return;
    }

    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('יש להזין אימייל למתאמן'),
        ),
      );
      return;
    }

    if (ageController.text.trim().isNotEmpty && (age == null || age <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('יש להזין גיל תקין'),
        ),
      );
      return;
    }

    if (heightController.text.trim().isNotEmpty &&
        (height == null || height <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('יש להזין גובה תקין'),
        ),
      );
      return;
    }

    if (currentWeightController.text.trim().isNotEmpty &&
        (currentWeight == null || currentWeight <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('יש להזין משקל נוכחי תקין'),
        ),
      );
      return;
    }

    if (targetWeightController.text.trim().isNotEmpty &&
        (targetWeight == null || targetWeight <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('יש להזין משקל יעד תקין'),
        ),
      );
      return;
    }

    try {
      await _repository.saveTraineeAccessEmail(
        traineeId: widget.traineeId,
        email: emailController.text.trim(),
        name: nameController.text.trim(),
      );
    } on TraineeInviteException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
      return;
    }

    await _repository.updateTraineeName(
      widget.traineeId,
      nameController.text.trim(),
    );

    final existingProfile =
        await _dataRepository.getProfileLocal(widget.traineeId);
    var startingWeight = existingProfile.startingWeight;
    var updatedHistory = existingProfile.weightHistory;

    if (currentWeight != null) {
      if (startingWeight == null) {
        startingWeight = currentWeight;
      }
      updatedHistory = _updatedWeightHistory(updatedHistory, currentWeight);
    }

    final profile = TraineeProfileData(
      name: nameController.text.trim(),
      age: age,
      height: height,
      goal: goalController.text.trim(),
      currentWeight: currentWeight,
      targetWeight: targetWeight,
      startingWeight: startingWeight,
      weightHistory: updatedHistory,
    );

    await _dataRepository.saveProfile(widget.traineeId, profile);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('פרופיל המתאמן נשמר בהצלחה')),
    );

    Navigator.pop(context);
  }

  Future<void> _resetStartingWeight() async {
    final currentWeight = double.tryParse(currentWeightController.text.trim());

    if (currentWeight == null || currentWeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('יש להזין קודם משקל נוכחי תקין'),
        ),
      );
      return;
    }

    await _dataRepository.setStartingWeight(widget.traineeId, currentWeight);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('משקל ההתחלה אופס למשקל הנוכחי'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('פרופיל מתאמן'),
        ),
        body: isLoading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              _buildSoftContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'פרטים אישיים',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'כאן אפשר לעדכן את פרטי המתאמן ואת נתוני ההתקדמות שלו',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isNewTrainee) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1EC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'מלאי את פרטי המתאמן ולחצי שמור פרופיל. רק אחרי השמירה המתאמן יוכל להירשם לאפליקציה עם האימייל שתזיני.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _buildSoftContainer(
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'שם מתאמן',
                        hintText: 'למשל: שי',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'אימייל המתאמן',
                        hintText: 'למשל: shay@example.com',
                        helperText: _inviteReady
                            ? 'המתאמן יכול להירשם עם האימייל הזה'
                            : 'לאחר שמירת הפרופיל המתאמן יוכל להירשם עם האימייל הזה',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'גיל',
                        hintText: 'למשל: 24',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: heightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'גובה',
                        hintText: 'למשל: 170',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: goalController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'מטרה',
                        hintText:
                        'למשל: ירידה במשקל ושמירה על חלבון גבוה',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSoftContainer(
                child: Column(
                  children: [
                    TextField(
                      controller: currentWeightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'משקל נוכחי',
                        hintText: 'למשל: 72.5',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: targetWeightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'משקל יעד',
                        hintText: 'למשל: 65',
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        child: const Text('שמור פרופיל'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _resetStartingWeight,
                        child: const Text('אפס משקל התחלה למשקל הנוכחי'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSoftContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'היסטוריית משקלים',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (weightHistory.isEmpty)
                      const Text(
                        'עדיין אין היסטוריית משקלים',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      )
                    else
                      ...weightHistory.reversed.map(
                            (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '${entry.date} - ${entry.weight.toStringAsFixed(1)} ק״ג',
                            style: const TextStyle(fontSize: 14),
                          ),
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

  Widget _buildSoftContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}