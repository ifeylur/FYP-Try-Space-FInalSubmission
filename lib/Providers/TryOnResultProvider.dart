import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:try_space/Models/TryOnResultModel.dart';

class TryOnResultProvider with ChangeNotifier {
  final List<TryOnResultModel> _allResults = [];
  final List<TryOnResultModel> _userResults = [];

  List<TryOnResultModel> get allResults => _allResults;
  List<TryOnResultModel> get userResults => _userResults;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper function to split base64 string into chunks
  List<String> splitIntoChunks(String base64Image, int chunkSize) {
    List<String> chunks = [];
    for (int i = 0; i < base64Image.length; i += chunkSize) {
      int end = (i + chunkSize < base64Image.length) 
          ? i + chunkSize 
          : base64Image.length;
      chunks.add(base64Image.substring(i, end));
    }
    return chunks;
  }

  /// Fetch all try-on results (for admin or public view)
  Future<void> fetchAllResults() async {
    try {
      // Create a composite index in Firebase console for this query
      final snapshot = await _firestore
          .collection('tryon_results')
          .orderBy('createdAt', descending: true)
          .get();

      _allResults.clear();
      for (var doc in snapshot.docs) {
        _allResults.add(
          TryOnResultModel.fromMap({...doc.data(), 'id': doc.id}),
        );
      }
      notifyListeners();
    } catch (e) {
      print("Error fetching all try-on results: $e");
      // Don't rethrow - handle gracefully
    }
  }

  Future<void> fetchUserResults() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print("User not authenticated when fetching results");
        return;
      }

      // Create a composite index in Firebase console for this query
      final snapshot = await _firestore
          .collection('tryon_results')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _userResults.clear();
      for (var doc in snapshot.docs) {
        _userResults.add(
          TryOnResultModel.fromMap({...doc.data(), 'id': doc.id}),
        );
      }
      notifyListeners();
    } catch (e) {
      print("Error fetching user try-on results: $e");
      // Handle specific error types
      if (e is FirebaseException) {
        if (e.code == 'permission-denied') {
          print("Permission denied error: Check your Firestore rules");
        } else if (e.code == 'failed-precondition') {
          print("Index error: You need to create an index for this query");
        }
      }
    }
  }

  /// Get a single try-on result by ID
  Future<TryOnResultModel?> getTryOnResultById(String id) async {
    try {
      final doc = await _firestore.collection('tryon_results').doc(id).get();

      if (doc.exists) {
        return TryOnResultModel.fromMap({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      print("Error getting try-on result: $e");
      return null; // Return null instead of rethrowing
    }
  }

  /// Delete a try-on result
  Future<void> deleteTryOnResult(String id) async {
    try {
      await _firestore.collection('tryon_results').doc(id).delete();
      await fetchUserResults();
      await fetchAllResults();
    } catch (e) {
      print("Error deleting try-on result: $e");
      // Don't rethrow - handle gracefully
    }
  }

  /// Post a try-on result with chunking for large images
  Future<void> postTryOnResult(TryOnResultModel result) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print("User not authenticated when posting result");
        throw Exception("User not authenticated");
      }
      
      print('Current user UID: ${currentUser.uid}');
      final String base64Image = result.resultImage;

      // Check if we need to chunk the image (>500KB to be safe)
      if (base64Image.length > 500000) {
        // Define chunk size (400KB is safer for Firestore)
        const int chunkSize = 400000;

        // Split the image into chunks
        final List<String> chunks = splitIntoChunks(base64Image, chunkSize);

        // First chunk goes in resultImage, rest in imageChunks
        final String firstChunk = chunks.first;
        final List<String> remainingChunks = chunks.sublist(1);

        // Create updated model with chunked image
        final chunkedResult = TryOnResultModel(
          id: result.id,
          resultImage: firstChunk,
          imageChunks: remainingChunks,
          userId: result.userId,
          title: result.title,
          isChunked: true,
        );

        // Store in Firestore - ADDING .doc(result.id) to use the UUID as document ID
        await _firestore.collection('tryon_results').doc(result.id).set({
          ...chunkedResult.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        print("Large image stored in ${chunks.length} chunks");
      } else {
        // Store normally if small enough - ADDING .doc(result.id) to use the UUID as document ID
        await _firestore.collection('tryon_results').doc(result.id).set({
          ...result.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        print("Small image stored without chunking");
      }

      await fetchUserResults();
      await fetchAllResults();
    } catch (e) {
      print("Error posting try-on result: $e");
      throw Exception("Failed to save result: $e"); // Rethrow for UI feedback
    }
  }

  
}