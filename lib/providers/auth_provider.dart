import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/models.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _token;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  AuthProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    // In a real app, we would verify the token and fetch user details
    if (_token != null) {
      // Mock session restoration
      _currentUser = User(
        id: 'owner_1',
        name: 'Hardik Landlord',
        email: 'owner@example.com',
        role: UserRole.owner,
      );
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Mock API call
    await Future.delayed(const Duration(seconds: 1));

    if (email == 'owner@hardik.com' && password == 'password') {
      _currentUser = User(
        id: 'owner_1',
        name: 'Hardik Owner',
        email: email,
        role: UserRole.owner,
      );
      _token = 'mock_jwt_token_owner';
    } else if (email == 'tenant@hardik.com' && password == 'password') {
      _currentUser = User(
        id: 'tenant_1',
        name: 'Rahul Tenant',
        email: email,
        role: UserRole.tenant,
      );
      _token = 'mock_jwt_token_tenant';
    } else {
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', _token!);
    
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _currentUser = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    notifyListeners();
  }

  Future<bool> register(String name, String email, String password, UserRole role) async {
    _isLoading = true;
    notifyListeners();

    // Mock API call
    await Future.delayed(const Duration(seconds: 1));

    _currentUser = User(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      role: role,
    );
    _token = 'mock_jwt_token_new';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', _token!);

    _isLoading = false;
    notifyListeners();
    return true;
  }
}
