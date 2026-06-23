import 'package:flutter/material.dart';
import '../../../models/menu_type.dart';
import 'coach_menu_builder_screen.dart';

class MenuTypeSelectionScreen extends StatelessWidget {
  final String traineeId;

  const MenuTypeSelectionScreen({
    super.key,
    required this.traineeId,
  });

  void openMenuBuilder(BuildContext context, MenuType menuType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CoachMenuBuilderScreen(
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
          title: const Text('בחירת סוג תפריט'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'בחרי סוג תפריט',
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
                    openMenuBuilder(context, MenuType.weekday);
                  },
                  child: const Text('תפריט אמצע שבוע'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    openMenuBuilder(context, MenuType.weekend);
                  },
                  child: const Text('תפריט סוף שבוע'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}