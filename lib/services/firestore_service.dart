import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'trainee_session.dart';

class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get coachId => FirebaseAuth.instance.currentUser?.uid;

  bool get isReady => effectiveCoachId != null;

  String? get effectiveCoachId {
    final sessionCoachId = TraineeSession.instance.coachId;
    final sessionTraineeId = TraineeSession.instance.traineeId;

    if (sessionCoachId != null &&
        sessionCoachId.isNotEmpty &&
        sessionTraineeId != null) {
      return sessionCoachId;
    }

    return coachId;
  }

  DocumentReference<Map<String, dynamic>>? coachDocForId(String coachUid) {
    return _db.collection('coaches').doc(coachUid);
  }

  DocumentReference<Map<String, dynamic>>? coachDoc() {
    final uid = effectiveCoachId;
    if (uid == null) {
      return null;
    }
    return coachDocForId(uid);
  }

  CollectionReference<Map<String, dynamic>>? traineesCollectionForCoach(
    String coachUid,
  ) {
    return coachDocForId(coachUid)?.collection('trainees');
  }

  CollectionReference<Map<String, dynamic>>? traineesCollection() {
    return coachDoc()?.collection('trainees');
  }

  DocumentReference<Map<String, dynamic>>? traineeDocForCoach(
    String coachUid,
    String traineeId,
  ) {
    return traineesCollectionForCoach(coachUid)?.doc(traineeId);
  }

  DocumentReference<Map<String, dynamic>>? traineeDoc(String traineeId) {
    return traineesCollection()?.doc(traineeId);
  }

  CollectionReference<Map<String, dynamic>>? customFoodsCollection() {
    return coachDoc()?.collection('customFoods');
  }
}
