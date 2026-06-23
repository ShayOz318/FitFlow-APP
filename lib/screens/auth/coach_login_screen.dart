import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class CoachLoginScreen extends StatefulWidget {
  const CoachLoginScreen({super.key});

  @override
  State<CoachLoginScreen> createState() => _CoachLoginScreenState();
}

class _CoachLoginScreenState extends State<CoachLoginScreen> {
  final AuthService _authService = AuthService.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;
  String? _errorMessage;

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
        await _authService.signInWithEmail(email: email, password: password);
      } else {
        await _authService.signUpWithEmail(email: email, password: password);
      }
    } on FirebaseAuthException catch (error) {
      setState(() {
        _errorMessage = _mapAuthError(error);
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
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'כניסת מאמן',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoginMode
                      ? 'התחברי כדי לנהל את המתאמנים שלך'
                      : 'צרי חשבון מאמן חדש',
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
                        ? 'אין חשבון? הירשמי כאן'
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
