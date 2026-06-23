import 'package:flutter/material.dart';
import '../../../models/food_item.dart';
import '../../../models/meal_item.dart';

class FoodAmountScreen extends StatefulWidget {
  final FoodItem foodItem;
  final MealItem? existingItem;

  const FoodAmountScreen({
    super.key,
    required this.foodItem,
    this.existingItem,
  });

  @override
  State<FoodAmountScreen> createState() => _FoodAmountScreenState();
}

class _FoodAmountScreenState extends State<FoodAmountScreen> {
  late AmountType selectedAmountType;
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.existingItem != null) {
      selectedAmountType = widget.existingItem!.amountType;
      amountController.text = widget.existingItem!.amount.toString();
      noteController.text = widget.existingItem!.note;
    } else {
      selectedAmountType = AmountType.grams;
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void confirmSelection() {
    final amount = double.tryParse(amountController.text);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('יש להזין כמות תקינה'),
        ),
      );
      return;
    }

    final mealItem = MealItem(
      foodItem: widget.foodItem,
      amount: amount,
      amountType: selectedAmountType,
      note: noteController.text.trim(),
    );

    Navigator.pop(context, mealItem);
  }

  @override
  Widget build(BuildContext context) {
    final canUseUnits = widget.foodItem.supportsUnits;
    final isEditing = widget.existingItem != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'עריכת פריט' : 'הוספת מזון'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Text(
                widget.foodItem.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.foodItem.caloriesPer100g} קלוריות | '
                    '${widget.foodItem.proteinPer100g} חלבון | '
                    '${widget.foodItem.carbsPer100g} פחמימה | '
                    '${widget.foodItem.fatPer100g} שומן',
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<AmountType>(
                value: selectedAmountType,
                items: [
                  const DropdownMenuItem(
                    value: AmountType.grams,
                    child: Text('גרמים'),
                  ),
                  if (canUseUnits)
                    const DropdownMenuItem(
                      value: AmountType.units,
                      child: Text('יחידות'),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    selectedAmountType = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'סוג כמות',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: selectedAmountType == AmountType.grams
                      ? 'כמות בגרמים'
                      : 'כמות ביחידות',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'הערה למוצר',
                  hintText: 'למשל: מבושל, ללא שמן, לפני אימון',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: confirmSelection,
                  child: Text(isEditing ? 'עדכן פריט' : 'הוסף לתפריט'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}