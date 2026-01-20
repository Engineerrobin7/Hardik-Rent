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

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final authUser = await _service.signInWithGoogle();
      if (authUser != null) {
        final userData = await _service.getUser(authUser.uid);
        if (userData == null) {
          // New Google User: Create default profile as Tenant
          final newUser = User(
            id: authUser.uid,
            name: authUser.displayName ?? 'Google User',
            email: authUser.email ?? '',
            role: UserRole.tenant, // Default to tenant
            photoUrl: authUser.photoURL,
          );
          await _service.addTenant(newUser);
          _currentUser = newUser;
        } else {
          _currentUser = userData;
        }
        _startUserListener(authUser.uid);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Google Login Error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Phone Auth
  Future<void> verifyPhone({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    await _service.verifyPhone(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId, _) => onCodeSent(verificationId),
      onVerificationFailed: (e) => onError(e.message ?? 'Verification failed'),
      onVerificationCompleted: (credential) async {
        // Auto-signin if possible (Android only)
        // This is complex to handle through provider, usually we just wait for sms code
      },
    );
  }

  Future<bool> signInWithPhoneNumber(String verificationId, String smsCode) async {
    _isLoading = true;
    notifyListeners();

    try {
      final authUser = await _service.signInWithPhoneNumber(verificationId, smsCode);
      if (authUser != null) {
        final userData = await _service.getUser(authUser.uid);
        if (userData == null) {
           final newUser = User(
            id: authUser.uid,
            name: 'User ${phoneNumberMask(authUser.phoneNumber)}',
            email: '',
            role: UserRole.tenant,
          );
          await _service.addTenant(newUser);
          _currentUser = newUser;
        } else {
          _currentUser = userData;
        }
        _startUserListener(authUser.uid);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Phone Auth Error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  String phoneNumberMask(String? phone) {
    if (phone == null || phone.length < 4) return 'New';
    return phone.substring(phone.length - 4);
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
        photoUrl: _currentUser!.photoUrl,
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
