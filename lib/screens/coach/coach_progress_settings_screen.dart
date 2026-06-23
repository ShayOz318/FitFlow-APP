import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoachProgressSettingsScreen extends StatefulWidget {
  const CoachProgressSettingsScreen({super.key});

  @override
  State<CoachProgressSettingsScreen> createState() =>
      _CoachProgressSettingsScreenState();
}

class _CoachProgressSettingsScreenState
    extends State<CoachProgressSettingsScreen> {
  static const String currentWeightKey = 'current_weight';
  static const String targetWeightKey = 'target_weight';
  static const String startingWeightKey = 'starting_weight';

  final TextEditingController currentWeightController = TextEditingController();
  final TextEditingController targetWeightController = TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeights();
  }

  @override
  void dispose() {
    currentWeightController.dispose();
    targetWeightController.dispose();
    super.dispose();
  }

  Future<void> _loadWeights() async {
    final prefs = await SharedPreferences.getInstance();

    final currentWeight = prefs.getDouble(currentWeightKey);
    final targetWeight = prefs.getDouble(targetWeightKey);

    setState(() {
      if (currentWeight != null) {
        currentWeightController.text = currentWeight.toString();
      }
      if (targetWeight != null) {
        targetWeightController.text = targetWeight.toString();
      }
      isLoading = false;
    });
  }

  Future<void> _saveWeights() async {
    final currentWeight = double.tryParse(currentWeightController.text);
    final targetWeight = double.tryParse(targetWeightController.text);

    if (currentWeight == null ||
        targetWeight == null ||
        currentWeight <= 0 ||
        targetWeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('יש להזין משקלים תקינים'),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    final existingStartingWeight = prefs.getDouble(startingWeightKey);
    if (existingStartingWeight == null) {
      await prefs.setDouble(startingWeightKey, currentWeight);
    }

    await prefs.setDouble(currentWeightKey, currentWeight);
    await prefs.setDouble(targetWeightKey, targetWeight);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('הנתונים נשמרו בהצלחה'),
      ),
    );
  }

  Future<void> _resetStartingWeight() async {
    final currentWeight = double.tryParse(currentWeightController.text);

    if (currentWeight == null || currentWeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('יש להזין קודם משקל נוכחי תקין'),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(startingWeightKey, currentWeight);

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
          title: const Text('מעקב התקדמות'),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              _buildSoftContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'נתוני התקדמות',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'כאן המאמן יכול לעדכן משקל נוכחי ומשקל יעד לצורך מעקב בדשבורד של המתאמן',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.4,
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
                        hintText: 'למשל 72.5',
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
                        hintText: 'למשל 65',
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveWeights,
                        child: const Text('שמור נתונים'),
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