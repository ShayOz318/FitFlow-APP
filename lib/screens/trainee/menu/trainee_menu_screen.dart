import 'package:flutter/material.dart';

import '../../../data/coach_data_repository.dart';
import '../../../models/meal.dart';
import '../../../models/meal_item.dart';
import '../../../models/menu_type.dart';

class TraineeMenuScreen extends StatefulWidget {
  final MenuType menuType;
  final String traineeId;

  const TraineeMenuScreen({
    super.key,
    required this.menuType,
    required this.traineeId,
  });

  @override
  State<TraineeMenuScreen> createState() => _TraineeMenuScreenState();
}

class _TraineeMenuScreenState extends State<TraineeMenuScreen> {
  final CoachDataRepository _dataRepository = CoachDataRepository.instance;

  List<Meal> meals = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  String get screenTitle {
    return widget.menuType == MenuType.weekday
        ? 'תפריט אמצע שבוע'
        : 'תפריט סופ״ש';
  }

  Future<void> _loadMeals() async {
    final loadedMeals =
        await _dataRepository.getMeals(widget.traineeId, widget.menuType);

    setState(() {
      meals = loadedMeals;
      isLoading = false;
    });
  }

  double get totalCalories {
    double sum = 0;
    for (final meal in meals) {
      sum += meal.totalCalories;
    }
    return sum;
  }

  double get totalProtein {
    double sum = 0;
    for (final meal in meals) {
      sum += meal.totalProtein;
    }
    return sum;
  }

  double get totalCarbs {
    double sum = 0;
    for (final meal in meals) {
      sum += meal.totalCarbs;
    }
    return sum;
  }

  double get totalFat {
    double sum = 0;
    for (final meal in meals) {
      sum += meal.totalFat;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(screenTitle),
        ),
        body: isLoading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : meals.isEmpty
            ? const Center(
          child: Text(
            'עדיין לא נבנה תפריט',
            style: TextStyle(fontSize: 18),
          ),
        )
            : Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'היי 👋',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                screenTitle,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: meals.length,
                  itemBuilder: (context, index) {
                    final meal = meals[index];
                    return _buildMealCard(meal);
                  },
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      const Text(
                        'סיכום יומי',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildSummaryRow('קלוריות', totalCalories),
                      _buildSummaryRow('חלבון', totalProtein),
                      _buildSummaryRow('פחמימות', totalCarbs),
                      _buildSummaryRow('שומן', totalFat),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealCard(Meal meal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              meal.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (meal.note.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('הערת מאמן: ${meal.note}'),
              ),
            ],
            const SizedBox(height: 10),
            if (meal.items.isEmpty)
              const Text('אין פריטים בארוחה הזו')
            else
              Column(
                children: meal.items.map(_buildMealItemCard).toList(),
              ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 6),
            _buildSummaryRow('קלוריות בארוחה', meal.totalCalories),
            _buildSummaryRow('חלבון בארוחה', meal.totalProtein),
            _buildSummaryRow('פחמימות בארוחה', meal.totalCarbs),
            _buildSummaryRow('שומן בארוחה', meal.totalFat),
          ],
        ),
      ),
    );
  }

  Widget _buildMealItemCard(MealItem item) {
    final amountText = item.amountType == AmountType.grams
        ? '${item.amount.toStringAsFixed(0)} גרם'
        : '${item.amount.toStringAsFixed(0)} יחידות';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          iconColor: Colors.black54,
          collapsedIconColor: Colors.black54,
          title: Text(
            item.foodItem.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('כמות: $amountText'),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6F3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildValueRow('קלוריות', item.calories),
                  _buildValueRow('חלבון', item.protein),
                  _buildValueRow('פחמימות', item.carbs),
                  _buildValueRow('שומן', item.fat),
                  if (item.note.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'הערה: ${item.note}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueRow(String title, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            value.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(value.toStringAsFixed(1)),
        ],
      ),
    );
  }
}