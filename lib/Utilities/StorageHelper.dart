import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:try_space/Utilities/Auth.dart';

class StorageHelper {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Auth _auth = Auth();
  
  // Upload a file to Firebase Storage and return the download URL
  Future<String?> uploadFile(File file, String folder) async {
    try {
      final userId = _auth.getCurrentUserId();
      if (userId == null) {
        debugPrint('No user logged in');
        return null;
      }
      
      // Create a unique filename with timestamp
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final destination = '$folder/$userId/$fileName';
      
      // Upload the file
      final ref = _storage.ref().child(destination);
      final uploadTask = ref.putFile(file);
      
      // Wait for upload to complete
      final snapshot = await uploadTask.whenComplete(() {});
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }
  
  // Delete a file from Firebase Storage
  Future<bool> deleteFile(String url) async {
    try {
      // Get reference from URL
      final ref = _storage.refFromURL(url);
      
      // Delete the file
      await ref.delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }
}