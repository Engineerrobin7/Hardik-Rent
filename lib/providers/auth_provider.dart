import 'package:flutter/material.dart';
import '../data/models/models.dart';
import '../services/firebase_service.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseService _service = FirebaseService();
  final ApiService _apiService = ApiService();
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    final authUser = await _service.getCurrentUser();
    if (authUser != null) {
      final userData = await _apiService.getUserProfile();
      if (userData != null) {
        _currentUser = User.fromJson(userData);
        notifyListeners();
      }
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final authUser = await _service.signIn(email, password);
      if (authUser != null) {
        // Fetch from MySQL instead of Firestore
        final userData = await _apiService.getUserProfile();
        if (userData != null) {
          _currentUser = User.fromJson(userData);
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('Login Error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _service.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> register(String name, String email, String password, UserRole role) async {
    _isLoading = true;
    notifyListeners();

    try {
      final authUser = await _service.signUp(email, password);
      if (authUser != null) {
        final newUser = User(
          id: authUser.uid,
          name: name,
          email: email,
          role: role,
        );
        
        // Save profile to Firestore (Backup/Sync)
        await _service.addTenant(newUser);
        
        // Sync with MySQL (This is now the primary storage)
        await _apiService.syncUserWithBackend(
          email: newUser.email,
          name: newUser.name,
          role: newUser.role.toString().split('.').last,
        );

        _currentUser = newUser;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Register Error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> resetPassword(String email) async {
    try {
      await _service.resetPassword(email);
    } catch (e) {
      debugPrint('Reset Password Error: $e');
      rethrow;
    }
  }
}
