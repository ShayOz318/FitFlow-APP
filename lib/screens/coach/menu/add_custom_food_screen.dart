import 'package:flutter/material.dart';

import '../../../data/food_repository.dart';

class AddCustomFoodScreen extends StatefulWidget {
  const AddCustomFoodScreen({super.key});

  @override
  State<AddCustomFoodScreen> createState() => _AddCustomFoodScreenState();
}

class _AddCustomFoodScreenState extends State<AddCustomFoodScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController caloriesController = TextEditingController();
  final TextEditingController proteinController = TextEditingController();
  final TextEditingController carbsController = TextEditingController();
  final TextEditingController fatController = TextEditingController();
  final TextEditingController gramsPerUnitController = TextEditingController();

  String selectedCategory = 'חלבון';
  bool supportsUnits = false;
  bool isSaving = false;

  final List<String> categories = [
    'חלבון',
    'פחמימה',
    'שומן',
    'פרי',
    'ירק',
    'מוצרי חלב',
    'אחר',
  ];

  @override
  void dispose() {
    nameController.dispose();
    caloriesController.dispose();
    proteinController.dispose();
    carbsController.dispose();
    fatController.dispose();
    gramsPerUnitController.dispose();
    super.dispose();
  }

  double? _parseOptional(String value) {
    if (value.trim().isEmpty) {
      return 0;
    }
    return double.tryParse(value.trim());
  }

  Future<void> _saveFood() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final calories = _parseOptional(caloriesController.text);
    final protein = _parseOptional(proteinController.text);
    final carbs = _parseOptional(carbsController.text);
    final fat = _parseOptional(fatController.text);
    final gramsPerUnit = _parseOptional(gramsPerUnitController.text);

    if (calories == null ||
        protein == null ||
        carbs == null ||
        fat == null ||
        gramsPerUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('יש להזין ערכים תזונתיים תקינים')),
      );
      return;
    }

    if (supportsUnits && gramsPerUnit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('יש להזין משקל ליחידה כשבוחרים מדידה ביחידות')),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    final food = await FoodRepository.addCustomFood(
      name: nameController.text,
      category: selectedCategory,
      caloriesPer100g: calories,
      proteinPer100g: protein,
      carbsPer100g: carbs,
      fatPer100g: fat,
      supportsUnits: supportsUnits,
      gramsPerUnit: supportsUnits ? gramsPerUnit : 0,
    );

    if (!mounted) {
      return;
    }

    Navigator.pop(context, food);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('הוספת מזון ידנית'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'הוסיפי מזון משלך למאגר המאמן',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'שם המזון',
                  hintText: 'למשל: סלט עוף ביתי',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'יש להזין שם מזון';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'קטגוריה',
                  border: OutlineInputBorder(),
                ),
                items: categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'ערכים תזונתיים ל-100 גרם',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: caloriesController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'קלוריות',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'שדה חובה' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: proteinController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'חלבון (גרם)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: carbsController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'פחמימות (גרם)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: fatController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'שומן (גרם)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('אפשר מדידה ביחידות'),
                subtitle: const Text('למשל: פרוסה, כף, יחידה'),
                value: supportsUnits,
                onChanged: (value) {
                  setState(() {
                    supportsUnits = value;
                  });
                },
              ),
              if (supportsUnits) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: gramsPerUnitController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'משקל יחידה (גרם)',
                    hintText: 'למשל: 30',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: isSaving ? null : _saveFood,
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('שמור מזון'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
