import '../data/food_repository.dart';
import 'food_item.dart';

enum AmountType {
  grams,
  units,
}

class MealItem {
  final FoodItem foodItem;
  final double amount;
  final AmountType amountType;
  final String note;

  const MealItem({
    required this.foodItem,
    required this.amount,
    required this.amountType,
    this.note = '',
  });

  double get amountInGrams {
    if (amountType == AmountType.grams) {
      return amount;
    }

    return amount * foodItem.gramsPerUnit;
  }

  double get calories => foodItem.caloriesPer100g * amountInGrams / 100;
  double get protein => foodItem.proteinPer100g * amountInGrams / 100;
  double get carbs => foodItem.carbsPer100g * amountInGrams / 100;
  double get fat => foodItem.fatPer100g * amountInGrams / 100;

  Map<String, dynamic> toMap() {
    return {
      'foodId': foodItem.id,
      'food': foodItem.toMap(),
      'amount': amount,
      'amountType': amountType.name,
      'note': note,
    };
  }

  factory MealItem.fromMap(Map<String, dynamic> map) {
    FoodItem foodItem;

    if (map['food'] != null) {
      foodItem = FoodItem.fromMap(Map<String, dynamic>.from(map['food'] as Map));
      if (foodItem.isOnline) {
        FoodRepository.rememberOnlineFood(foodItem);
      }
    } else {
      final foodId = map['foodId'] as int;
      final cachedFood = FoodRepository.getById(foodId);
      if (cachedFood == null) {
        throw Exception('לא נמצא מזון עם מזהה $foodId');
      }
      foodItem = cachedFood;
    }

    return MealItem(
      foodItem: foodItem,
      amount: (map['amount'] as num).toDouble(),
      amountType: AmountType.values.firstWhere(
        (type) => type.name == map['amountType'],
      ),
      note: map['note'] as String? ?? '',
    );
  }
}
