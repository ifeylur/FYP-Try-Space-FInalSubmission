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

      // Check if file exists
      if (!await file.exists()) {
        debugPrint('File does not exist: ${file.path}');
        return null;
      }

      // Create a unique filename with timestamp
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final destination = '$folder/$userId/$fileName';
      
      debugPrint('Uploading file to: $destination');
      
      // Upload the file with metadata
      final ref = _storage.ref().child(destination);
      
      // Determine content type based on file extension
      final fileExtension = path.extension(file.path).toLowerCase();
      String? contentType;
      if (fileExtension == '.jpg' || fileExtension == '.jpeg') {
        contentType = 'image/jpeg';
      } else if (fileExtension == '.png') {
        contentType = 'image/png';
      } else if (fileExtension == '.gif') {
        contentType = 'image/gif';
      }
      
      final metadata = SettableMetadata(
        contentType: contentType,
        cacheControl: 'public, max-age=31536000',
      );
      
      final uploadTask = ref.putFile(file, metadata);
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        debugPrint('Upload progress: ${progress.toStringAsFixed(1)}%');
      });
      
      // Wait for upload to complete and check for errors
      final snapshot = await uploadTask;
      
      if (snapshot.state == TaskState.success) {
        // Get download URL
        final downloadUrl = await snapshot.ref.getDownloadURL();
        debugPrint('File uploaded successfully: $downloadUrl');
        return downloadUrl;
      } else {
        debugPrint('Upload failed with state: ${snapshot.state}');
        return null;
      }
    } on FirebaseException catch (e) {
      debugPrint('Firebase Storage error: ${e.code} - ${e.message}');
      if (e.code == 'object-not-found') {
        debugPrint('Storage bucket or path does not exist. Check Firebase Storage configuration.');
      } else if (e.code == 'unauthorized') {
        debugPrint('Unauthorized: Check Firebase Storage security rules.');
      } else if (e.code == 'canceled') {
        debugPrint('Upload was canceled.');
      }
      return null;
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