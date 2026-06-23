enum FoodSource {
  local,
  openFoodFacts,
  custom,
}

class FoodItem {
  final int id;
  final String name;
  final String category;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final bool supportsUnits;
  final double gramsPerUnit;
  final FoodSource source;
  final String? externalId;

  const FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.supportsUnits = false,
    this.gramsPerUnit = 0,
    this.source = FoodSource.local,
    this.externalId,
  });

  bool get isOnline => source == FoodSource.openFoodFacts;

  bool get isCustom => source == FoodSource.custom;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'caloriesPer100g': caloriesPer100g,
      'proteinPer100g': proteinPer100g,
      'carbsPer100g': carbsPer100g,
      'fatPer100g': fatPer100g,
      'supportsUnits': supportsUnits,
      'gramsPerUnit': gramsPerUnit,
      'source': source.name,
      'externalId': externalId,
    };
  }

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] as int,
      name: map['name'] as String,
      category: map['category'] as String,
      caloriesPer100g: (map['caloriesPer100g'] as num).toDouble(),
      proteinPer100g: (map['proteinPer100g'] as num).toDouble(),
      carbsPer100g: (map['carbsPer100g'] as num).toDouble(),
      fatPer100g: (map['fatPer100g'] as num).toDouble(),
      supportsUnits: map['supportsUnits'] as bool? ?? false,
      gramsPerUnit: (map['gramsPerUnit'] as num?)?.toDouble() ?? 0,
      source: FoodSource.values.firstWhere(
        (value) => value.name == map['source'],
        orElse: () => FoodSource.local,
      ),
      externalId: map['externalId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || (other is FoodItem && other.id == id);
  }

  @override
  int get hashCode => id.hashCode;
}
