import 'package:flutter/material.dart';
import 'dart:io';
import 'package:try_space/Services/VirtualTryOnService.dart';

class VirtualTryOnProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _resultImage;
  String? _errorMessage;

  final VirtualTryOnService _service = VirtualTryOnService();

  bool get isLoading => _isLoading;
  String? get resultImage => _resultImage;
  String? get errorMessage => _errorMessage;

  /// UPDATED: Added garmentCategory parameter
  Future<void> generateTryOn(
    File personImage, 
    File garmentImage,
    {String garmentCategory = 'upper'} // NEW PARAMETER
  ) async {
    _isLoading = true;
    _resultImage = null;
    _errorMessage = null;
    notifyListeners();

    try {
      // Call the service with garment category
      final result = await _service.generateTryOn(
        personImage, 
        garmentImage,
        garmentCategory: garmentCategory, // Pass category
      );
      
      _resultImage = result;
      _errorMessage = null;
    } catch (e) {
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      
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
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearResult() {
    _resultImage = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  void reset() {
    _isLoading = false;
    _resultImage = null;
    _errorMessage = null;
    notifyListeners();
  }
}