class Exercise {
  final int id;
  final String name;
  final String category;
  final String muscleGroup;
  final String instructions;
  final bool hasVideo;
  final String videoUrl;

  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.muscleGroup,
    required this.instructions,
    this.hasVideo = false,
    this.videoUrl = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'muscleGroup': muscleGroup,
      'instructions': instructions,
      'hasVideo': hasVideo,
      'videoUrl': videoUrl,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as int,
      name: map['name'] as String,
      category: map['category'] as String,
      muscleGroup: map['muscleGroup'] as String,
      instructions: map['instructions'] as String,
      hasVideo: map['hasVideo'] as bool? ?? false,
      videoUrl: map['videoUrl'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || (other is Exercise && other.id == id);
  }

  @override
  int get hashCode => id.hashCode;
}