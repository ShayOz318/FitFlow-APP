import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/food_repository.dart';
import '../../../models/food_item.dart';
import '../../../models/food_search_result.dart';
import '../../../widgets/food_search_status_message.dart';

class FoodLibraryScreen extends StatefulWidget {
  const FoodLibraryScreen({super.key});

  @override
  State<FoodLibraryScreen> createState() => _FoodLibraryScreenState();
}

class _FoodLibraryScreenState extends State<FoodLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchText = '';
  List<FoodItem> onlineFoods = [];
  bool isSearchingOnline = false;
  FoodSearchStatus? onlineStatus;
  String? onlineErrorMessage;
  String? lastOnlineQuery;
  Timer? _debounce;

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
  }

  @override
  Widget build(BuildContext context) {
    final localFoods = FoodRepository.searchLocal(searchText);
    final showOnlineSection = searchText.trim().length >= 2;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('מאגר מזונות'),
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
                  'מאגר מקומי + Open Food Facts',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    const Text(
                      'מאגר מקומי',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (localFoods.isEmpty && searchText.trim().isNotEmpty)
                      FoodSearchStatusMessage(
                        status: FoodSearchStatus.notFound,
                        query: searchText.trim(),
                      )
                    else
                      ...localFoods.map(_buildFoodCard),
                    if (showOnlineSection) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'מהאינטרנט',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (isSearchingOnline)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 10),
                              Text(
                                'מחפש במאגר האינטרנט...',
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
                      else if (onlineFoods.isEmpty)
                        FoodSearchStatusMessage(
                          status: FoodSearchStatus.notFound,
                          query: searchText.trim(),
                        )
                      else
                        ...onlineFoods.map(_buildFoodCard),
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

  Widget _buildFoodCard(FoodItem food) {
    return Card(
      child: ListTile(
        leading: food.isOnline
            ? const Icon(Icons.cloud_outlined, color: Colors.blueGrey)
            : null,
        title: Text(food.name),
        subtitle: Text(
          '${food.category} | ${food.caloriesPer100g.toStringAsFixed(0)} קלוריות ל-100 גרם',
        ),
      ),
    );
  }
}
