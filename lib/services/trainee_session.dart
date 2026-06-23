import 'package:shared_preferences/shared_preferences.dart';

class TraineeSession {
  TraineeSession._();

  static final TraineeSession instance = TraineeSession._();

  static const String _coachIdKey = 'trainee_session_coach_id';
  static const String _traineeIdKey = 'trainee_session_trainee_id';
  static const String _emailKey = 'trainee_session_email';
  static const String _nameKey = 'trainee_session_name';

  String? _coachId;
  String? _traineeId;
  String? _email;
  String? _name;
  bool _loaded = false;

  String? get coachId => _coachId;
  String? get traineeId => _traineeId;
  String? get email => _email;
  String? get name => _name;

  bool get isActive =>
      _coachId != null && _traineeId != null && _email != null;

  Future<void> ensureLoaded() async {
    if (!_loaded) {
      await reload();
    }
  }

  Future<void> reload() async {
    final prefs = await SharedPreferences.getInstance();
    _coachId = prefs.getString(_coachIdKey);
    _traineeId = prefs.getString(_traineeIdKey);
    _email = prefs.getString(_emailKey);
    _name = prefs.getString(_nameKey);
    _loaded = true;
  }

  Future<void> save({
    required String coachId,
    required String traineeId,
    required String email,
    required String name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_coachIdKey, coachId);
    await prefs.setString(_traineeIdKey, traineeId);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_nameKey, name);

    _coachId = coachId;
    _traineeId = traineeId;
    _email = email;
    _name = name;
    _loaded = true;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_coachIdKey);
    await prefs.remove(_traineeIdKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_nameKey);

    _coachId = null;
    _traineeId = null;
    _email = null;
    _name = null;
    _loaded = true;
  }
}
