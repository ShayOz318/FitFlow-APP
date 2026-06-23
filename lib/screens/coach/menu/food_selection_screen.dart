import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/food_repository.dart';
import '../../../models/food_item.dart';
import '../../../models/food_search_result.dart';
import '../../../widgets/food_search_status_message.dart';
import 'add_custom_food_screen.dart';

class FoodSelectionScreen extends StatefulWidget {
  const FoodSelectionScreen({super.key});

  @override
  State<FoodSelectionScreen> createState() => _FoodSelectionScreenState();
}

class _FoodSelectionScreenState extends State<FoodSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchText = '';
  Set<String> selectedCategories = {'הכל'};

  List<FoodItem> onlineFoods = [];
  bool isSearchingOnline = false;
  FoodSearchStatus? onlineStatus;
  String? onlineErrorMessage;
  String? lastOnlineQuery;
  Timer? _debounce;
  bool customFoodsLoaded = false;

  final List<String> categories = [
    'הכל',
    'חלבון',
    'פחמימה',
    'שומן',
    'פרי',
    'ירק',
    'מוצרי חלב',
    'אחר',
    'מהאינטרנט',
  ];

  @override
  void initState() {
    super.initState();
    _loadCustomFoods();
  }

  Future<void> _loadCustomFoods() async {
    await FoodRepository.ensureCustomFoodsLoaded();
    if (!mounted) {
      return;
    }
    setState(() {
      customFoodsLoaded = true;
    });
  }

  Future<void> _openAddCustomFood() async {
    final food = await Navigator.push<FoodItem>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddCustomFoodScreen(),
      ),
    );

    if (food == null) {
      return;
    }

    await _loadCustomFoods();

    if (!mounted) {
      return;
    }

    Navigator.pop(context, food);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String _normalizeSearchInput(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  void _onSearchChanged(String value) {
    final normalized = _normalizeSearchInput(value);
    setState(() {
      searchText = normalized;
      onlineStatus = null;
      onlineErrorMessage = null;
    });

    _debounce?.cancel();
    if (normalized.length < 2) {
      setState(() {
        onlineFoods = [];
        isSearchingOnline = false;
        onlineStatus = null;
        onlineErrorMessage = null;
        lastOnlineQuery = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 600), () {
      _searchOnline(normalized);
    });
  }

  void _submitSearch() {
    _debounce?.cancel();
    final normalized = _normalizeSearchInput(_searchController.text);
    setState(() {
      searchText = normalized;
    });
    if (normalized.length < 2) {
      return;
    }
    _searchOnline(normalized);
  }

  Future<void> _searchOnline(String query) async {
    setState(() {
      isSearchingOnline = true;
      onlineStatus = null;
      onlineErrorMessage = null;
      lastOnlineQuery = query;
    });

    try {
      final result = await FoodRepository.searchOnline(query);
      if (!mounted || _normalizeSearchInput(searchText) != query) {
        return;
      }

      setState(() {
        onlineFoods = result.items;
        onlineStatus = result.status;
        onlineErrorMessage = result.message;
        isSearchingOnline = false;
      });
    } catch (_) {
      if (!mounted || searchText.trim() != query) {
        return;
      }

      setState(() {
        onlineFoods = [];
        onlineStatus = FoodSearchStatus.unavailable;
        onlineErrorMessage =
            'לא הצלחנו להתחבר למאגר המזון באינטרנט. בדקי את חיבור האינטרנט ונסי שוב.';
        isSearchingOnline = false;
      });
    }
  }

  List<FoodItem> get localFoods {
    final category = selectedCategories.contains('הכל')
        ? null
        : selectedCategories.first;

    return FoodRepository.searchLocal(
      searchText,
      category: category,
    );
  }

  List<FoodItem> get customFoods {
    final category = selectedCategories.contains('הכל')
        ? null
        : selectedCategories.first;

    return FoodRepository.searchCustomFoods(
      searchText,
      category: category,
    );
  }

  List<FoodItem> get filteredOnlineFoods {
    if (selectedCategories.contains('הכל')) {
      return onlineFoods;
    }

    return onlineFoods.where((food) {
      return selectedCategories.contains(food.category);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final showOnlineSection = searchText.trim().length >= 2;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('בחירת מזון'),
          actions: [
            TextButton.icon(
              onPressed: _openAddCustomFood,
              icon: const Icon(Icons.add),
              label: const Text('הוסף ידנית'),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'חיפוש מזון (עברית או אנגלית)...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: _onSearchChanged,
                onSubmitted: (_) => _submitSearch(),
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'מאגר מקומי + מזונות ידניים + Open Food Facts',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategories.contains(category);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (category == 'הכל') {
                              selectedCategories = {'הכל'};
                            } else {
                              selectedCategories.remove('הכל');

                              if (selected) {
                                selectedCategories.add(category);
                              } else {
                                selectedCategories.remove(category);
                              }

                              if (selectedCategories.isEmpty) {
                                selectedCategories.add('הכל');
                              }
                            }
                          });
                        },
                        selectedColor: Colors.pink.shade200,
                        backgroundColor: Colors.grey.shade200,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _buildSectionTitle('מאגר מקומי'),
                    if (localFoods.isEmpty && searchText.trim().isNotEmpty)
                      FoodSearchStatusMessage(
                        status: FoodSearchStatus.notFound,
                        query: searchText.trim(),
                      )
                    else if (localFoods.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('אין מזונות במאגר המקומי'),
                      )
                    else
                      ...localFoods.map(_buildFoodTile),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildSectionTitle('מזונות שהוספתי')),
                        TextButton.icon(
                          onPressed: _openAddCustomFood,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('הוסף'),
                        ),
                      ],
                    ),
                    if (!customFoodsLoaded)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (customFoods.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'עדיין לא הוספת מזונות ידניים',
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    else
                      ...customFoods.map(_buildFoodTile),
                    if (showOnlineSection) ...[
                      const SizedBox(height: 20),
                      _buildSectionTitle('מהאינטרנט'),
                      if (isSearchingOnline)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 10),
                              Text(
                                'מחפש במאגר האינטרנט... זה יכול לקחת עד 30 שניות',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        )
                      else if (onlineStatus == FoodSearchStatus.unavailable)
                        FoodSearchStatusMessage(
                          status: FoodSearchStatus.unavailable,
                          query: searchText.trim(),
                          customMessage: onlineErrorMessage,
                          onRetry: lastOnlineQuery == null
                              ? null
                              : () => _searchOnline(lastOnlineQuery!),
                        )
                      else if (filteredOnlineFoods.isEmpty)
                        FoodSearchStatusMessage(
                          status: FoodSearchStatus.notFound,
                          query: searchText.trim(),
                          customMessage: onlineFoods.isNotEmpty &&
                                  !selectedCategories.contains('הכל')
                              ? 'נמצאו תוצאות באינטרנט, אבל לא בקטגוריה שבחרת.\nנסי לבחור "הכל".'
                              : null,
                        )
                      else
                        ...filteredOnlineFoods.map(_buildFoodTile),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildFoodTile(FoodItem food) {
    return Card(
      child: ListTile(
        title: Text(food.name),
        subtitle: Text(
          '${food.caloriesPer100g.toStringAsFixed(0)} קלוריות | '
          '${food.proteinPer100g.toStringAsFixed(1)} חלבון | '
          '${food.carbsPer100g.toStringAsFixed(1)} פחמימה | '
          '${food.fatPer100g.toStringAsFixed(1)} שומן',
        ),
        trailing: food.isOnline
            ? const Icon(Icons.cloud_outlined, color: Colors.blueGrey)
            : food.isCustom
                ? const Icon(Icons.edit_note, color: Color(0xFFFF6F61))
                : const Icon(Icons.arrow_back_ios_new),
        onTap: () {
          Navigator.pop(context, food);
        },
      ),
    );
  }
}
