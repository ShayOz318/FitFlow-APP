import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../services/trainee_invite_service.dart';
import '../services/trainee_session.dart';

class TraineeAuthService {
  TraineeAuthService._();

  static final TraineeAuthService instance = TraineeAuthService._();

  final AuthService _auth = AuthService.instance;
  final TraineeInviteService _invites = TraineeInviteService.instance;

  String? lastLinkError;

  Future<TraineeInvite> signUpTrainee({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _invites.normalizeEmail(email);

    if (!_invites.isValidEmail(normalizedEmail)) {
      throw TraineeInviteException('יש להזין כתובת אימייל תקינה');
    }

    await _prepareForTraineeAuth();

    try {
      await _auth.signUpWithEmail(email: normalizedEmail, password: password);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        throw TraineeInviteException(
          'האימייל כבר רשום. נסי להתחבר במקום להירשם',
        );
      }
      rethrow;
    }

    return linkSessionForCurrentUser();
  }

  Future<TraineeInvite> signInTrainee({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _invites.normalizeEmail(email);

    if (!_invites.isValidEmail(normalizedEmail)) {
      throw TraineeInviteException('יש להזין כתובת אימייל תקינה');
    }

    await _prepareForTraineeAuth();
    await _auth.signInWithEmail(email: normalizedEmail, password: password);

    return linkSessionForCurrentUser();
  }

  Future<TraineeInvite> linkSessionForCurrentUser() async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      throw TraineeInviteException('שגיאת התחברות. נסי שוב');
    }

    return _linkCurrentUserToInvite(_invites.normalizeEmail(email));
  }

  Future<void> signOutTrainee() async {
    await TraineeSession.instance.clear();
    await _auth.signOut();
  }

  Future<void> _prepareForTraineeAuth() async {
    lastLinkError = null;
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await TraineeSession.instance.clear();
      await _auth.signOut();
    }
  }

  Future<TraineeInvite> _linkCurrentUserToInvite(String email) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw TraineeInviteException('שגיאת התחברות. נסי שוב');
    }

    TraineeInvite? invite;
    try {
      invite = await _invites.findInviteByEmail(email);
    } catch (_) {
      throw TraineeInviteException(
        'לא הצלחנו לאמת את האימייל. בדקי חיבור לאינטרנט ונסי שוב',
      );
    }

    if (invite == null) {
      lastLinkError =
          'האימייל הזה לא רשום אצל מאמן. המאמן צריך לשמור את הפרופיל שלך עם האימייל הזה לפני ההרשמה';
      await _auth.signOut();
      throw TraineeInviteException(lastLinkError!);
    }

    if (invite.isClaimed && invite.claimedByUid != user.uid) {
      lastLinkError = 'האימייל הזה כבר בשימוש על ידי מתאמן אחר';
      await _auth.signOut();
      throw TraineeInviteException(lastLinkError!);
    }

    TraineeInvite? linkedInvite;
    try {
      linkedInvite = await _invites.claimInvite(
        email: email,
        authUid: user.uid,
      );
    } catch (error) {
      lastLinkError = error is TraineeInviteException
          ? error.message
          : 'לא הצלחנו לקשר את החשבון למתאמן';
      await _auth.signOut();
      throw TraineeInviteException(lastLinkError!);
    }

    if (linkedInvite == null) {
      lastLinkError = 'לא הצלחנו לקשר את החשבון למתאמן';
      await _auth.signOut();
      throw TraineeInviteException(lastLinkError!);
    }

    await TraineeSession.instance.save(
      coachId: linkedInvite.coachId,
      traineeId: linkedInvite.traineeId,
      email: linkedInvite.email,
      name: linkedInvite.name,
    );

    lastLinkError = null;
    return linkedInvite;
  }
}
