import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:provider/provider.dart';
import 'package:try_space/Providers/UserProvider.dart';
import 'package:try_space/Utilities/StorageHelper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({Key? key}) : super(key: key);

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final StorageHelper _storageHelper = StorageHelper();

  File? _selectedImage;
  String? _imageUrl;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _nameController.text = userProvider.user?.name ?? '';
    _bioController.text = userProvider.user?.bio ?? '';
    _imageUrl = userProvider.user?.profileImageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _showImageSourceBottomSheet() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_imageUrl != null || _selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                      _imageUrl = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Request permissions
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission is required')),
          );
          return;
        }
      } else {
        final status = await Permission.photos.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo library permission is required')),
          );
          return;
        }
      }

      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (picked != null) {
        setState(() {
          _isUploadingImage = true;
        });

        final file = File(picked.path);
        final compressed = await _compressAndCropImage(file);

        setState(() {
          _selectedImage = compressed;
          _isUploadingImage = false;
        });
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<File> _compressAndCropImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      
      // Compress to max 500KB
      Uint8List compressed = await FlutterImageCompress.compressWithList(
        bytes,
        minHeight: 500,
        minWidth: 500,
        quality: 85,
        format: CompressFormat.jpeg,
      );

      // Keep compressing until under 500KB
      int quality = 85;
      while (compressed.length > 500 * 1024 && quality > 30) {
        quality -= 10;
        compressed = await FlutterImageCompress.compressWithList(
          bytes,
          minHeight: 500,
          minWidth: 500,
          quality: quality,
          format: CompressFormat.jpeg,
        );
      }

      // Save compressed image to temp file
      final tempDir = file.parent;
      final tempFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(compressed);
      
      return tempFile;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return file;
    }
  }

  Future<String?> _uploadImageToFirebase(File imageFile) async {
    try {
      // Ensure file exists
      if (!await imageFile.exists()) {
        debugPrint('Image file does not exist: ${imageFile.path}');
        return null;
      }

      final url = await _storageHelper.uploadFile(imageFile, 'profile_images');
      
      if (url == null) {
        // Fallback: Use base64 encoding if Firebase Storage fails
        debugPrint('Firebase Storage upload failed, falling back to base64 encoding');
        final bytes = await imageFile.readAsBytes();
        final base64String = base64Encode(bytes);
        return base64String;
      }
      
      return url;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      // Fallback: Use base64 encoding
      try {
        final bytes = await imageFile.readAsBytes();
        final base64String = base64Encode(bytes);
        return base64String;
      } catch (e2) {
        debugPrint('Error encoding to base64: $e2');
        return null;
      }
    }
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();
    final bio = _bioController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    if (bio.length > 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bio must be 200 characters or less')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final provider = Provider.of<UserProvider>(context, listen: false);
      String? finalImageUrl = _imageUrl;

      // Upload new image if selected
      if (_selectedImage != null) {
        final uploadedUrl = await _uploadImageToFirebase(_selectedImage!);
        if (uploadedUrl != null) {
          finalImageUrl = uploadedUrl;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to upload image. Please check your internet connection and try again.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
          throw Exception('Failed to upload image. Please try again.');
        }
      }

      await provider.updateUserProfile(
        name: name,
        profileImageUrl: finalImageUrl ?? '',
        bio: bio,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = [Color(0xFFFF5F6D), Color(0xFFFFC371)];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
          ),
        ),
        leading: const BackButton(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              GestureDetector(
                onTap: _showImageSourceBottomSheet,
                child: Stack(
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _isUploadingImage
                            ? const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              )
                            : _selectedImage != null
                                ? Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                  )
                                : _imageUrl != null && _imageUrl!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: _imageUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const Center(
                                          child: CircularProgressIndicator(color: Colors.white),
                                        ),
                                        errorWidget: (context, url, error) => const Icon(
                                          Icons.person,
                                          size: 80,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Container(
                                        color: Colors.white.withOpacity(0.3),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 60,
                                          color: Colors.white,
                                        ),
                                      ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Color(0xFFFF5F6D),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white, width: 2),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              Consumer<UserProvider>(
                builder: (context, userProvider, _) {
                  return TextField(
                    controller: _bioController,
                    maxLength: 200,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Bio (Optional)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white, width: 2),
                      ),
                      counterStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                    style: const TextStyle(color: Colors.white),
                  );
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5F6D)),
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Color(0xFFFF5F6D),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
