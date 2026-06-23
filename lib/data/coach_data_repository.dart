import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/meal.dart';
import '../models/menu_type.dart';
import '../models/trainee_profile_data.dart';
import '../models/weight_entry.dart';
import '../models/workout.dart';
import '../services/firestore_service.dart';
import 'trainee_repository.dart';

class CoachDataRepository {
  CoachDataRepository._();

  static final CoachDataRepository instance = CoachDataRepository._();

  final TraineeRepository _traineeRepository = TraineeRepository.instance;
  final FirestoreService _firestore = FirestoreService.instance;

  Future<TraineeProfileData> getProfile(String traineeId) async {
    final localProfile = await _loadProfileFromLocal(traineeId);
    final cloudProfile = await _loadProfileFromFirestore(traineeId);

    if (cloudProfile == null) {
      return localProfile;
    }

    final merged = _mergeProfiles(localProfile, cloudProfile);
    await _cacheProfile(traineeId, merged);
    return merged;
  }

  Future<TraineeProfileData> getProfileLocal(String traineeId) async {
    return _loadProfileFromLocal(traineeId);
  }

  TraineeProfileData _mergeProfiles(
    TraineeProfileData local,
    TraineeProfileData cloud,
  ) {
    return TraineeProfileData(
      name: cloud.name.isNotEmpty ? cloud.name : local.name,
      age: cloud.age ?? local.age,
      height: cloud.height ?? local.height,
      goal: cloud.goal.isNotEmpty ? cloud.goal : local.goal,
      currentWeight: cloud.currentWeight ?? local.currentWeight,
      targetWeight: cloud.targetWeight ?? local.targetWeight,
      startingWeight: cloud.startingWeight ?? local.startingWeight,
      weightHistory: cloud.weightHistory.isNotEmpty
          ? cloud.weightHistory
          : local.weightHistory,
    );
  }

  Future<void> saveProfile(String traineeId, TraineeProfileData profile) async {
    await _cacheProfile(traineeId, profile);
    await _updateFirestore(traineeId, profile.toFirestoreFields());
  }

  Future<void> setStartingWeight(String traineeId, double weight) async {
    final profile = await getProfile(traineeId);
    final updated = profile.copyWith(startingWeight: weight);
    await saveProfile(traineeId, updated);
  }

  Future<List<Meal>> getMeals(String traineeId, MenuType menuType) async {
    final field = _mealsField(menuType);
    final cloudMeals = await _loadMealsFromFirestore(traineeId, field);
    if (cloudMeals != null) {
      await _cacheMeals(traineeId, menuType, cloudMeals);
      return cloudMeals;
    }

    return _loadMealsFromLocal(traineeId, menuType);
  }

  Future<void> saveMeals(
    String traineeId,
    MenuType menuType,
    List<Meal> meals,
  ) async {
    await _cacheMeals(traineeId, menuType, meals);
    await _updateFirestore(traineeId, {
      _mealsField(menuType): meals.map((meal) => meal.toMap()).toList(),
    });
  }

  Future<List<Workout>> getWorkouts(String traineeId) async {
    final cloudWorkouts = await _loadWorkoutsFromFirestore(traineeId);
    if (cloudWorkouts != null) {
      await _cacheWorkouts(traineeId, cloudWorkouts);
      return cloudWorkouts;
    }

    return _loadWorkoutsFromLocal(traineeId);
  }

  Future<void> saveWorkouts(String traineeId, List<Workout> workouts) async {
    await _cacheWorkouts(traineeId, workouts);
    await _updateFirestore(traineeId, {
      'savedWorkouts': workouts.map((workout) => workout.toMap()).toList(),
    });
  }

  Future<Map<String, String>> getExerciseNotes(String traineeId) async {
    final cloudNotes = await _loadExerciseNotesFromFirestore(traineeId);
    if (cloudNotes != null) {
      await _cacheExerciseNotes(traineeId, cloudNotes);
      return cloudNotes;
    }

    return _loadExerciseNotesFromLocal(traineeId);
  }

  Future<void> saveExerciseNotes(
    String traineeId,
    Map<String, String> notes,
  ) async {
    await _cacheExerciseNotes(traineeId, notes);
    await _updateFirestore(traineeId, {'exerciseNotes': notes});
  }

  Future<Map<String, dynamic>> buildTraineeDocumentFromLocal(
    String traineeId,
  ) async {
    final profile = await _loadProfileFromLocal(traineeId);
    final weekdayMeals = await _loadMealsFromLocal(traineeId, MenuType.weekday);
    final weekendMeals = await _loadMealsFromLocal(traineeId, MenuType.weekend);
    final workouts = await _loadWorkoutsFromLocal(traineeId);
    final exerciseNotes = await _loadExerciseNotesFromLocal(traineeId);

    return {
      'id': traineeId,
      ...profile.toFirestoreFields(),
      'weekdayMeals': weekdayMeals.map((meal) => meal.toMap()).toList(),
      'weekendMeals': weekendMeals.map((meal) => meal.toMap()).toList(),
      'savedWorkouts': workouts.map((workout) => workout.toMap()).toList(),
      'exerciseNotes': exerciseNotes,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  String _mealsField(MenuType menuType) {
    return menuType == MenuType.weekday ? 'weekdayMeals' : 'weekendMeals';
  }

  Future<void> _updateFirestore(
    String traineeId,
    Map<String, dynamic> fields,
  ) async {
    final doc = _firestore.traineeDoc(traineeId);
    if (doc == null) {
      return;
    }

    try {
      await doc.set(
        {
          'id': traineeId,
          ...fields,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  Future<TraineeProfileData?> _loadProfileFromFirestore(String traineeId) async {
    final data = await _readTraineeDoc(traineeId);
    if (data == null) {
      return null;
    }

    return TraineeProfileData.fromFirestore(data);
  }

  Future<List<Meal>?> _loadMealsFromFirestore(
    String traineeId,
    String field,
  ) async {
    final data = await _readTraineeDoc(traineeId);
    if (data == null || data[field] == null) {
      return null;
    }

    return _parseMeals(data[field]);
  }

  Future<List<Workout>?> _loadWorkoutsFromFirestore(String traineeId) async {
    final data = await _readTraineeDoc(traineeId);
    if (data == null || data['savedWorkouts'] == null) {
      return null;
    }

    return _parseWorkouts(data['savedWorkouts']);
  }

  Future<Map<String, String>?> _loadExerciseNotesFromFirestore(
    String traineeId,
  ) async {
    final data = await _readTraineeDoc(traineeId);
    if (data == null || data['exerciseNotes'] == null) {
      return null;
    }

    final raw = data['exerciseNotes'] as Map<String, dynamic>;
    return raw.map((key, value) => MapEntry(key, value.toString()));
  }

  Future<Map<String, dynamic>?> _readTraineeDoc(String traineeId) async {
    final doc = _firestore.traineeDoc(traineeId);
    if (doc == null) {
      return null;
    }

    try {
      final snapshot = await doc.get();
      if (!snapshot.exists) {
        return null;
      }
      return snapshot.data();
    } catch (_) {
      return null;
    }
  }

  Future<TraineeProfileData> _loadProfileFromLocal(String traineeId) async {
    final prefs = await SharedPreferences.getInstance();

    final historyJson = prefs.getString(_traineeRepository.weightHistoryKey(traineeId));
    List<WeightEntry> history = [];

    if (historyJson != null && historyJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(historyJson) as List<dynamic>;
        history = decoded
            .map((item) => WeightEntry.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      } catch (_) {}
    }

    return TraineeProfileData(
      name: prefs.getString(_traineeRepository.nameKey(traineeId)) ?? '',
      age: prefs.getInt(_traineeRepository.ageKey(traineeId)),
      height: prefs.getDouble(_traineeRepository.heightKey(traineeId)),
      goal: prefs.getString(_traineeRepository.goalKey(traineeId)) ?? '',
      currentWeight:
          prefs.getDouble(_traineeRepository.currentWeightKey(traineeId)),
      targetWeight:
          prefs.getDouble(_traineeRepository.targetWeightKey(traineeId)),
      startingWeight:
          prefs.getDouble(_traineeRepository.startingWeightKey(traineeId)),
      weightHistory: history,
    );
  }

  Future<void> _cacheProfile(String traineeId, TraineeProfileData profile) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _traineeRepository.nameKey(traineeId),
      profile.name,
    );
    await prefs.setString(
      _traineeRepository.goalKey(traineeId),
      profile.goal,
    );

    if (profile.age != null) {
      await prefs.setInt(_traineeRepository.ageKey(traineeId), profile.age!);
    } else {
      await prefs.remove(_traineeRepository.ageKey(traineeId));
    }

    if (profile.height != null) {
      await prefs.setDouble(
        _traineeRepository.heightKey(traineeId),
        profile.height!,
      );
    } else {
      await prefs.remove(_traineeRepository.heightKey(traineeId));
    }

    if (profile.currentWeight != null) {
      await prefs.setDouble(
        _traineeRepository.currentWeightKey(traineeId),
        profile.currentWeight!,
      );
    } else {
      await prefs.remove(_traineeRepository.currentWeightKey(traineeId));
    }

    if (profile.targetWeight != null) {
      await prefs.setDouble(
        _traineeRepository.targetWeightKey(traineeId),
        profile.targetWeight!,
      );
    } else {
      await prefs.remove(_traineeRepository.targetWeightKey(traineeId));
    }

    if (profile.startingWeight != null) {
      await prefs.setDouble(
        _traineeRepository.startingWeightKey(traineeId),
        profile.startingWeight!,
      );
    } else {
      await prefs.remove(_traineeRepository.startingWeightKey(traineeId));
    }

    await prefs.setString(
      _traineeRepository.weightHistoryKey(traineeId),
      jsonEncode(profile.weightHistory.map((entry) => entry.toMap()).toList()),
    );
  }

  Future<List<Meal>> _loadMealsFromLocal(
    String traineeId,
    MenuType menuType,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = menuType == MenuType.weekday
        ? _traineeRepository.weekdayMealsKey(traineeId)
        : _traineeRepository.weekendMealsKey(traineeId);
    final savedMeals = prefs.getString(key);

    if (savedMeals == null || savedMeals.isEmpty) {
      return [];
    }

    try {
      return _parseMeals(jsonDecode(savedMeals));
    } catch (_) {
      return [];
    }
  }

  Future<void> _cacheMeals(
    String traineeId,
    MenuType menuType,
    List<Meal> meals,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = menuType == MenuType.weekday
        ? _traineeRepository.weekdayMealsKey(traineeId)
        : _traineeRepository.weekendMealsKey(traineeId);

    await prefs.setString(
      key,
      jsonEncode(meals.map((meal) => meal.toMap()).toList()),
    );
  }

  Future<List<Workout>> _loadWorkoutsFromLocal(String traineeId) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_traineeRepository.savedWorkoutsKey(traineeId));

    if (saved == null || saved.isEmpty) {
      return [];
    }

    try {
      return _parseWorkouts(jsonDecode(saved));
    } catch (_) {
      return [];
    }
  }

  Future<void> _cacheWorkouts(String traineeId, List<Workout> workouts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _traineeRepository.savedWorkoutsKey(traineeId),
      jsonEncode(workouts.map((workout) => workout.toMap()).toList()),
    );
  }

  Future<Map<String, String>> _loadExerciseNotesFromLocal(
    String traineeId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final savedNotes =
        prefs.getString(_traineeRepository.exerciseNotesKey(traineeId));

    if (savedNotes == null || savedNotes.isEmpty) {
      return {};
    }

    try {
      final decodedNotes = jsonDecode(savedNotes) as Map<String, dynamic>;
      return decodedNotes.map(
        (key, value) => MapEntry(key, value.toString()),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _cacheExerciseNotes(
    String traineeId,
    Map<String, String> notes,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _traineeRepository.exerciseNotesKey(traineeId),
      jsonEncode(notes),
    );
  }

  List<Meal> _parseMeals(dynamic raw) {
    final list = raw as List<dynamic>;
    return list
        .map((meal) => Meal.fromMap(Map<String, dynamic>.from(meal)))
        .toList();
  }

  List<Workout> _parseWorkouts(dynamic raw) {
    final list = raw as List<dynamic>;
    return list
        .map((item) => Workout.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }
}
