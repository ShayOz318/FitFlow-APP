import 'package:flutter/material.dart';

import '../../../data/coach_data_repository.dart';
import '../../../data/food_repository.dart';
import '../../../models/food_item.dart';
import '../../../models/meal.dart';
import '../../../models/meal_item.dart';
import '../../../models/menu_type.dart';
import 'food_amount_screen.dart';
import 'food_selection_screen.dart';

class CoachMenuBuilderScreen extends StatefulWidget {
  final MenuType menuType;
  final String traineeId;

  const CoachMenuBuilderScreen({
    super.key,
    required this.menuType,
    required this.traineeId,
  });

  @override
  State<CoachMenuBuilderScreen> createState() =>
      _CoachMenuBuilderScreenState();
}

class _CoachMenuBuilderScreenState extends State<CoachMenuBuilderScreen> {
  final CoachDataRepository _dataRepository = CoachDataRepository.instance;

  late List<Meal> meals;
  Meal? selectedMeal;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    meals = _defaultMeals();
    _loadMeals();
  }

  List<Meal> _defaultMeals() {
    return [
      Meal(title: 'ארוחת בוקר', items: [], isDefault: true),
      Meal(title: 'ארוחת צהריים', items: [], isDefault: true),
      Meal(title: 'ארוחת ערב', items: [], isDefault: true),
    ];
  }

  MenuType get oppositeMenuType {
    return widget.menuType == MenuType.weekday
        ? MenuType.weekend
        : MenuType.weekday;
  }

  String get oppositeMenuLabel {
    return widget.menuType == MenuType.weekday
        ? 'סופ״ש'
        : 'אמצע שבוע';
  }

  Future<void> _saveMeals() async {
    await _dataRepository.saveMeals(widget.traineeId, widget.menuType, meals);
  }

  Future<void> _saveMealsToMenuType(
    MenuType menuType,
    List<Meal> mealsToSave,
  ) async {
    await _dataRepository.saveMeals(
      widget.traineeId,
      menuType,
      mealsToSave,
    );
  }

  Future<void> _loadMeals() async {
    await FoodRepository.ensureCustomFoodsLoaded();
    final loadedMeals =
        await _dataRepository.getMeals(widget.traineeId, widget.menuType);

    if (loadedMeals.isEmpty) {
      setState(() {
        meals = _defaultMeals();
        isLoading = false;
      });
      return;
    }

    setState(() {
      meals = loadedMeals;
      isLoading = false;
    });
  }

  Future<void> addMeal() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('הוספת ארוחה'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'שם הארוחה',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, controller.text.trim());
              },
              child: const Text('הוסף'),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty) {
      return;
    }

    final alreadyExists = meals.any(
          (meal) => meal.title.trim().toLowerCase() == result.toLowerCase(),
    );

    if (alreadyExists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('כבר קיימת ארוחה בשם הזה'),
        ),
      );
      return;
    }

    final newMeal = Meal(
      title: result,
      items: [],
      isDefault: false,
    );

    setState(() {
      meals.add(newMeal);
      selectedMeal = newMeal;
    });

    await _saveMeals();
  }

  Future<void> editMealName(Meal meal, int index) async {
    final controller = TextEditingController(text: meal.title);

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('עריכת שם ארוחה'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'שם הארוחה',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, controller.text.trim());
              },
              child: const Text('שמור'),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty || result == meal.title) {
      return;
    }

    final alreadyExists = meals.asMap().entries.any(
          (entry) =>
      entry.key != index &&
          entry.value.title.trim().toLowerCase() == result.toLowerCase(),
    );

    if (alreadyExists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('כבר קיימת ארוחה בשם הזה'),
        ),
      );
      return;
    }

    final updatedMeal = meal.copyWith(title: result);

    setState(() {
      meals[index] = updatedMeal;
      if (selectedMeal == meal) {
        selectedMeal = updatedMeal;
      }
    });

    await _saveMeals();
  }

  Future<void> editMealNote(Meal meal, int index) async {
    final controller = TextEditingController(text: meal.note);

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('הערה ל${meal.title}'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'כתבי הערה לארוחה',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, controller.text.trim());
              },
              child: const Text('שמור'),
            ),
          ],
        );
      },
    );

    if (result == null) {
      return;
    }

    final updatedMeal = meal.copyWith(note: result);

    setState(() {
      meals[index] = updatedMeal;
      if (selectedMeal == meal) {
        selectedMeal = updatedMeal;
      }
    });

    await _saveMeals();
  }

  Future<void> deleteMeal(Meal meal, int index) async {
    if (meal.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('אי אפשר למחוק ארוחת ברירת מחדל'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('מחיקת ארוחה'),
          content: Text('למחוק את "${meal.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('מחק'),
            ),
          ],
        );
      },
    ) ??
        false;

    if (!confirmed) {
      return;
    }

    setState(() {
      if (selectedMeal == meal) {
        selectedMeal = null;
      }
      meals.removeAt(index);
    });

    await _saveMeals();
  }

  Future<void> duplicateMenuToOtherType() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('שכפול תפריט'),
          content: Text(
            'לשכפל את התפריט הזה אל תפריט $oppositeMenuLabel?\nהפעולה תדרוס את התפריט הקיים שם.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('שכפל'),
            ),
          ],
        );
      },
    ) ??
        false;

    if (!confirmed) {
      return;
    }

    final duplicatedMeals = meals
        .map(
          (meal) => Meal(
        title: meal.title,
        items: meal.items
            .map(
              (item) => MealItem(
            foodItem: item.foodItem,
            amount: item.amount,
            amountType: item.amountType,
            note: item.note,
          ),
        )
            .toList(),
        note: meal.note,
        isDefault: meal.isDefault,
      ),
    )
        .toList();

    await _saveMealsToMenuType(oppositeMenuType, duplicatedMeals);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('התפריט שוכפל בהצלחה ל$oppositeMenuLabel'),
      ),
    );
  }

  Future<void> selectFoodAndAdd() async {
    if (selectedMeal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('יש לבחור ארוחה קודם'),
        ),
      );
      return;
    }

    final selectedFood = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FoodSelectionScreen(),
      ),
    );

    if (!mounted || selectedFood == null || selectedFood is! FoodItem) {
      return;
    }

    final alreadyExists = selectedMeal!.items.any(
          (item) => item.foodItem.id == selectedFood.id,
    );

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('המזון הזה כבר קיים בארוחה'),
        ),
      );
      return;
    }

    final mealItem = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FoodAmountScreen(foodItem: selectedFood),
      ),
    );

    if (!mounted || mealItem == null || mealItem is! MealItem) {
      return;
    }

    setState(() {
      selectedMeal!.items.add(mealItem);
    });

    await _saveMeals();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${selectedFood.name} נוסף ל${selectedMeal!.title}'),
      ),
    );
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

  String get screenTitle {
    return widget.menuType == MenuType.weekday
        ? 'בניית תפריט אמצע שבוע'
        : 'בניית תפריט סופ״ש';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(screenTitle),
          actions: [
            IconButton(
              tooltip: 'שכפל תפריט',
              onPressed: duplicateMenuToOtherType,
              icon: const Icon(Icons.copy_all),
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              DropdownButtonFormField<Meal?>(
                value: selectedMeal,
                items: [
                  ...meals.map((meal) {
                    return DropdownMenuItem<Meal?>(
                      value: meal,
                      child: Text(meal.title),
                    );
                  }),
                  const DropdownMenuItem<Meal?>(
                    value: null,
                    child: Text('➕ הוסף ארוחה'),
                  ),
                ],
                onChanged: (value) async {
                  if (value == null) {
                    await addMeal();
                    return;
                  }

                  setState(() {
                    selectedMeal = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'בחרי ארוחה',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectFoodAndAdd,
                  child: const Text('בחירת מזון מהמאגר'),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ReorderableListView(
                  buildDefaultDragHandles: false,
                  onReorder: (oldIndex, newIndex) async {
                    setState(() {
                      if (newIndex > oldIndex) {
                        newIndex--;
                      }

                      final item = meals.removeAt(oldIndex);
                      meals.insert(newIndex, item);
                    });

                    await _saveMeals();
                  },
                  children: [
                    for (int i = 0; i < meals.length; i++)
                      buildMealCard(meals[i], i),
                  ],
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      const Text(
                        'סיכום יומי',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('קלוריות: ${totalCalories.toStringAsFixed(1)}'),
                      Text('חלבון: ${totalProtein.toStringAsFixed(1)}'),
                      Text('פחמימות: ${totalCarbs.toStringAsFixed(1)}'),
                      Text('שומן: ${totalFat.toStringAsFixed(1)}'),
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

  Widget buildMealCard(Meal meal, int index) {
    return Card(
      key: ValueKey('${meal.title}_$index'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.drag_handle),
                  ),
                ),
                Expanded(
                  child: Text(
                    meal.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'הערה לארוחה',
                  onPressed: () => editMealNote(meal, index),
                  icon: const Icon(Icons.note_alt_outlined),
                ),
                IconButton(
                  tooltip: 'עריכת שם',
                  onPressed: () => editMealName(meal, index),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'מחיקת ארוחה',
                  onPressed: () => deleteMeal(meal, index),
                  icon: Icon(
                    Icons.delete_outline,
                    color: meal.isDefault ? Colors.grey : Colors.red,
                  ),
                ),
              ],
            ),
            if (meal.note.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('הערה: ${meal.note}'),
              ),
            ],
            const SizedBox(height: 8),
            if (meal.items.isEmpty)
              const Text('אין פריטים')
            else
              Column(
                children: meal.items.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;

                  final amountText = item.amountType == AmountType.grams
                      ? '${item.amount.toStringAsFixed(0)} גרם'
                      : '${item.amount.toStringAsFixed(0)} יחידות';

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.foodItem.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$amountText | '
                              '${item.calories.toStringAsFixed(1)} קלוריות | '
                              '${item.protein.toStringAsFixed(1)} חלבון | '
                              '${item.carbs.toStringAsFixed(1)} פחמימות | '
                              '${item.fat.toStringAsFixed(1)} שומן',
                        ),
                        if (item.note.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('הערה: ${item.note}'),
                          ),
                      ],
                    ),
                    onTap: () async {
                      final updatedItem = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FoodAmountScreen(
                            foodItem: item.foodItem,
                            existingItem: item,
                          ),
                        ),
                      );

                      if (!mounted ||
                          updatedItem == null ||
                          updatedItem is! MealItem) {
                        return;
                      }

                      setState(() {
                        meal.items[i] = updatedItem;
                      });

                      await _saveMeals();
                    },
                    trailing: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 12),
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          setState(() {
                            meal.items.removeAt(i);
                          });

                          await _saveMeals();
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 8),
            Text(
              'סה״כ: ${meal.totalCalories.toStringAsFixed(1)} קלוריות | '
                  '${meal.totalProtein.toStringAsFixed(1)} חלבון | '
                  '${meal.totalCarbs.toStringAsFixed(1)} פחמימות | '
                  '${meal.totalFat.toStringAsFixed(1)} שומן',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}