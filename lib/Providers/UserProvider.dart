import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:try_space/Models/UserModel.dart';

class UserProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _user;
  UserModel? get user => _user;

  Future<void> fetchUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _user = UserModel.fromMap(doc.data()!);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching user: $e');
    }
  }

  Future<void> addUserToFirestore(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toMap());
    _user = user;
    notifyListeners();
  }

  Future<void> saveUser(UserModel userModel) async {
    await _firestore.collection('users').doc(userModel.uid).set(userModel.toMap());
    _user = userModel;
    notifyListeners();
  }

  /// ✅ Unified method to update profile
  Future<void> updateUserProfile({
    required String name,
    required String profileImageUrl,
  }) async {
    if (_user == null) return;

    try {
      final docRef = _firestore.collection('users').doc(_user!.uid);

      await docRef.update({
        'name': name,
        'profileImageUrl': profileImageUrl,
      });

      _user = UserModel(
        uid: _user!.uid,
        name: name,
        email: _user!.email,
        profileImageUrl: profileImageUrl,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
