import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/firestore_migration.dart';
import '../../services/auth_service.dart';
import '../../services/trainee_session.dart';
import '../coach/coach_home_screen.dart';
import 'coach_login_screen.dart';

class CoachAuthGate extends StatelessWidget {
  const CoachAuthGate({super.key});

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

        if (snapshot.data != null) {
          return const _SignedInShell();
        }

        return const CoachLoginScreen();
      },
    );
  }
}

class _SignedInShell extends StatefulWidget {
  const _SignedInShell();

  @override
  State<_SignedInShell> createState() => _SignedInShellState();
}

class _SignedInShellState extends State<_SignedInShell> {
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _prepareData();
  }

  Future<void> _prepareData() async {
    await TraineeSession.instance.clear();
    await FirestoreMigration.instance.runIfNeeded();
    await FirestoreMigration.instance.pullTraineesFromCloudIfNeeded();

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

    return const CoachHomeScreen();
  }
}
