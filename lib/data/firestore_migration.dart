import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/food_item.dart';
import '../models/trainee.dart';
import '../services/firestore_service.dart';
import 'coach_data_repository.dart';
import 'food_repository.dart';
import 'trainee_repository.dart';

class FirestoreMigration {
  FirestoreMigration._();

  static final FirestoreMigration instance = FirestoreMigration._();

  static const String migrationDoneKey = 'firestore_migrated_v1';

  final FirestoreService _firestore = FirestoreService.instance;
  final TraineeRepository _traineeRepository = TraineeRepository.instance;
  final CoachDataRepository _dataRepository = CoachDataRepository.instance;

  Future<void> runIfNeeded() async {
    if (!_firestore.isReady) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(migrationDoneKey) == true) {
      return;
    }

    await _traineeRepository.ensureMigrated();

    final trainees = await _traineeRepository.getTraineesLocal();
    final coachDoc = _firestore.coachDoc();
    if (coachDoc == null) {
      return;
    }

    try {
      final batch = FirebaseFirestore.instance.batch();
      final traineesCollection = _firestore.traineesCollection();
      if (traineesCollection == null) {
        return;
      }

      for (final trainee in trainees) {
        final doc = traineesCollection.doc(trainee.id);
        final payload = await _dataRepository.buildTraineeDocumentFromLocal(
          trainee.id,
        );
        batch.set(
          doc,
          {
            ...payload,
            'name': trainee.name,
            'createdAt': trainee.createdAt.toIso8601String(),
          },
          SetOptions(merge: true),
        );
      }

      final activeTraineeId = prefs.getString(TraineeRepository.activeTraineeIdKey);
      batch.set(
        coachDoc,
        {
          if (activeTraineeId != null) 'activeTraineeId': activeTraineeId,
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await _migrateCustomFoods(batch);
      await batch.commit();
      await prefs.setBool(migrationDoneKey, true);
    } catch (_) {}
  }

  Future<void> _migrateCustomFoods(WriteBatch batch) async {
    await FoodRepository.ensureCustomFoodsLoaded();
    final customFoods = FoodRepository.customFoods;
    final collection = _firestore.customFoodsCollection();
    if (collection == null) {
      return;
    }

    for (final food in customFoods) {
      batch.set(
        collection.doc('${food.id}'),
        food.toMap(),
        SetOptions(merge: true),
      );
    }
  }

  Future<void> pullTraineesFromCloudIfNeeded() async {
    if (!_firestore.isReady) {
      return;
    }

    final collection = _firestore.traineesCollection();
    if (collection == null) {
      return;
    }

    try {
      final snapshot = await collection.get();
      if (snapshot.docs.isEmpty) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final trainees = snapshot.docs.map((doc) {
        final data = doc.data();
        return Trainee(
          id: data['id'] as String? ?? doc.id,
          name: data['name'] as String? ?? 'מתאמן',
          email: data['email'] as String? ?? '',
          createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ??
              DateTime.now(),
        );
      }).toList();

      await prefs.setString(
        TraineeRepository.traineesListKey,
        jsonEncode(trainees.map((trainee) => trainee.toMap()).toList()),
      );

      final coachDoc = await _firestore.coachDoc()?.get();
      final activeTraineeId = coachDoc?.data()?['activeTraineeId'] as String?;
      if (activeTraineeId != null) {
        await prefs.setString(
          TraineeRepository.activeTraineeIdKey,
          activeTraineeId,
        );
      }

      for (final doc in snapshot.docs) {
        await _cacheTraineeDocLocally(doc.id, doc.data());
      }

      await _pullCustomFoodsFromCloud();
    } catch (_) {}
  }

  Future<void> pullTraineeDataFromCloud(
    String coachId,
    String traineeId,
  ) async {
    final doc = _firestore.traineeDocForCoach(coachId, traineeId);
    if (doc == null) {
      return;
    }

    try {
      final snapshot = await doc.get();
      if (!snapshot.exists) {
        return;
      }

      await _cacheTraineeDocLocally(traineeId, snapshot.data()!);
    } catch (_) {}
  }

  Future<void> _cacheTraineeDocLocally(
    String traineeId,
    Map<String, dynamic> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final repository = TraineeRepository.instance;

    if (data['name'] != null) {
      await prefs.setString(repository.nameKey(traineeId), data['name'] as String);
    }
    if (data['age'] != null) {
      await prefs.setInt(repository.ageKey(traineeId), data['age'] as int);
    }
    if (data['height'] != null) {
      await prefs.setDouble(
        repository.heightKey(traineeId),
        (data['height'] as num).toDouble(),
      );
    }
    if (data['goal'] != null) {
      await prefs.setString(repository.goalKey(traineeId), data['goal'] as String);
    }
    if (data['currentWeight'] != null) {
      await prefs.setDouble(
        repository.currentWeightKey(traineeId),
        (data['currentWeight'] as num).toDouble(),
      );
    }
    if (data['targetWeight'] != null) {
      await prefs.setDouble(
        repository.targetWeightKey(traineeId),
        (data['targetWeight'] as num).toDouble(),
      );
    }
    if (data['startingWeight'] != null) {
      await prefs.setDouble(
        repository.startingWeightKey(traineeId),
        (data['startingWeight'] as num).toDouble(),
      );
    }
    if (data['weightHistory'] != null) {
      await prefs.setString(
        repository.weightHistoryKey(traineeId),
        jsonEncode(data['weightHistory']),
      );
    }
    if (data['weekdayMeals'] != null) {
      await prefs.setString(
        repository.weekdayMealsKey(traineeId),
        jsonEncode(data['weekdayMeals']),
      );
    }
    if (data['weekendMeals'] != null) {
      await prefs.setString(
        repository.weekendMealsKey(traineeId),
        jsonEncode(data['weekendMeals']),
      );
    }
    if (data['savedWorkouts'] != null) {
      await prefs.setString(
        repository.savedWorkoutsKey(traineeId),
        jsonEncode(data['savedWorkouts']),
      );
    }
    if (data['exerciseNotes'] != null) {
      await prefs.setString(
        repository.exerciseNotesKey(traineeId),
        jsonEncode(data['exerciseNotes']),
      );
    }
  }

  Future<void> _pullCustomFoodsFromCloud() async {
    final collection = _firestore.customFoodsCollection();
    if (collection == null) {
      return;
    }

    try {
      final snapshot = await collection.get();
      if (snapshot.docs.isEmpty) {
        return;
      }

      final foods = snapshot.docs
          .map((doc) => FoodItem.fromMap(doc.data()))
          .toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'coach_custom_foods',
        jsonEncode(foods.map((food) => food.toMap()).toList()),
      );
      FoodRepository.replaceCustomFoodsCache(foods);
    } catch (_) {}
  }
}
