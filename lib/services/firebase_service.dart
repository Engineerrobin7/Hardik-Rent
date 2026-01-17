import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_storage/firebase_storage.dart';
import '../data/models/models.dart';

class FirebaseService {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Singleton
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // --- Auth ---
  Future<auth.User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  Future<auth.User?> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<auth.User?> signUp(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // --- Firestore: Flats ---
  Stream<List<Flat>> getFlats() {
    return _db.collection('flats').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Flat.fromJson({...doc.data(), 'id': doc.id});
      }).toList();
    });
  }

  Future<void> addFlat(Flat flat) async {
    await _db.collection('flats').add(flat.toJson()..remove('id'));
  }

  Future<void> updateFlat(Flat flat) async {
    await _db.collection('flats').doc(flat.id).update(flat.toJson()..remove('id'));
  }

  // --- Firestore: Tenants (Users) ---
  Stream<List<User>> getTenants() {
    return _db.collection('users')
        .where('role', isEqualTo: 'tenant')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return User.fromJson({...doc.data(), 'id': doc.id});
      }).toList();
    });
  }
  
  Future<void> addTenant(User tenant) async {
    // Note: Creating a user in Firestore doesn't create auth account. 
    // In a real app, you'd use Admin SDK or secondary auth flow.
    // Here we just store the profile.
    await _db.collection('users').doc(tenant.id).set(tenant.toJson());
  }

  Future<User?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return User.fromJson({...doc.data()!, 'id': doc.id});
    }
    return null;
  }

  // --- Firestore: Rent Records ---
  Stream<List<RentRecord>> getRentRecords() {
    return _db.collection('rent_records').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return RentRecord.fromJson({...doc.data(), 'id': doc.id});
      }).toList();
    });
  }

  Future<void> addRentRecord(RentRecord record) async {
    await _db.collection('rent_records').add(record.toJson()..remove('id'));
  }
  
  Future<void> updateRentRecord(RentRecord record) async {
     await _db.collection('rent_records').doc(record.id).update(record.toJson()..remove('id'));
  }

  // --- Firestore: Payments ---
  Future<void> submitPayment(PaymentRecord payment) async {
    await _db.collection('payments').add(payment.toJson()..remove('id'));
  }

  Stream<List<PaymentRecord>> getPayments() {
    return _db.collection('payments').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return PaymentRecord.fromJson({...doc.data(), 'id': doc.id});
      }).toList();
    });
  }
  
  Future<void> updatePaymentStatus(String paymentId, PaymentStatus status) async {
    await _db.collection('payments').doc(paymentId).update({
      'status': status.toString().split('.').last
    });
  }

  // --- Storage ---
  Future<String> uploadFile(String path, File file) async {
    final ref = _storage.ref().child(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }
}
