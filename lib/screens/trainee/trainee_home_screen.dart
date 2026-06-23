import 'package:flutter/material.dart';

import '../../data/trainee_repository.dart';
import '../../models/trainee.dart';
import 'trainee_dashboard_screen.dart';

class TraineeHomeScreen extends StatefulWidget {
  const TraineeHomeScreen({super.key});

  @override
  State<TraineeHomeScreen> createState() => _TraineeHomeScreenState();
}

class _TraineeHomeScreenState extends State<TraineeHomeScreen> {
  final TraineeRepository _repository = TraineeRepository.instance;

  List<Trainee> trainees = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrainees();
  }

  Future<void> _loadTrainees() async {
    final loadedTrainees = await _repository.getTrainees();

    if (!mounted) {
      return;
    }

    if (loadedTrainees.length == 1) {
      _openDashboard(loadedTrainees.first);
      return;
    }

    setState(() {
      trainees = loadedTrainees;
      isLoading = false;
    });
  }

  void _openDashboard(Trainee trainee) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TraineeDashboardScreen(traineeId: trainee.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('בחירת מתאמן'),
        ),
        body: trainees.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'עדיין אין מתאמנים.\nהמאמן צריך להוסיף מתאמן באזור המאמן.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: trainees.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final trainee = trainees[index];

                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: Colors.black12),
                    ),
                    tileColor: Colors.white,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFF1EC),
                      child: Icon(
                        Icons.person,
                        color: Color(0xFFFF6F61),
                      ),
                    ),
                    title: Text(
                      trainee.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text('צפייה בתפריט, אימונים והתקדמות'),
                    trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
                    onTap: () => _openDashboard(trainee),
                  );
                },
              ),
      ),
    );
  }
}
