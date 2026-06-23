import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'open_food_facts_service.dart';
import '../models/food_item.dart';
import '../models/food_search_result.dart';
import '../services/firestore_service.dart';

class FoodRepository {
  static const String _customFoodsKey = 'coach_custom_foods';
  static const int _customFoodIdStart = 900001;

  static final Map<int, FoodItem> _onlineCache = {};
  static List<FoodItem> _customFoods = [];
  static bool _customFoodsLoaded = false;

  static final FirestoreService _firestore = FirestoreService.instance;

  static void replaceCustomFoodsCache(List<FoodItem> foods) {
    _customFoods = List<FoodItem>.from(foods);
    _customFoodsLoaded = true;
  }

  static Future<void> ensureCustomFoodsLoaded() async {
    if (_customFoodsLoaded) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customFoodsKey);
    if (raw == null || raw.isEmpty) {
      _customFoods = [];
      _customFoodsLoaded = true;
      return;
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _customFoods = decoded
          .map((item) => FoodItem.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      _customFoods = [];
    }

    await _loadCustomFoodsFromFirestore();
    _customFoodsLoaded = true;
  }

  static Future<void> _loadCustomFoodsFromFirestore() async {
    final collection = _firestore.customFoodsCollection();
    if (collection == null) {
      return;
    }

    try {
      final snapshot = await collection.get();
      if (snapshot.docs.isEmpty) {
        return;
      }

      _customFoods = snapshot.docs
          .map((doc) => FoodItem.fromMap(doc.data()))
          .toList();
      await _saveCustomFoods();
    } catch (_) {}
  }

  static Future<FoodItem> addCustomFood({
    required String name,
    required String category,
    required double caloriesPer100g,
    required double proteinPer100g,
    required double carbsPer100g,
    required double fatPer100g,
    bool supportsUnits = false,
    double gramsPerUnit = 0,
  }) async {
    await ensureCustomFoodsLoaded();

    final nextId = _customFoods.isEmpty
        ? _customFoodIdStart
        : _customFoods.map((food) => food.id).reduce((a, b) => a > b ? a : b) +
            1;

    final food = FoodItem(
      id: nextId,
      name: name.trim(),
      category: category,
      caloriesPer100g: caloriesPer100g,
      proteinPer100g: proteinPer100g,
      carbsPer100g: carbsPer100g,
      fatPer100g: fatPer100g,
      supportsUnits: supportsUnits,
      gramsPerUnit: gramsPerUnit,
      source: FoodSource.custom,
    );

    _customFoods.add(food);
    await _saveCustomFoods();
    await _syncCustomFoodToFirestore(food);
    return food;
  }

  static Future<void> _syncCustomFoodToFirestore(FoodItem food) async {
    final collection = _firestore.customFoodsCollection();
    if (collection == null) {
      return;
    }

    try {
      await collection.doc('${food.id}').set(
        {
          ...food.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  static Future<void> _saveCustomFoods() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _customFoodsKey,
      jsonEncode(_customFoods.map((food) => food.toMap()).toList()),
    );
  }

  static List<FoodItem> get customFoods => List.unmodifiable(_customFoods);

  static final List<FoodItem> foods = [
    const FoodItem(
      id: 1,
      name: 'חזה עוף',
      category: 'חלבון',
      caloriesPer100g: 165,
      proteinPer100g: 31,
      carbsPer100g: 0,
      fatPer100g: 3.6,
    ),
    const FoodItem(
      id: 2,
      name: 'טונה במים',
      category: 'חלבון',
      caloriesPer100g: 116,
      proteinPer100g: 26,
      carbsPer100g: 0,
      fatPer100g: 1,
    ),
    const FoodItem(
      id: 3,
      name: 'ביצה',
      category: 'חלבון',
      caloriesPer100g: 155,
      proteinPer100g: 13,
      carbsPer100g: 1.1,
      fatPer100g: 11,
      supportsUnits: true,
      gramsPerUnit: 50,
    ),
    const FoodItem(
      id: 4,
      name: 'בשר בקר רזה',
      category: 'חלבון',
      caloriesPer100g: 250,
      proteinPer100g: 26,
      carbsPer100g: 0,
      fatPer100g: 15,
    ),
    const FoodItem(
      id: 5,
      name: 'קוטג׳ 5%',
      category: 'מוצרי חלב',
      caloriesPer100g: 98,
      proteinPer100g: 11,
      carbsPer100g: 3,
      fatPer100g: 5,
    ),
    const FoodItem(
      id: 6,
      name: 'יוגורט חלבון',
      category: 'מוצרי חלב',
      caloriesPer100g: 60,
      proteinPer100g: 10,
      carbsPer100g: 4,
      fatPer100g: 0.5,
      supportsUnits: true,
      gramsPerUnit: 200,
    ),
    const FoodItem(
      id: 7,
      name: 'גבינה צהובה',
      category: 'מוצרי חלב',
      caloriesPer100g: 402,
      proteinPer100g: 25,
      carbsPer100g: 1.3,
      fatPer100g: 33,
    ),
    const FoodItem(
      id: 8,
      name: 'אורז לבן',
      category: 'פחמימה',
      caloriesPer100g: 130,
      proteinPer100g: 2.7,
      carbsPer100g: 28,
      fatPer100g: 0.3,
    ),
    const FoodItem(
      id: 9,
      name: 'אורז מלא',
      category: 'פחמימה',
      caloriesPer100g: 112,
      proteinPer100g: 2.6,
      carbsPer100g: 23,
      fatPer100g: 0.9,
    ),
    const FoodItem(
      id: 10,
      name: 'שיבולת שועל',
      category: 'פחמימה',
      caloriesPer100g: 389,
      proteinPer100g: 16.9,
      carbsPer100g: 66.3,
      fatPer100g: 6.9,
    ),
    const FoodItem(
      id: 11,
      name: 'לחם לבן',
      category: 'פחמימה',
      caloriesPer100g: 265,
      proteinPer100g: 9,
      carbsPer100g: 49,
      fatPer100g: 3.2,
      supportsUnits: true,
      gramsPerUnit: 30,
    ),
    const FoodItem(
      id: 12,
      name: 'לחם קל',
      category: 'פחמימה',
      caloriesPer100g: 210,
      proteinPer100g: 9,
      carbsPer100g: 40,
      fatPer100g: 2.5,
      supportsUnits: true,
      gramsPerUnit: 25,
    ),
    const FoodItem(
      id: 13,
      name: 'פסטה מבושלת',
      category: 'פחמימה',
      caloriesPer100g: 131,
      proteinPer100g: 5,
      carbsPer100g: 25,
      fatPer100g: 1.1,
    ),
    const FoodItem(
      id: 14,
      name: 'בטטה',
      category: 'פחמימה',
      caloriesPer100g: 86,
      proteinPer100g: 1.6,
      carbsPer100g: 20,
      fatPer100g: 0.1,
    ),
    const FoodItem(
      id: 15,
      name: 'אבוקדו',
      category: 'שומן',
      caloriesPer100g: 160,
      proteinPer100g: 2,
      carbsPer100g: 9,
      fatPer100g: 15,
    ),
    const FoodItem(
      id: 16,
      name: 'שמן זית',
      category: 'שומן',
      caloriesPer100g: 884,
      proteinPer100g: 0,
      carbsPer100g: 0,
      fatPer100g: 100,
    ),
    const FoodItem(
      id: 17,
      name: 'שקדים',
      category: 'שומן',
      caloriesPer100g: 579,
      proteinPer100g: 21,
      carbsPer100g: 22,
      fatPer100g: 50,
    ),
    const FoodItem(
      id: 18,
      name: 'אגוזי מלך',
      category: 'שומן',
      caloriesPer100g: 654,
      proteinPer100g: 15,
      carbsPer100g: 14,
      fatPer100g: 65,
    ),
    const FoodItem(
      id: 19,
      name: 'תפוח',
      category: 'פרי',
      caloriesPer100g: 52,
      proteinPer100g: 0.3,
      carbsPer100g: 14,
      fatPer100g: 0.2,
      supportsUnits: true,
      gramsPerUnit: 150,
    ),
    const FoodItem(
      id: 20,
      name: 'בננה',
      category: 'פרי',
      caloriesPer100g: 89,
      proteinPer100g: 1.1,
      carbsPer100g: 23,
      fatPer100g: 0.3,
      supportsUnits: true,
      gramsPerUnit: 120,
    ),
    const FoodItem(
      id: 21,
      name: 'תמר',
      category: 'פרי',
      caloriesPer100g: 277,
      proteinPer100g: 2,
      carbsPer100g: 75,
      fatPer100g: 0.2,
      supportsUnits: true,
      gramsPerUnit: 20,
    ),
    const FoodItem(
      id: 22,
      name: 'מלפפון',
      category: 'ירק',
      caloriesPer100g: 15,
      proteinPer100g: 0.7,
      carbsPer100g: 3.6,
      fatPer100g: 0.1,
    ),
    const FoodItem(
      id: 23,
      name: 'עגבנייה',
      category: 'ירק',
      caloriesPer100g: 18,
      proteinPer100g: 0.9,
      carbsPer100g: 3.9,
      fatPer100g: 0.2,
    ),
    const FoodItem(
      id: 24,
      name: 'ברוקולי',
      category: 'ירק',
      caloriesPer100g: 34,
      proteinPer100g: 2.8,
      carbsPer100g: 7,
      fatPer100g: 0.4,
    ),
    const FoodItem(
      id: 25,
      name: 'גזר',
      category: 'ירק',
      caloriesPer100g: 41,
      proteinPer100g: 0.9,
      carbsPer100g: 10,
      fatPer100g: 0.2,
    ),
  ];

  static FoodItem? getById(int id) {
    for (final food in _customFoods) {
      if (food.id == id) {
        return food;
      }
    }

    try {
      return foods.firstWhere((food) => food.id == id);
    } catch (_) {
      return _onlineCache[id];
    }
  }

  static void rememberOnlineFood(FoodItem food) {
    _onlineCache[food.id] = food;
  }

  static Future<FoodSearchResult> searchOnline(String query) async {
    try {
      final results = await OpenFoodFactsService.instance.searchFoods(query);
      for (final food in results) {
        rememberOnlineFood(food);
      }

      if (results.isEmpty) {
        return FoodSearchResult.notFound();
      }

      return FoodSearchResult.success(results);
    } on FoodSearchException catch (error) {
      return FoodSearchResult.unavailable(error.message);
    } catch (_) {
      return FoodSearchResult.unavailable(
        'לא הצלחנו להתחבר למאגר המזון באינטרנט. בדקי את חיבור האינטרנט ונסי שוב.',
      );
    }
  }

  static List<FoodItem> searchLocal(String query, {String? category}) {
    final normalizedQuery = query.trim().toLowerCase();

    return foods.where((food) {
      final matchesSearch = normalizedQuery.isEmpty ||
          food.name.toLowerCase().contains(normalizedQuery) ||
          food.category.toLowerCase().contains(normalizedQuery);
      final matchesCategory =
          category == null || category == 'הכל' || food.category == category;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  static List<FoodItem> searchCustomFoods(String query, {String? category}) {
    final normalizedQuery = query.trim().toLowerCase();

    return _customFoods.where((food) {
      final matchesSearch = normalizedQuery.isEmpty ||
          food.name.toLowerCase().contains(normalizedQuery) ||
          food.category.toLowerCase().contains(normalizedQuery);
      final matchesCategory =
          category == null || category == 'הכל' || food.category == category;
      return matchesSearch && matchesCategory;
    }).toList();
  }
}