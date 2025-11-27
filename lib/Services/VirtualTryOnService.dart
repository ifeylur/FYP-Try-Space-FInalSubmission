import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class VirtualTryOnService {
  static const String _baseUrl = 'https://feylur-try-space-project.hf.space';
  static const Duration _timeout = Duration(seconds: 240);
  static const int _maxRetries = 3;
  static const int _maxImageSize = 512;
  static const int _jpegQuality = 70;
  
  Future<Map<String, dynamic>?> _getApiInfo() async {
    try {
      final endpoints = [
        '$_baseUrl/api/',
        '$_baseUrl/api/info',
        '$_baseUrl/api_info',
      ];
      
      for (final endpoint in endpoints) {
        try {
          final response = await http
              .get(Uri.parse(endpoint))
              .timeout(const Duration(seconds: 10));
          
          if (response.statusCode == 200) {
            final apiInfo = jsonDecode(response.body) as Map<String, dynamic>;
            print('✅ API Info retrieved from $endpoint');
            return apiInfo;
          }
        } catch (e) {
          continue;
        }
      }
      
      print('⚠️ Could not get API info, using default fn_index: 0');
    } catch (e) {
      print('⚠️ Failed to get API info: $e');
    }
    return null;
  }
  
  int? _getFnIndexForNamedEndpoint(Map<String, dynamic>? apiInfo, String endpointName) {
    if (apiInfo == null) return null;
    
    if (apiInfo.containsKey('named_endpoints')) {
      final namedEndpoints = apiInfo['named_endpoints'] as Map<String, dynamic>?;
      if (namedEndpoints != null) {
        final keys = namedEndpoints.keys.toList();
        for (final key in keys) {
          if (key == endpointName || key == endpointName.replaceFirst('/', '') || 
              key == '/$endpointName' || key.contains('generate_tryon')) {
            final index = namedEndpoints[key];
            if (index is int) {
              print('✅ Found fn_index for $endpointName: $index');
              return index;
            }
          }
        }
      }
    }
    
    return null;
  }
  
  int _getFnIndex(Map<String, dynamic>? apiInfo) {
    if (apiInfo == null) return 0;
    
    if (apiInfo.containsKey('named_endpoints')) {
      final namedEndpoints = apiInfo['named_endpoints'] as Map<String, dynamic>?;
      if (namedEndpoints != null && namedEndpoints.containsKey('predict')) {
        return namedEndpoints['predict'] as int? ?? 0;
      }
    }
    
    if (apiInfo.containsKey('unnamed_endpoints')) {
      final unnamedEndpoints = apiInfo['unnamed_endpoints'] as Map<String, dynamic>?;
      if (unnamedEndpoints != null && unnamedEndpoints.isNotEmpty) {
        return 0;
      }
    }
    
    return 0;
  }

  Future<String?> _uploadFile(Uint8List imageBytes, String filename, String mimeType) async {
    try {
      print('📤 Uploading file: $filename (${(imageBytes.length / 1024).toStringAsFixed(1)} KB)');
      
      final uploadEndpoints = [
        '$_baseUrl/upload',
        '$_baseUrl/api/upload',
        '$_baseUrl/file/upload',
      ];
      
      for (final endpoint in uploadEndpoints) {
        try {
          var request = http.MultipartRequest(
            'POST',
            Uri.parse(endpoint),
          );
          
          request.files.add(http.MultipartFile.fromBytes(
            'files',
            imageBytes,
            filename: filename,
            contentType: MediaType.parse(mimeType),
          ));
          
          final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
          final responseBody = await streamedResponse.stream.bytesToString();
          
          if (streamedResponse.statusCode == 200) {
            final json = jsonDecode(responseBody);
            if (json is List && json.isNotEmpty) {
              final filePath = json[0] as String;
              print('✅ File uploaded successfully to: $filePath');
              return filePath;
            } else if (json is Map && json.containsKey('path')) {
              final filePath = json['path'] as String;
              print('✅ File uploaded successfully to: $filePath');
              return filePath;
            }
          }
        } catch (e) {
          continue;
        }
      }
      
      print('❌ All upload endpoints failed');
      return null;
    } catch (e) {
      print('❌ File upload failed: $e');
      return null;
    }
  }

  Future<Uint8List> _compressImage(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final originalSize = imageBytes.length;
      
      final isPng = imageFile.path.toLowerCase().endsWith('.png');
      
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: _maxImageSize,
        minHeight: _maxImageSize,
        quality: _jpegQuality,
        format: isPng ? CompressFormat.png : CompressFormat.jpeg,
      );
      
      if (compressedBytes != null && compressedBytes.isNotEmpty) {
        final compressedSize = compressedBytes.length;
        final reduction = ((1 - compressedSize / originalSize) * 100).toStringAsFixed(1);
        print('📦 Image compression: ${(originalSize / 1024).toStringAsFixed(1)} KB -> ${(compressedSize / 1024).toStringAsFixed(1)} KB (${reduction}% reduction)');
        return compressedBytes;
      } else {
        print('⚠️ Compression returned null, using original image');
        return imageBytes;
      }
    } catch (e) {
      print('⚠️ Image compression failed: $e, using original image');
      return await imageFile.readAsBytes();
    }
  }

  /// UPDATED: Added garmentCategory parameter
  Future<String> generateTryOn(
    File personImage, 
    File garmentImage,
    {String garmentCategory = 'upper'} // NEW PARAMETER
  ) async {
    Exception? lastException;
    
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        if (attempt > 1) {
          print('🔄 Retry attempt $attempt of $_maxRetries');
          await Future.delayed(Duration(seconds: attempt * 2));
        }
        
        return await _generateTryOnAttempt(personImage, garmentImage, garmentCategory, attempt);
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        print('❌ Attempt $attempt failed: $e');
        
        if (e.toString().contains('timeout') || 
            e.toString().contains('Network error') ||
            e.toString().contains('500')) {
          if (attempt < _maxRetries) {
            print('🔄 Retrying due to timeout/network/server error...');
            continue;
          }
        }
        
        if (attempt < _maxRetries && e.toString().contains('500')) {
          continue;
        } else {
          rethrow;
        }
      }
    }
    
    throw lastException ?? Exception('All retry attempts failed');
  }

  /// UPDATED: Added garmentCategory parameter
  Future<String> _generateTryOnAttempt(
    File personImage, 
    File garmentImage, 
    String garmentCategory, // NEW PARAMETER
    int attempt
  ) async {
    try {
      print('🚀 Starting virtual try-on (attempt $attempt) with category: $garmentCategory');
      
      print('📦 Compressing images to reduce payload size...');
      final personBytes = await _compressImage(personImage);
      final garmentBytes = await _compressImage(garmentImage);

      print('📊 Person image: ${(personBytes.length / 1024).toStringAsFixed(1)} KB');
      print('📊 Garment image: ${(garmentBytes.length / 1024).toStringAsFixed(1)} KB');
      
      final personBase64 = base64Encode(personBytes);
      final garmentBase64 = base64Encode(garmentBytes);
      
      String personMimeType = 'image/jpeg';
      String garmentMimeType = 'image/jpeg';
      String personFileName = 'person.jpg';
      String garmentFileName = 'garment.jpg';
      
      if (personImage.path.toLowerCase().endsWith('.png')) {
        personMimeType = 'image/png';
        personFileName = 'person.png';
      }
      if (garmentImage.path.toLowerCase().endsWith('.png')) {
        garmentMimeType = 'image/png';
        garmentFileName = 'garment.png';
      }

      print('🔍 Getting API info...');
      final apiInfo = await _getApiInfo();
      final generateTryOnFnIndex = _getFnIndexForNamedEndpoint(apiInfo, '/generate_tryon');
      final defaultFnIndex = _getFnIndex(apiInfo);
      final fnIndex = generateTryOnFnIndex ?? defaultFnIndex;
      print('📌 Using fn_index: $fnIndex');

      final random = Random();
      const chars = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
      final sessionHash = List.generate(11, (_) => chars[random.nextInt(chars.length)]).join();

      print('\n=== Uploading files and sending in FileData format ===');
      
      final personPath = await _uploadFile(personBytes, personFileName, personMimeType);
      final garmentPath = await _uploadFile(garmentBytes, garmentFileName, garmentMimeType);
      
      if (personPath == null || garmentPath == null) {
        throw Exception('Failed to upload files to the server');
      }
      
      print('✅ Files uploaded successfully');
      print('📁 Person file: $personPath');
      print('📁 Garment file: $garmentPath');
      
      final personFileData = <String, dynamic>{
        'path': personPath,
        'url': null,
        'size': null,
        'orig_name': personFileName,
        'mime_type': personMimeType,
        'is_stream': false,
        'meta': <String, dynamic>{'_type': 'gradio.FileData'},
      };
      
      final garmentFileData = <String, dynamic>{
        'path': garmentPath,
        'url': null,
        'size': null,
        'orig_name': garmentFileName,
        'mime_type': garmentMimeType,
        'is_stream': false,
        'meta': <String, dynamic>{'_type': 'gradio.FileData'},
      };
      
      print('📤 Sending request to API with category: $garmentCategory');
      
      // CRITICAL FIX: Add garmentCategory as third parameter
      final requestBody = <String, dynamic>{
        'data': [
          personFileData, 
          garmentFileData, 
          garmentCategory // NEW: Third parameter matches Gradio interface
        ],
        'fn_index': fnIndex,
        'session_hash': sessionHash,
      };
      
      final response = await _makePredictRequest('$_baseUrl/api/predict', requestBody);
      
      if (response == null) {
        throw Exception('Failed to get response from API');
      }
      
      if (response.statusCode == 200) {
        final result = await _parseResponse(response);
        if (result.isNotEmpty) {
          print('✅✅✅ Success! Try-on result generated');
          return result;
        } else {
          throw Exception('Received empty result from API');
        }
      } else {
        final errorBody = response.body.length > 1000 ? response.body.substring(0, 1000) : response.body;
        print('❌ API returned error: ${response.statusCode}');
        print('Error details: $errorBody');
        throw Exception('API error: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Error in API call attempt: $e');
    }
  }

  Future<http.Response?> _makePredictRequest(String endpoint, Map<String, dynamic> requestBody) async {
    try {
      print('📡 Making request to: $endpoint');
      print('📋 Fn_index: ${requestBody['fn_index']}, Session_hash: ${requestBody['session_hash']}');
      
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(_timeout);
      
      print('📥 Response status: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        final errorPreview = response.body.length > 500 ? response.body.substring(0, 500) : response.body;
        print('❌ Error response: $errorPreview');
        
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map<String, dynamic> && errorData.containsKey('error')) {
            throw Exception('API Error: ${errorData['error']}');
          }
        } catch (_) {}
      } else {
        print('✅ Request successful (${response.body.length} bytes)');
      }
      
      return response;
    } catch (e) {
      if (e.toString().contains('TimeoutException') || e.toString().contains('timeout')) {
        print('❌ Request timed out after ${_timeout.inSeconds} seconds');
        throw Exception('Request timed out. The processing may take 2-3 minutes. Please try again.');
      }
      print('❌ Request failed: $e');
      rethrow;
    }
  }

  Future<String> _fetchImageFromUrl(String url) async {
    try {
      print('🌐 Fetching image from URL: $url');
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final imageBytes = response.bodyBytes;
        final base64String = base64Encode(imageBytes);
        print('✅ Successfully fetched and encoded image (${base64String.length} chars)');
        return base64String;
      } else {
        throw Exception('Failed to fetch image: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching image from URL: $e');
      throw Exception('Failed to fetch image from URL: $e');
    }
  }

  Future<String> _parseResponse(http.Response response) async {
    try {
      print('🔍 Parsing response (${response.body.length} bytes)...');
      
      final responseData = jsonDecode(response.body);
      
      String? imageData;
      
      if (responseData is Map<String, dynamic>) {
        print('📦 Response is Map with keys: ${responseData.keys.toList()}');
        
        if (responseData.containsKey('data') && responseData['data'] is List) {
          final dataList = responseData['data'] as List;
          print('📋 Data list length: ${dataList.length}');
          
          if (dataList.isNotEmpty) {
            final firstItem = dataList[0];
            print('🔎 First item type: ${firstItem.runtimeType}');
            
            if (firstItem is Map<String, dynamic>) {
              print('📝 First item keys: ${firstItem.keys.toList()}');
              
              if (firstItem.containsKey('path')) {
                imageData = firstItem['path'] as String;
              } else if (firstItem.containsKey('url')) {
                imageData = firstItem['url'] as String?;
              }
            } 
            else if (firstItem is String) {
              print('📄 First item is String (${firstItem.length} chars)');
              imageData = firstItem;
            }
          }
        }
        else if (responseData.containsKey('path')) {
          imageData = responseData['path'] as String;
        } else if (responseData.containsKey('url')) {
          imageData = responseData['url'] as String?;
        }
        else if (responseData.containsKey('error')) {
          final error = responseData['error'];
          throw Exception('API returned error: $error');
        }
      } else if (responseData is List && responseData.isNotEmpty) {
        print('📋 Response is List with ${responseData.length} items');
        
        final firstItem = responseData[0];
        if (firstItem is Map<String, dynamic>) {
          if (firstItem.containsKey('path')) {
            imageData = firstItem['path'] as String;
          } else if (firstItem.containsKey('url')) {
            imageData = firstItem['url'] as String?;
          }
        } else if (firstItem is String) {
          imageData = firstItem;
        }
      }
      
      if (imageData == null || imageData.isEmpty) {
        print('❌ Could not extract image data from response');
        print('Response preview: ${response.body.substring(0, response.body.length > 1000 ? 1000 : response.body.length)}');
        throw Exception('Invalid response format: could not extract image data. Response type: ${responseData.runtimeType}');
      }
      
      print('✅ Found image data: ${imageData.substring(0, imageData.length > 100 ? 100 : imageData.length)}...');
      
      String resultImageBase64;
      
      if (imageData.startsWith('data:image')) {
        final parts = imageData.split(',');
        if (parts.length > 1) {
          resultImageBase64 = parts[1];
          print('✅ Extracted base64 from data URL (${resultImageBase64.length} chars)');
        } else {
          throw Exception('Invalid data URL format');
        }
      }
      else if (imageData.startsWith('http://') || imageData.startsWith('https://')) {
        print('🌐 Image data is a URL, fetching image...');
        resultImageBase64 = await _fetchImageFromUrl(imageData);
      }
      else if (imageData.startsWith('/')) {
        final fullUrl = '$_baseUrl/file=$imageData';
        print('🔗 Image data is relative path, constructing full URL: $fullUrl');
        resultImageBase64 = await _fetchImageFromUrl(fullUrl);
      }
      else {
        resultImageBase64 = imageData;
        print('📄 Using image data as base64 (${resultImageBase64.length} chars)');
      }
      
      if (resultImageBase64.isNotEmpty) {
        print('✅✅✅ Successfully extracted result image (${resultImageBase64.length} chars)');
        return resultImageBase64;
      } else {
        throw Exception('Failed to extract image data');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      print('❌ Error parsing response: $e');
      print('Response preview: ${response.body.substring(0, response.body.length > 1000 ? 1000 : response.body.length)}');
      throw Exception('Failed to parse API response: $e');
    }
  }
}