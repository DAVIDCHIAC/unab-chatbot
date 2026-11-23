import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guarda el código del estudiante y el identificador de la sesión de chat.
class SessionProvider extends ChangeNotifier {
  static const String _kStudentId = 'unab_student_id';
  static const String _kStudentName = 'unab_student_name';
  static const String _kSessionId = 'unab_session_id';

  String? _studentId;
  String? _studentName;
  String _sessionId = '';
  bool _loaded = false;

  String? get studentId => _studentId;
  String? get studentName => _studentName;
  String get sessionId => _sessionId;
  bool get loaded => _loaded;
  bool get isLoggedIn => (_studentId ?? '').isNotEmpty;

  String get displayName {
    final String? name = _studentName;
    if (name != null && name.isNotEmpty) return name;
    if (isLoggedIn) return 'Estudiante $_studentId';
    return 'Invitado';
  }

  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _studentId = prefs.getString(_kStudentId);
    _studentName = prefs.getString(_kStudentName);
    _sessionId = prefs.getString(_kSessionId) ?? _newSessionId();
    await prefs.setString(_kSessionId, _sessionId);
    _loaded = true;
    notifyListeners();
  }

  Future<void> signIn(String studentId, {String? name}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _studentId = studentId.trim();
    _studentName = name?.trim();
    _sessionId = _newSessionId();
    await prefs.setString(_kStudentId, _studentId!);
    await prefs.setString(_kSessionId, _sessionId);
    if (_studentName == null || _studentName!.isEmpty) {
      await prefs.remove(_kStudentName);
      _studentName = null;
    } else {
      await prefs.setString(_kStudentName, _studentName!);
    }
    notifyListeners();
  }

  Future<void> updateName(String name) async {
    final String clean = name.trim();
    if (clean.isEmpty || clean == _studentName) return;
    _studentName = clean;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kStudentName, clean);
    notifyListeners();
  }

  Future<void> newSession() async {
    _sessionId = _newSessionId();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSessionId, _sessionId);
    notifyListeners();
  }

  Future<void> signOut() async {
    _studentId = null;
    _studentName = null;
    _sessionId = _newSessionId();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kStudentId);
    await prefs.remove(_kStudentName);
    await prefs.setString(_kSessionId, _sessionId);
    notifyListeners();
  }

  String _newSessionId() {
    final int now = DateTime.now().millisecondsSinceEpoch;
    return 'ses-$now';
  }
}
