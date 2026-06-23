class Trainee {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  const Trainee({
    required this.id,
    required this.name,
    this.email = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Trainee.fromMap(Map<String, dynamic> map) {
    return Trainee(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Trainee copyWith({String? name, String? email}) {
    return Trainee(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt,
    );
  }
}
