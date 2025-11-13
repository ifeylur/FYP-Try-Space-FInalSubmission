import 'package:cloud_firestore/cloud_firestore.dart';

class TryOnResultModel {
  final String id;
  final String resultImage; // Base64 image or first chunk
  final List<String> imageChunks; // Additional chunks if image is large
  final String userId;
  final String title;
  final bool isChunked; // Indicates if the image is split into chunks
  final DateTime? createdAt;

  TryOnResultModel({
    required this.id,
    required this.resultImage,
    this.imageChunks = const [],
    required this.userId,
    this.title = 'Try-On Result',
    this.isChunked = false,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'resultImage': resultImage,
      'imageChunks': imageChunks,
      'userId': userId,
      'title': title,
      'isChunked': isChunked,
      // Don't include id in the map as it will be the document ID
      // Don't include createdAt as it will be set by the server
    };
  }

  factory TryOnResultModel.fromMap(Map<String, dynamic> map) {
    // Handle timestamp conversion safely
    DateTime? createdAtDate;
    if (map['createdAt'] != null) {
      if (map['createdAt'] is Timestamp) {
        createdAtDate = (map['createdAt'] as Timestamp).toDate();
      }
    }
    
    return TryOnResultModel(
      id: map['id'],
      resultImage: map['resultImage'] ?? '',
      imageChunks: map['imageChunks'] != null
          ? List<String>.from(map['imageChunks'])
          : [],
      userId: map['userId'] ?? '',
      title: map['title'] ?? 'Try-On Result',
      isChunked: map['isChunked'] ?? false,
      createdAt: createdAtDate,
    );
  }
  
  // Helper method to get the complete image
  String getCompleteImage() {
    if (!isChunked || imageChunks.isEmpty) return resultImage;
    
    try {
      return resultImage + imageChunks.join();
    } catch (e) {
      print("Error combining image chunks: $e");
      return resultImage; // Return at least the first chunk if there's an error
    }
  }
}