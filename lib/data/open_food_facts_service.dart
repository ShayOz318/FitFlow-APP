import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../models/food_item.dart';

class OpenFoodFactsService {
  OpenFoodFactsService._();

  static final OpenFoodFactsService instance = OpenFoodFactsService._();

  static const String _searchApiUrl = 'https://search.openfoodfacts.org/search';
  static const String _legacyApiUrl =
      'https://world.openfoodfacts.org/cgi/search.pl';
  static const String _webProxyUrl =
      'https://us-central1-fitflow-cd332.cloudfunctions.net/foodSearch';
  static const String _searchFields =
      'code,product_name,product_name_he,nutriments,categories_tags,brands';
  static const Duration _requestTimeout = Duration(seconds: 30);

  Future<List<FoodItem>> searchFoods(String query) async {
    final normalized = _normalizeQuery(query);
    if (normalized.length < 2) {
      return [];
    }

    try {
      var foods = await _fetchFoods(normalized);
      foods = _rankByQuery(foods, normalized);

      if (foods.isEmpty && normalized.contains(' ')) {
        final firstWord = normalized.split(' ').first;
        if (firstWord.length >= 2) {
          foods = await _fetchFoods(firstWord);
          foods = _rankByQuery(foods, normalized);
        }
      }

      return foods;
    } on FoodSearchException {
      rethrow;
    } catch (_) {
      throw FoodSearchException(
        'לא הצלחנו לחפש מזון. בדקי חיבור לאינטרנט ונסי שוב.',
      );
    }
  }

  String _normalizeQuery(String query) {
    return query.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<List<FoodItem>> _fetchFoods(String query) async {
    FoodSearchException? lastError;

    for (final builder in _searchUriBuilders(query)) {
      try {
        final body = await _fetchJsonBody(builder());
        return _parseSearchResponse(body);
      } on FoodSearchException catch (error) {
        lastError = error;
      }
    }

    if (lastError != null) {
      throw lastError;
    }

    return [];
  }

  List<Uri Function()> _searchUriBuilders(String query) {
    final pageSize = query.contains(' ') ? 40 : 25;

    Uri buildSearchALicious(Uri base) {
      return base.replace(
        queryParameters: {
          'q': query,
          'page_size': '$pageSize',
          'fields': _searchFields,
        },
      );
    }

    Uri buildLegacy(Uri base) {
      return base.replace(
        queryParameters: {
          'search_terms': query,
          'search_simple': '1',
          'action': 'process',
          'json': '1',
          'page_size': '$pageSize',
          'fields': _searchFields,
        },
      );
    }

    if (kIsWeb) {
      return [
        () => buildSearchALicious(Uri.parse(_webProxyUrl)),
        () => buildSearchALicious(Uri.parse(_searchApiUrl)),
        () => buildLegacy(Uri.parse(_legacyApiUrl)),
      ];
    }

    return [
      () => buildSearchALicious(Uri.parse(_searchApiUrl)),
      () => buildLegacy(Uri.parse(_legacyApiUrl)),
    ];
  }

  List<FoodItem> _parseSearchResponse(String body) {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final rawItems = decoded['hits'] as List<dynamic>? ??
        decoded['products'] as List<dynamic>? ??
        [];

    final foods = <FoodItem>[];
    for (final item in rawItems) {
      final food = _mapProduct(Map<String, dynamic>.from(item as Map));
      if (food != null) {
        foods.add(food);
      }
    }

    return foods;
  }

  List<FoodItem> _rankByQuery(List<FoodItem> foods, String query) {
    final terms = query
        .toLowerCase()
        .split(' ')
        .where((term) => term.isNotEmpty)
        .toList();

    if (terms.isEmpty || foods.isEmpty) {
      return foods;
    }

    int scoreFor(FoodItem food) {
      final name = food.name.toLowerCase();
      var score = 0;
      for (final term in terms) {
        if (name.contains(term)) {
          score++;
        }
      }
      return score;
    }

    final ranked = [...foods]..sort((a, b) => scoreFor(b).compareTo(scoreFor(a)));

    final withMatches = ranked.where((food) => scoreFor(food) > 0).toList();
    return withMatches.isNotEmpty ? withMatches : ranked;
  }

  Future<String> _fetchJsonBody(Uri uri) async {
    if (kIsWeb && uri.host != _webProxyHost) {
      return _fetchViaWebProxies(uri);
    }

    final response = await http
        .get(
          uri,
          headers: const {
            'User-Agent': 'FitFlow/1.0 (Flutter fitness coach app)',
            'Accept': 'application/json',
          },
        )
        .timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw FoodSearchException('שגיאה בחיפוש מזון (${response.statusCode})');
    }

    return _validateJsonBody(response.body);
  }

  String get _webProxyHost => Uri.parse(_webProxyUrl).host;

  Future<String> _fetchViaWebProxies(Uri uri) async {
    final errors = <String>[];

    for (final proxy in _webProxyBuilders) {
      try {
        final proxyUri = proxy(uri);
        final response = await http.get(proxyUri).timeout(_requestTimeout);

        if (response.statusCode != 200) {
          errors.add('${proxyUri.host}: ${response.statusCode}');
          continue;
        }

        return _validateJsonBody(response.body);
      } catch (error) {
        errors.add('${proxy(uri).host}: $error');
      }
    }

    throw FoodSearchException(
      'חיפוש מהאינטרנט לא זמין כרגע. נסי שוב בעוד רגע, או חפשי באנגלית.',
    );
  }

  String _validateJsonBody(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty || trimmed.startsWith('<')) {
      throw FoodSearchException(
        'מאגר המזון באינטרנט לא זמין כרגע. נסי שוב בעוד כמה דקות.',
      );
    }

    try {
      jsonDecode(trimmed);
    } catch (_) {
      throw FoodSearchException('תשובה לא תקינה ממאגר המזון באינטרנט.');
    }

    return trimmed;
  }

  List<Uri Function(Uri target)> get _webProxyBuilders {
    return [
      (target) => Uri.parse('https://api.allorigins.win/raw').replace(
            queryParameters: {'url': target.toString()},
          ),
      (target) => Uri.parse(
            'https://corsproxy.io/?${Uri.encodeComponent(target.toString())}',
          ),
    ];
  }

  FoodItem? _mapProduct(Map<String, dynamic> product) {
    final code = product['code']?.toString();
    if (code == null || code.isEmpty) {
      return null;
    }

    final name = _productName(product);
    if (name.isEmpty) {
      return null;
    }

    final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};
    final calories = _readCalories(nutriments) ?? 0;
    final protein =
        _readNutrient(nutriments, ['proteins_100g', 'proteins']) ?? 0;
    final carbs = _readNutrient(nutriments, [
          'carbohydrates_100g',
          'carbohydrates',
        ]) ??
        0;
    final fat = _readNutrient(nutriments, ['fat_100g', 'fat']) ?? 0;

    final brand = product['brands']?.toString().trim();
    final displayName =
        brand != null && brand.isNotEmpty ? '$name ($brand)' : name;

    return FoodItem(
      id: _apiIdForCode(code),
      name: displayName,
      category: _mapCategory(product['categories_tags']),
      caloriesPer100g: calories,
      proteinPer100g: protein,
      carbsPer100g: carbs,
      fatPer100g: fat,
      source: FoodSource.openFoodFacts,
      externalId: code,
    );
  }

  String _productName(Map<String, dynamic> product) {
    final hebrewName = product['product_name_he']?.toString().trim();
    if (hebrewName != null && hebrewName.isNotEmpty) {
      return hebrewName;
    }

    return product['product_name']?.toString().trim() ?? '';
  }

  double? _readCalories(Map<String, dynamic> nutriments) {
    final kcal = _readNutrient(nutriments, [
      'energy-kcal_100g',
      'energy-kcal',
      'energy-kcal_value',
    ]);
    if (kcal != null) {
      return kcal;
    }

    final kj = _readNutrient(nutriments, [
      'energy-kj_100g',
      'energy-kj',
      'energy-kj_value',
      'energy_100g',
      'energy',
    ]);
    if (kj != null) {
      return kj / 4.184;
    }

    return null;
  }

  double? _readNutrient(
    Map<String, dynamic> nutriments,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = nutriments[key];
      if (value is num) {
        return value.toDouble();
      }
    }
    return null;
  }

  String _mapCategory(dynamic rawTags) {
    if (rawTags is! List) {
      return 'מהאינטרנט';
    }

    final tags = rawTags.map((tag) => tag.toString().toLowerCase()).toList();

    if (tags.any((tag) => tag.contains('meat') || tag.contains('fish'))) {
      return 'חלבון';
    }
    if (tags.any((tag) => tag.contains('dairy') || tag.contains('milk'))) {
      return 'מוצרי חלב';
    }
    if (tags.any((tag) => tag.contains('fruit'))) {
      return 'פרי';
    }
    if (tags.any((tag) => tag.contains('vegetable'))) {
      return 'ירק';
    }
    if (tags.any((tag) =>
        tag.contains('bread') ||
        tag.contains('cereal') ||
        tag.contains('pasta') ||
        tag.contains('rice'))) {
      return 'פחמימה';
    }
    if (tags.any((tag) => tag.contains('oil') || tag.contains('nut'))) {
      return 'שומן';
    }

    return 'מהאינטרנט';
  }

  int _apiIdForCode(String code) {
    return 100000 + code.hashCode.abs() % 900000;
  }
}

class FoodSearchException implements Exception {
  final String message;

  FoodSearchException(this.message);

  @override
  String toString() => message;
}
