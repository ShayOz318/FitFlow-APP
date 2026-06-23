import '../models/food_item.dart';

enum FoodSearchStatus {
  success,
  notFound,
  unavailable,
}

class FoodSearchResult {
  final FoodSearchStatus status;
  final List<FoodItem> items;
  final String? message;

  const FoodSearchResult({
    required this.status,
    this.items = const [],
    this.message,
  });

  factory FoodSearchResult.success(List<FoodItem> items) {
    if (items.isEmpty) {
      return const FoodSearchResult(status: FoodSearchStatus.notFound);
    }
    return FoodSearchResult(
      status: FoodSearchStatus.success,
      items: items,
    );
  }

  factory FoodSearchResult.notFound() {
    return const FoodSearchResult(status: FoodSearchStatus.notFound);
  }

  factory FoodSearchResult.unavailable(String message) {
    return FoodSearchResult(
      status: FoodSearchStatus.unavailable,
      message: message,
    );
  }

  bool get isUnavailable => status == FoodSearchStatus.unavailable;
  bool get isNotFound => status == FoodSearchStatus.notFound;
}
