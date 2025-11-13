import 'package:flutter/material.dart';
import 'dart:io';
import 'package:try_space/Services/VirtualTryOnService.dart';

class VirtualTryOnProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _resultImage;
  String? _errorMessage;

  final VirtualTryOnService _service = VirtualTryOnService();

  // Getters
  bool get isLoading => _isLoading;
  String? get resultImage => _resultImage;
  String? get errorMessage => _errorMessage;

  /// Generates a virtual try-on result using the provided images
  /// 
  /// [personImage] - File containing the person's image
  /// [garmentImage] - File containing the garment image
  /// 
  /// Updates the loading state, result image, and error message accordingly
  Future<void> generateTryOn(File personImage, File garmentImage) async {
    // Reset state
    _isLoading = true;
    _resultImage = null;
    _errorMessage = null;
    notifyListeners();

    try {
      // Call the service to generate try-on result
      final result = await _service.generateTryOn(personImage, garmentImage);
      
      // Update result image
      _resultImage = result;
      _errorMessage = null;
    } catch (e) {
      // Handle errors with better messages
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      
      // Provide user-friendly error messages
      if (errorMsg.contains('500') || errorMsg.contains('API error')) {
        errorMsg = 'Server error. Please try again in a moment. The API may be processing another request.';
      } else if (errorMsg.contains('timeout')) {
        errorMsg = 'Request timed out. Processing takes 2-3 minutes. Please try again.';
      } else if (errorMsg.contains('Network') || errorMsg.contains('Socket')) {
        errorMsg = 'Network error. Please check your internet connection and try again.';
      } else if (errorMsg.contains('All API approaches failed')) {
        errorMsg = 'Unable to connect to the API. Please check your connection and try again.';
      }
      
      _errorMessage = errorMsg;
      _resultImage = null;
      print('❌ Error generating try-on: $e');
    } finally {
      // Update loading state
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears the current result and error state
  void clearResult() {
    _resultImage = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Resets the provider to its initial state
  void reset() {
    _isLoading = false;
    _resultImage = null;
    _errorMessage = null;
    notifyListeners();
  }
}

