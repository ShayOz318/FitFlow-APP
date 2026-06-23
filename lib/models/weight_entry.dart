class WeightEntry {
  final String date;
  final double weight;

  const WeightEntry({
    required this.date,
    required this.weight,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'weight': weight,
    };
  }

  factory WeightEntry.fromMap(Map<String, dynamic> map) {
    return WeightEntry(
      date: map['date'] as String,
      weight: (map['weight'] as num).toDouble(),
    );
  }
}