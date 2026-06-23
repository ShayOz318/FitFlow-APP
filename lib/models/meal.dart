import 'meal_item.dart';

class Meal {
  final String title;
  final List<MealItem> items;
  final String note;
  final bool isDefault;

  Meal({
    required this.title,
    required this.items,
    this.note = '',
    this.isDefault = false,
  });

  double get totalCalories {
    double sum = 0;
    for (final item in items) {
      sum += item.calories;
    }
    return sum;
  }

  double get totalProtein {
    double sum = 0;
    for (final item in items) {
      sum += item.protein;
    }
    return sum;
  }

  double get totalCarbs {
    double sum = 0;
    for (final item in items) {
      sum += item.carbs;
    }
    return sum;
  }

  double get totalFat {
    double sum = 0;
    for (final item in items) {
      sum += item.fat;
    }
    return sum;
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'items': items.map((item) => item.toMap()).toList(),
      'note': note,
      'isDefault': isDefault,
    };
  }

  factory Meal.fromMap(Map<String, dynamic> map) {
    final itemsList = map['items'] as List<dynamic>? ?? [];

    return Meal(
      title: map['title'] as String,
      items: itemsList
          .map((item) => MealItem.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      note: map['note'] as String? ?? '',
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }

  Meal copyWith({
    String? title,
    List<MealItem>? items,
    String? note,
    bool? isDefault,
  }) {
    return Meal(
      title: title ?? this.title,
      items: items ?? this.items,
      note: note ?? this.note,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}