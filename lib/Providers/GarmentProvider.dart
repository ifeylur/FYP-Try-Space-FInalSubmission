import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:try_space/Models/GarmentModel.dart';

class GarmentProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<GarmentModel> _garments = [];
  List<GarmentModel> get garments => _garments;

  /// Fetch all garments
  Future<void> fetchGarments() async {
    try {
      final snapshot = await _firestore.collection('garments').get();
      _garments = snapshot.docs
          .map((doc) => GarmentModel.fromMap(doc.data()))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching garments: $e');
    }
  }

  /// Add a new garment
  Future<void> addGarment(GarmentModel garment) async {
    try {
      await _firestore.collection('garments').doc(garment.id).set(garment.toMap());
      _garments.add(garment);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding garment: $e');
    }
  }

  /// Clear all garments (optional)
  void clearGarments() {
    _garments.clear();
    notifyListeners();
  }
}
