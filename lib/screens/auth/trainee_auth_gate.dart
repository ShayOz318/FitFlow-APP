import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/firestore_migration.dart';
import '../../services/auth_service.dart';
import '../../services/trainee_auth_service.dart';
import '../../services/trainee_invite_service.dart';
import '../../services/trainee_session.dart';
import '../trainee/trainee_dashboard_screen.dart';
import 'trainee_login_screen.dart';

class TraineeAuthGate extends StatelessWidget {
  const TraineeAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final user = snapshot.data;
        if (user != null) {
          return _TraineeSignedInShell(user: user);
        }

        return TraineeLoginScreen(
          initialErrorMessage: TraineeAuthService.instance.lastLinkError,
        );
      },
    );
  }
}

class _TraineeSignedInShell extends StatefulWidget {
  final User user;

  const _TraineeSignedInShell({required this.user});

  @override
  State<_TraineeSignedInShell> createState() => _TraineeSignedInShellState();
}

class _TraineeSignedInShellState extends State<_TraineeSignedInShell> {
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _prepareTraineeSession();
  }

  Future<void> _prepareTraineeSession() async {
    await TraineeSession.instance.reload();

    if (!TraineeSession.instance.isActive) {
      try {
        await TraineeAuthService.instance.linkSessionForCurrentUser();
        await TraineeSession.instance.reload();
      } on TraineeInviteException catch (error) {
        TraineeAuthService.instance.lastLinkError = error.message;
        await TraineeAuthService.instance.signOutTrainee();
        return;
      }
    }

    if (!TraineeSession.instance.isActive) {
      TraineeAuthService.instance.lastLinkError =
          'לא נמצא חשבון מתאמן מקושר לאימייל הזה';
      await TraineeAuthService.instance.signOutTrainee();
      return;
    }

    await FirestoreMigration.instance.pullTraineeDataFromCloud(
      TraineeSession.instance.coachId!,
      TraineeSession.instance.traineeId!,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return TraineeDashboardScreen(
      traineeId: TraineeSession.instance.traineeId!,
    );
  }
}
