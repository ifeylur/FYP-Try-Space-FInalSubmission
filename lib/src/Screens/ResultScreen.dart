import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:try_space/Models/TryOnResultModel.dart';
import 'package:try_space/Providers/TryOnResultProvider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';

class ResultScreen extends StatefulWidget {
  final File? userImage;
  final File? garmentImage;
  final String? resultImageBase64;
  final String? resultId; // ID of the saved result (if available)

  const ResultScreen({
    Key? key,
    this.userImage,
    this.garmentImage,
    this.resultImageBase64,
    this.resultId,
  }) : super(key: key);

  @override
  _ResultScreenState createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final GlobalKey _resultKey = GlobalKey();
  bool _isSaving = false;
  String _errorMessage = '';

  // Define the gradient colors (same as in HomePage)
  final List<Color> gradientColors = const [
    Color(0xFFFF5F6D),
    Color(0xFFFFC371),
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Try-On Result',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Show delete button only if this is a saved result (has resultId)
          if (widget.resultId != null && widget.resultId!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: _confirmDelete,
              tooltip: 'Delete Result',
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Image Display Section
              Container(
                height: MediaQuery.of(context).size.height * 0.45, // 45% of screen height instead of fixed 400
                margin: const EdgeInsets.all(16), // Reduced from 20
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: RepaintBoundary(
                    key: _resultKey,
                    child: widget.resultImageBase64 != null
                            ? Image.memory(
                                base64Decode(widget.resultImageBase64!),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback to overlay if base64 decode fails
                                  if (widget.userImage != null && widget.garmentImage != null) {
                                    return Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Image.file(
                                          widget.userImage!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                        Opacity(
                                          opacity: 0.7,
                                          child: Image.file(
                                            widget.garmentImage!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          ),
                                        ),
                                      ],
                                    );
                                  } else {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                      ),
                                    );
                                  }
                                },
                              )
                            : widget.userImage != null && widget.garmentImage != null
                                ? Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Image.file(
                                        widget.userImage!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                      Opacity(
                                        opacity: 0.7,
                                        child: Image.file(
                                          widget.garmentImage!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                      ),
                                    ],
                                  )
                                : Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: Icon(Icons.image, size: 50, color: Colors.grey),
                                    ),
                                  ),
                  ),
                ),
              ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              
              Padding(
                padding: const EdgeInsets.all(16), // Reduced from 20
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveToGallery,
                        icon: const Icon(Icons.save_alt, color: Colors.white),
                        label: const Text(
                          'Save to Gallery',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor: gradientColors[0],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveResultToFirestore,
                        icon: const Icon(Icons.cloud_upload, color: Colors.white),
                        label: const Text(
                          'Save to Cloud',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor: gradientColors[1],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveToGallery() async {
    setState(() {
      _isSaving = true;
      _errorMessage = '';
    });

    try {
      // Request permissions - Simplified and more reliable approach
      bool hasPermission = false;
      PermissionStatus? permissionStatus;
      
      // Show message that we're requesting permission
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Requesting permission to save image...'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      
      if (Platform.isAndroid) {
        // For Android, try photos permission first (Android 13+), then storage
        permissionStatus = await Permission.photos.request();
        
        if (permissionStatus.isGranted) {
          hasPermission = true;
        } else if (permissionStatus.isDenied) {
          // If photos permission is denied, try storage permission (for older Android)
          permissionStatus = await Permission.storage.request();
          if (permissionStatus.isGranted) {
            hasPermission = true;
          }
        } else if (permissionStatus.isPermanentlyDenied) {
          // Permission permanently denied - show dialog to open settings
          if (mounted) {
            final shouldOpenSettings = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Permission Required'),
                content: const Text(
                  'Storage permission is required to save images to gallery. '
                  'Please enable it in app settings.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Open Settings'),
                  ),
                ],
              ),
            );
            
            if (shouldOpenSettings == true) {
              await openAppSettings();
              // After opening settings, check again
              await Future.delayed(const Duration(seconds: 1));
              final newStatus = await Permission.photos.status;
              if (newStatus.isGranted) {
                hasPermission = true;
              } else {
                final storageStatus = await Permission.storage.status;
                if (storageStatus.isGranted) {
                  hasPermission = true;
                }
              }
            }
          }
        }
      } else if (Platform.isIOS) {
        // iOS uses photos permission
        permissionStatus = await Permission.photos.request();
        if (permissionStatus.isGranted) {
          hasPermission = true;
        } else if (permissionStatus.isPermanentlyDenied) {
          // Permission permanently denied - show dialog to open settings
          if (mounted) {
            final shouldOpenSettings = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Permission Required'),
                content: const Text(
                  'Photo library permission is required to save images. '
                  'Please enable it in app settings.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Open Settings'),
                  ),
                ],
              ),
            );
            
            if (shouldOpenSettings == true) {
              await openAppSettings();
              // After opening settings, check again
              await Future.delayed(const Duration(seconds: 1));
              final newStatus = await Permission.photos.status;
              if (newStatus.isGranted) {
                hasPermission = true;
              }
            }
          }
        }
      }

      if (!hasPermission) {
        setState(() {
          _errorMessage = permissionStatus?.isPermanentlyDenied == true
              ? 'Permission permanently denied. Please enable in settings.'
              : 'Permission denied to save image. Please grant permission when prompted.';
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              permissionStatus?.isPermanentlyDenied == true
                  ? 'Please enable permission in app settings'
                  : 'Permission denied. Please grant permission when prompted.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: permissionStatus?.isPermanentlyDenied == true
                ? SnackBarAction(
                    label: 'Settings',
                    textColor: Colors.white,
                    onPressed: () => openAppSettings(),
                  )
                : null,
          ),
        );
        return;
      }

      // Get base64 image
      String? base64Image;
      if (widget.resultImageBase64 != null) {
        base64Image = widget.resultImageBase64;
      } else {
        base64Image = await _captureResultAsBase64();
      }

      if (base64Image == null || base64Image.isEmpty) {
        setState(() {
          _errorMessage = 'Failed to get image data';
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to get image data'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Decode base64 to bytes
      final imageBytes = base64Decode(base64Image);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'tryon_result_$timestamp';

      // Save to gallery using saver_gallery package
      final result = await SaverGallery.saveImage(
        imageBytes,
        fileName: fileName,
        quality: 100,
        androidRelativePath: "Pictures/Try-Space",
        skipIfExists: false,
      );

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image saved to gallery successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception(result.errorMessage ?? 'Failed to save image to gallery');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _saveResultToFirestore() async {
    setState(() {
      _isSaving = true;
      _errorMessage = '';
    });

    try {
      // Check authentication first
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _errorMessage = 'User not authenticated. Please log in again.';
          _isSaving = false;
        });
        return;
      }

      // Capture the result image as Base64
      String? base64Image = await _captureResultAsBase64();

      if (base64Image != null) {
        // Generate a unique ID
        final resultId = const Uuid().v4();
        
        // Create TryOnResult object with the generated ID
        final result = TryOnResultModel(
          id: resultId,
          resultImage: base64Image,
          userId: userId,
          title: 'Try-On Result',
        );

        // Save to Firestore using provider
        await Provider.of<TryOnResultProvider>(
          context,
          listen: false,
        ).postTryOnResult(result);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Result saved successfully!')),
        );

        // Navigate back to home page
        Navigator.of(context).pop();
      } else {
        setState(() {
          _errorMessage = 'Failed to capture result image';
          _isSaving = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isSaving = false;
      });
      
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving result: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<String?> _captureResultAsBase64() async {
    try {
      // If resultImageBase64 is provided, use it directly
      if (widget.resultImageBase64 != null) {
        return widget.resultImageBase64;
      }

      // Otherwise, capture from the widget
      // Find the RenderRepaintBoundary
      RenderRepaintBoundary? boundary =
          _resultKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // Capture image with a lower pixel ratio for smaller file size
      ui.Image image = await boundary.toImage(pixelRatio: 0.7); // Lower pixel ratio

      // Get PNG bytes with lower quality
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      
      if (byteData == null) return null;

      // Convert to Uint8List
      Uint8List pngBytes = byteData.buffer.asUint8List();
      
      // Compress the image further before base64 encoding
      Uint8List compressedBytes = await _compressImage(pngBytes);
      
      // Convert to Base64
      String base64Image = base64Encode(compressedBytes);
      
      return base64Image;
    } catch (e) {
      print('Error capturing image: $e');
      return null;
    }
  }
  
  // Add this method to compress the image bytes further
  Future<Uint8List> _compressImage(Uint8List bytes) async {
    // If you have flutter_image_compress package:
    try {
      // You'll need to add flutter_image_compress package
      // For now, we'll just return the original bytes
      // In a real app, use:
      // return await FlutterImageCompress.compressWithList(
      //   bytes,
      //   quality: 70,
      //   format: CompressFormat.jpeg,
      // );
      
      // Simulate compression by returning original bytes
      return bytes;
    } catch (e) {
      print('Error compressing image: $e');
      return bytes; // Return original if compression fails
    }
  }


  /// Confirm and delete the result from Firestore and recents
  Future<void> _confirmDelete() async {
    if (widget.resultId == null || widget.resultId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete: Result ID not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Try-On Result'),
        content: const Text(
          'Are you sure you want to delete this try-on result? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() {
          _isSaving = true;
        });

        // Delete from Firestore using provider
        await Provider.of<TryOnResultProvider>(
          context,
          listen: false,
        ).deleteTryOnResult(widget.resultId!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Result deleted successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Navigate back to previous screen
          Navigator.of(context).pop(true); // Return true to indicate deletion
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete result: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
}