import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/models.dart';
import '../services/firebase_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseService _service = FirebaseService();
  User? _currentUser;
  bool _isLoading = false;
  StreamSubscription? _userSub;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    final authUser = await _service.getCurrentUser();
    if (authUser != null) {
      _startUserListener(authUser.uid);
    }
  }

  void _startUserListener(String uid) {
    _userSub?.cancel();
    _userSub = _service.streamUser(uid).listen((userData) {
      if (userData != null) {
        _currentUser = userData;
        notifyListeners();
      }
    });
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final authUser = await _service.signIn(email, password);
      if (authUser != null) {
        _startUserListener(authUser.uid);
        _isLoading = false;
        return true;
      }
    } catch (e) {
      debugPrint('Login Error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _userSub?.cancel();
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
        
        // Save profile to Firestore
        await _service.addTenant(newUser);

        _startUserListener(authUser.uid);
        _isLoading = false;
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

  Future<void> updateProfile({required String name, required String phoneNumber}) async {
    if (_currentUser == null) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final updatedUser = User(
        id: _currentUser!.id,
        name: name,
        email: _currentUser!.email,
        role: _currentUser!.role,
        phoneNumber: phoneNumber,
      );

      await _service.updateUser(updatedUser);
      _currentUser = updatedUser;
    } catch (e) {
      debugPrint('Update Profile Error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
