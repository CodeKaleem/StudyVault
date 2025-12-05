import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _userKey = 'auth_user';
  final Uuid _uuid = const Uuid();

  // Mock database
  final List<Map<String, dynamic>> _mockUsers = [];

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr != null) {
      return User.fromMap(jsonDecode(userStr));
    }
    return null;
  }

  Future<User> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (!_isValidPassword(password)) {
      throw Exception(
          'Password must be 8+ chars, with 1 upper, 1 lower, 1 numeric, 1 special char.');
    }

    // Check if email exists (mock)
    if (_mockUsers.any((u) => u['email'] == email)) {
      throw Exception('Email already in use');
    }

    final newUser = User(
      id: _uuid.v4(),
      name: name,
      email: email,
      role: role,
    );

    // Save to mock db
    _mockUsers.add({
      ...newUser.toMap(),
      'password': password, 
    });

    // Auto login
    await _saveUserToPrefs(newUser);
    return newUser;
  }

  Future<User> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    // For demo purposes, if mock db is empty, allow a default login or just fail
    // But since we want to test, we should probably rely on signup first.
    // However, to make it easier, let's allow a "backdoor" or just strict check.
    // Strict check is better for the requirements.
    
    final userMap = _mockUsers.firstWhere(
      (u) => u['email'] == email && u['password'] == password,
      orElse: () => {},
    );

    if (userMap.isEmpty) {
      throw Exception('Invalid email or password');
    }

    final user = User.fromMap(userMap);
    await _saveUserToPrefs(user);
    return user;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  Future<void> _saveUserToPrefs(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toMap()));
  }

  bool _isValidPassword(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
    return true;
  }
}
