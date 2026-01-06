import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AppRole { teacher, student, unknown }

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? _user;
  AppRole _role = AppRole.unknown;
  bool _isLoading = true;

  User? get user => _user;
  AppRole get role => _role;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String get fullName => _user?.userMetadata?['full_name'] ?? 'Student';
  String get email => _user?.email ?? '';

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        _user = session.user;
        await _fetchUserRole();
      }
    } catch (e) {
      debugPrint('Auth Init Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // Listen to Auth Changes
    _supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        _user = session.user;
        _isLoading = true;
        notifyListeners();
        
        await _fetchUserRole();
        
        _isLoading = false;
        notifyListeners();
      } else if (event == AuthChangeEvent.signedOut) {
        _user = null;
        _role = AppRole.unknown;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchUserRole() async {
    if (_user == null) return;

    try {
      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', _user!.id)
          .maybeSingle();

      if (response != null && response['role'] != null) {
        final roleStr = response['role'] as String;
        if (roleStr == 'teacher') {
          _role = AppRole.teacher;
        } else {
          _role = AppRole.student;
        }
      }
    } catch (e) {
      debugPrint('Error fetching role: $e');
      // Fallback or retry logic could go here
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
  
  // Login wrapper for UI usage
  Future<void> signIn(String email, String password) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  // SignUp wrapper for UI usage
  Future<void> signUp(String email, String password, String fullName, bool isTeacher) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': isTeacher ? 'teacher' : 'student', 
      },
    );
  }
}
