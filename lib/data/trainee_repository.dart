import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/trainee.dart';
import '../services/firestore_service.dart';
import '../services/trainee_invite_service.dart';

class TraineeRepository {
  TraineeRepository._();

  static final TraineeRepository instance = TraineeRepository._();

  final FirestoreService _firestore = FirestoreService.instance;
  final TraineeInviteService _inviteService = TraineeInviteService.instance;

  static const String traineesListKey = 'trainees_list';
  static const String activeTraineeIdKey = 'active_trainee_id';
  static const String migrationDoneKey = 'trainees_migration_v1';

  static const String legacyTraineeName = 'trainee_name';
  static const String legacyTraineeAge = 'trainee_age';
  static const String legacyTraineeHeight = 'trainee_height';
  static const String legacyTraineeGoal = 'trainee_goal';
  static const String legacyCurrentWeight = 'current_weight';
  static const String legacyTargetWeight = 'target_weight';
  static const String legacyStartingWeight = 'starting_weight';
  static const String legacyWeightHistory = 'weight_history';
  static const String legacyWeekdayMeals = 'weekday_meals';
  static const String legacyWeekendMeals = 'weekend_meals';
  static const String legacySavedWorkouts = 'saved_workouts';
  static const String legacyExerciseNotes = 'trainee_exercise_notes';

  String _key(String traineeId, String suffix) => 'trainee_${traineeId}_$suffix';

  String nameKey(String id) => _key(id, 'name');
  String ageKey(String id) => _key(id, 'age');
  String heightKey(String id) => _key(id, 'height');
  String goalKey(String id) => _key(id, 'goal');
  String currentWeightKey(String id) => _key(id, 'current_weight');
  String targetWeightKey(String id) => _key(id, 'target_weight');
  String startingWeightKey(String id) => _key(id, 'starting_weight');
  String weightHistoryKey(String id) => _key(id, 'weight_history');
  String weekdayMealsKey(String id) => _key(id, 'weekday_meals');
  String weekendMealsKey(String id) => _key(id, 'weekend_meals');
  String savedWorkoutsKey(String id) => _key(id, 'saved_workouts');
  String exerciseNotesKey(String id) => _key(id, 'exercise_notes');

  Future<void> ensureMigrated() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(migrationDoneKey) == true) {
      return;
    }

    final hasLegacyData = prefs.containsKey(legacyTraineeName) ||
        prefs.containsKey(legacyWeekdayMeals) ||
        prefs.containsKey(legacyWeekendMeals) ||
        prefs.containsKey(legacySavedWorkouts) ||
        prefs.containsKey(legacyWeightHistory);

    if (hasLegacyData) {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final name = prefs.getString(legacyTraineeName)?.trim();
      final trainee = Trainee(
        id: id,
        name: (name != null && name.isNotEmpty) ? name : 'מתאמן 1',
        createdAt: DateTime.now(),
      );

      await _copyLegacyToTrainee(prefs, id);
      await _saveTrainees(prefs, [trainee]);
      await prefs.setString(activeTraineeIdKey, id);
    }

    await prefs.setBool(migrationDoneKey, true);
  }

  Future<void> _copyLegacyToTrainee(
    SharedPreferences prefs,
    String traineeId,
  ) async {
    await _copyString(prefs, legacyTraineeName, nameKey(traineeId));
    await _copyInt(prefs, legacyTraineeAge, ageKey(traineeId));
    await _copyDouble(prefs, legacyTraineeHeight, heightKey(traineeId));
    await _copyString(prefs, legacyTraineeGoal, goalKey(traineeId));
    await _copyDouble(prefs, legacyCurrentWeight, currentWeightKey(traineeId));
    await _copyDouble(prefs, legacyTargetWeight, targetWeightKey(traineeId));
    await _copyDouble(prefs, legacyStartingWeight, startingWeightKey(traineeId));
    await _copyString(prefs, legacyWeightHistory, weightHistoryKey(traineeId));
    await _copyString(prefs, legacyWeekdayMeals, weekdayMealsKey(traineeId));
    await _copyString(prefs, legacyWeekendMeals, weekendMealsKey(traineeId));
    await _copyString(prefs, legacySavedWorkouts, savedWorkoutsKey(traineeId));
    await _copyString(prefs, legacyExerciseNotes, exerciseNotesKey(traineeId));
  }

  Future<void> _copyString(
    SharedPreferences prefs,
    String from,
    String to,
  ) async {
    if (prefs.containsKey(from)) {
      await prefs.setString(to, prefs.getString(from)!);
    }
  }

  Future<void> _copyInt(
    SharedPreferences prefs,
    String from,
    String to,
  ) async {
    if (prefs.containsKey(from)) {
      await prefs.setInt(to, prefs.getInt(from)!);
    }
  }

  Future<void> _copyDouble(
    SharedPreferences prefs,
    String from,
    String to,
  ) async {
    if (prefs.containsKey(from)) {
      await prefs.setDouble(to, prefs.getDouble(from)!);
    }
  }

  Future<List<Trainee>> getTrainees() async {
    await ensureMigrated();

    final localTrainees = await getTraineesLocal();
    final cloudTrainees = await _loadTraineesFromFirestore();

    if (cloudTrainees.isEmpty) {
      return localTrainees;
    }

    final merged = _mergeTraineeLists(localTrainees, cloudTrainees);
    final prefs = await SharedPreferences.getInstance();
    await _saveTrainees(prefs, merged);
    return merged;
  }

  List<Trainee> _mergeTraineeLists(
    List<Trainee> localTrainees,
    List<Trainee> cloudTrainees,
  ) {
    final localById = {for (final trainee in localTrainees) trainee.id: trainee};
    final merged = <Trainee>[];

    for (final cloudTrainee in cloudTrainees) {
      final localTrainee = localById[cloudTrainee.id];
      if (localTrainee == null) {
        merged.add(cloudTrainee);
        continue;
      }

      merged.add(
        Trainee(
          id: cloudTrainee.id,
          name: cloudTrainee.name.isNotEmpty
              ? cloudTrainee.name
              : localTrainee.name,
          email: cloudTrainee.email.isNotEmpty
              ? cloudTrainee.email
              : localTrainee.email,
          createdAt: cloudTrainee.createdAt,
        ),
      );
    }

    final cloudIds = cloudTrainees.map((trainee) => trainee.id).toSet();
    for (final localTrainee in localTrainees) {
      if (!cloudIds.contains(localTrainee.id)) {
        merged.add(localTrainee);
      }
    }

    return merged;
  }

  Future<List<Trainee>> getTraineesLocal() async {
    await ensureMigrated();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(traineesListKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => Trainee.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Trainee>> _loadTraineesFromFirestore() async {
    final collection = _firestore.traineesCollection();
    if (collection == null) {
      return [];
    }

    try {
      final snapshot = await collection.get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Trainee(
          id: data['id'] as String? ?? doc.id,
          name: data['name'] as String? ?? 'מתאמן',
          email: data['email'] as String? ?? '',
          createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ??
              DateTime.now(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> getActiveTraineeId() async {
    await ensureMigrated();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(activeTraineeIdKey);
  }

  Future<Trainee?> getActiveTrainee() async {
    final trainees = await getTrainees();
    if (trainees.isEmpty) {
      return null;
    }

    final activeId = await getActiveTraineeId();
    if (activeId == null) {
      return trainees.first;
    }

    return trainees.cast<Trainee?>().firstWhere(
          (trainee) => trainee!.id == activeId,
          orElse: () => trainees.first,
        );
  }

  Future<void> setActiveTrainee(String traineeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(activeTraineeIdKey, traineeId);
    await _syncActiveTraineeToFirestore(traineeId);
  }

  Future<void> _syncActiveTraineeToFirestore(String traineeId) async {
    final coachDoc = _firestore.coachDoc();
    if (coachDoc == null) {
      return;
    }

    try {
      await coachDoc.set(
        {'activeTraineeId': traineeId},
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  Future<Trainee> addTrainee({required String name}) async {
    await ensureMigrated();

    final prefs = await SharedPreferences.getInstance();
    final trainees = await getTrainees();

    final trainee = Trainee(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      createdAt: DateTime.now(),
    );

    await prefs.setString(nameKey(trainee.id), trainee.name);
    trainees.add(trainee);
    await _saveTrainees(prefs, trainees);
    await setActiveTrainee(trainee.id);
    await _syncTraineeToFirestore(trainee);
    return trainee;
  }

  Future<void> saveTraineeAccessEmail({
    required String traineeId,
    required String email,
    required String name,
  }) async {
    final normalizedEmail = _inviteService.normalizeEmail(email);

    if (!_inviteService.isValidEmail(normalizedEmail)) {
      throw TraineeInviteException('יש להזין כתובת אימייל תקינה למתאמן');
    }

    if (!await _inviteService.isEmailAvailableForTrainee(
      normalizedEmail,
      traineeId,
    )) {
      throw TraineeInviteException('האימייל הזה כבר רשום למתאמן אחר');
    }

    final coachId = _firestore.coachId;
    if (coachId == null) {
      throw TraineeInviteException('יש להתחבר כמאמן לפני שמירת פרופיל');
    }

    final prefs = await SharedPreferences.getInstance();
    final trainees = await getTrainees();
    final index = trainees.indexWhere((trainee) => trainee.id == traineeId);
    if (index == -1) {
      throw TraineeInviteException('מתאמן לא נמצא');
    }

    final currentTrainee = trainees[index];
    final previousEmail = currentTrainee.email;

    if (previousEmail.isNotEmpty && previousEmail != normalizedEmail) {
      final previousInvite =
          await _inviteService.findInviteByEmail(previousEmail);
      if (previousInvite?.isClaimed == true) {
        throw TraineeInviteException(
          'לא ניתן לשנות אימייל למתאמן שכבר נרשם לאפליקציה',
        );
      }
      await _inviteService.deleteInvite(previousEmail);
    }

    final updatedTrainee = currentTrainee.copyWith(
      name: name.trim(),
      email: normalizedEmail,
    );
    trainees[index] = updatedTrainee;
    await _saveTrainees(prefs, trainees);
    await _syncTraineeToFirestore(updatedTrainee);

    final existingInvite =
        await _inviteService.findInviteByEmail(normalizedEmail);
    if (existingInvite != null && existingInvite.traineeId == traineeId) {
      await _inviteService.updateInviteName(
        email: normalizedEmail,
        name: name.trim(),
      );
      return;
    }

    await _inviteService.createInvite(
      coachId: coachId,
      traineeId: traineeId,
      name: name.trim(),
      email: normalizedEmail,
    );
  }

  Future<void> _syncTraineeToFirestore(Trainee trainee) async {
    final doc = _firestore.traineeDoc(trainee.id);
    if (doc == null) {
      return;
    }

    try {
      await doc.set(
        {
          'id': trainee.id,
          'name': trainee.name,
          'email': trainee.email,
          'createdAt': trainee.createdAt.toIso8601String(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  Future<void> updateTraineeName(String traineeId, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final trainees = await getTrainees();
    final index = trainees.indexWhere((trainee) => trainee.id == traineeId);
    if (index == -1) {
      return;
    }

    trainees[index] = trainees[index].copyWith(name: name.trim());
    await _saveTrainees(prefs, trainees);
    await prefs.setString(nameKey(traineeId), name.trim());
    await _syncTraineeToFirestore(trainees[index]);
  }

  Future<void> deleteTrainee(String traineeId) async {
    final prefs = await SharedPreferences.getInstance();
    final trainees = await getTrainees();
    Trainee? traineeToDelete;
    for (final trainee in trainees) {
      if (trainee.id == traineeId) {
        traineeToDelete = trainee;
        break;
      }
    }

    final remainingTrainees =
        trainees.where((trainee) => trainee.id != traineeId).toList();

    await _saveTrainees(prefs, remainingTrainees);

    if (traineeToDelete != null && traineeToDelete.email.isNotEmpty) {
      await _inviteService.deleteInvite(traineeToDelete.email);
    }

    await prefs.remove(nameKey(traineeId));
    await prefs.remove(ageKey(traineeId));
    await prefs.remove(heightKey(traineeId));
    await prefs.remove(goalKey(traineeId));
    await prefs.remove(currentWeightKey(traineeId));
    await prefs.remove(targetWeightKey(traineeId));
    await prefs.remove(startingWeightKey(traineeId));
    await prefs.remove(weightHistoryKey(traineeId));
    await prefs.remove(weekdayMealsKey(traineeId));
    await prefs.remove(weekendMealsKey(traineeId));
    await prefs.remove(savedWorkoutsKey(traineeId));
    await prefs.remove(exerciseNotesKey(traineeId));

    final doc = _firestore.traineeDoc(traineeId);
    if (doc != null) {
      try {
        await doc.delete();
      } catch (_) {}
    }

    final activeId = await getActiveTraineeId();
    if (activeId == traineeId) {
      if (remainingTrainees.isEmpty) {
        await prefs.remove(activeTraineeIdKey);
      } else {
        await setActiveTrainee(remainingTrainees.first.id);
      }
    }
  }

  Future<void> _saveTrainees(
    SharedPreferences prefs,
    List<Trainee> trainees,
  ) async {
    await prefs.setString(
      traineesListKey,
      jsonEncode(trainees.map((trainee) => trainee.toMap()).toList()),
    );
  }
}
