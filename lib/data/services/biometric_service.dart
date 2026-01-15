// Sprint 4: Biometric Authentication Service
// File: lib/data/services/biometric_service.dart

import 'package:flutter/foundation.dart';

import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  final LocalAuthentication auth = LocalAuthentication();

  // Check if hardware supports biometrics
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Error checking biometrics: $e');
      return false;
    }
  }

  // Authenticate user
  Future<bool> authenticateUser() async {
    try {
      bool authenticated = await auth.authenticate(
        localizedReason: 'Please authenticate to access Hardik Rent',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('Error authenticating: $e');
      return false;
    }
  }

  // Get available biometric types (Face ID, Fingerprint)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('Error getting biometric types: $e');
      return <BiometricType>[];
    }
  }
}
