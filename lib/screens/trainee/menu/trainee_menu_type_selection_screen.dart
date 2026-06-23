import 'package:flutter/material.dart';
import '../../../models/menu_type.dart';
import 'trainee_menu_screen.dart';

class TraineeMenuTypeSelectionScreen extends StatelessWidget {
  final String traineeId;

  const TraineeMenuTypeSelectionScreen({
    super.key,
    required this.traineeId,
  });

  void openMenu(BuildContext context, MenuType menuType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TraineeMenuScreen(
          menuType: menuType,
          traineeId: traineeId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('בחירת תפריט למתאמן'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'איזה תפריט להציג?',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    openMenu(context, MenuType.weekday);
                  },
                  child: const Text('תפריט אמצע שבוע'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    openMenu(context, MenuType.weekend);
                  },
                  child: const Text('תפריט סופ״ש'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}