import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/trainee_auth_service.dart';
import '../../services/trainee_invite_service.dart';

class TraineeLoginScreen extends StatefulWidget {
  final String? initialErrorMessage;

  const TraineeLoginScreen({
    super.key,
    this.initialErrorMessage,
  });

  @override
  State<TraineeLoginScreen> createState() => _TraineeLoginScreenState();
}

class _TraineeLoginScreenState extends State<TraineeLoginScreen> {
  final TraineeAuthService _traineeAuth = TraineeAuthService.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _errorMessage = widget.initialErrorMessage;
    TraineeAuthService.instance.lastLinkError = null;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'יש למלא אימייל וסיסמה';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLoginMode) {
        await _traineeAuth.signInTrainee(email: email, password: password);
      } else {
        await _traineeAuth.signUpTrainee(email: email, password: password);
      }
    } on TraineeInviteException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } on FirebaseAuthException catch (error) {
      setState(() {
        _errorMessage = _mapAuthError(error);
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'שגיאת התחברות. נסי שוב';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'כתובת האימייל לא תקינה';
      case 'user-not-found':
        return 'לא נמצא משתמש עם האימייל הזה';
      case 'wrong-password':
        return 'סיסמה שגויה';
      case 'email-already-in-use':
        return 'האימייל כבר בשימוש';
      case 'weak-password':
        return 'הסיסמה חלשה מדי (לפחות 6 תווים)';
      default:
        return error.message ?? 'שגיאת התחברות';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('כניסת מתאמן'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'ברוכה הבאה',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoginMode
                      ? 'התחברי עם האימייל שהמאמן רשם עבורך'
                      : 'הירשמי רק עם האימייל שהמאמן הוסיף עבורך',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'אימייל',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'סיסמה',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isLoginMode ? 'התחבר' : 'הירשם'),
                ),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _isLoginMode = !_isLoginMode;
                            _errorMessage = null;
                          });
                        },
                  child: Text(
                    _isLoginMode
                        ? 'פעם ראשונה? הירשמי כאן'
                        : 'יש לך חשבון? התחברי',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
