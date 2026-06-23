import 'package:cloud_firestore/cloud_firestore.dart';

class TraineeInvite {
  final String email;
  final String coachId;
  final String traineeId;
  final String name;
  final String? claimedByUid;

  const TraineeInvite({
    required this.email,
    required this.coachId,
    required this.traineeId,
    required this.name,
    this.claimedByUid,
  });

  bool get isClaimed => claimedByUid != null && claimedByUid!.isNotEmpty;

  factory TraineeInvite.fromMap(Map<String, dynamic> map) {
    return TraineeInvite(
      email: map['email'] as String,
      coachId: map['coachId'] as String,
      traineeId: map['traineeId'] as String,
      name: map['name'] as String,
      claimedByUid: map['claimedByUid'] as String?,
    );
  }
}

class TraineeInviteService {
  TraineeInviteService._();

  static final TraineeInviteService instance = TraineeInviteService._();

  static const String collectionName = 'traineeInvites';

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String normalizeEmail(String email) => email.trim().toLowerCase();

  String emailDocId(String email) => normalizeEmail(email);

  bool isValidEmail(String email) {
    final normalized = normalizeEmail(email);
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(normalized);
  }

  DocumentReference<Map<String, dynamic>> inviteDoc(String email) {
    return _db.collection(collectionName).doc(emailDocId(email));
  }

  Future<bool> isEmailAvailableForTrainee(String email, String traineeId) async {
    final invite = await findInviteByEmail(email);
    if (invite == null) {
      return true;
    }
    return invite.traineeId == traineeId;
  }

  Future<void> updateInviteName({
    required String email,
    required String name,
  }) async {
    await inviteDoc(email).set(
      {'name': name.trim()},
      SetOptions(merge: true),
    );
  }

  Future<bool> isEmailAvailable(String email) async {
    final snapshot = await inviteDoc(email).get();
    return !snapshot.exists;
  }

  Future<void> createInvite({
    required String coachId,
    required String traineeId,
    required String name,
    required String email,
  }) async {
    final normalizedEmail = normalizeEmail(email);

    await inviteDoc(normalizedEmail).set({
      'email': normalizedEmail,
      'coachId': coachId,
      'traineeId': traineeId,
      'name': name.trim(),
      'claimedByUid': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<TraineeInvite?> findInviteByEmail(String email) async {
    final snapshot = await inviteDoc(email).get();
    if (!snapshot.exists) {
      return null;
    }

    return TraineeInvite.fromMap(snapshot.data()!);
  }

  Future<TraineeInvite?> claimInvite({
    required String email,
    required String authUid,
  }) async {
    final invite = await findInviteByEmail(email);
    if (invite == null) {
      return null;
    }

    if (invite.isClaimed && invite.claimedByUid != authUid) {
      throw TraineeInviteException('האימייל הזה כבר רשום למתאמן אחר');
    }

    await inviteDoc(email).set(
      {'claimedByUid': authUid},
      SetOptions(merge: true),
    );

    return invite;
  }

  Future<void> deleteInvite(String email) async {
    try {
      await inviteDoc(email).delete();
    } catch (_) {}
  }
}

class TraineeInviteException implements Exception {
  final String message;

  TraineeInviteException(this.message);

  @override
  String toString() => message;
}
