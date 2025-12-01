import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Submit feedback from user
  Future<bool> submitFeedback({
    required String message,
    int? rating,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get user email
      final userEmail = user.email ?? 'Unknown';

      // Create feedback document
      await _firestore.collection('feedback').add({
        'userId': user.uid,
        'userEmail': userEmail,
        'message': message,
        'rating': rating,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      return true;
    } catch (e) {
      print('Error submitting feedback: $e');
      return false;
    }
  }
}

