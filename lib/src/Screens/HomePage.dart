import 'package:flutter/material.dart';
import 'dart:io' show File;
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:try_space/src/Screens/ResultScreen.dart';
import 'package:provider/provider.dart';
import 'package:try_space/Providers/TryOnResultProvider.dart';
import 'package:try_space/Providers/VirtualTryOnProvider.dart';
import 'package:try_space/Models/TryOnResultModel.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();
  File? _userImage;
  File? _garmentImage;
  bool _isLoading = true;
  int _currentIndex = 0;

  // Define the gradient colors
  final List<Color> gradientColors = const [
    Color(0xFFFF5F6D),
    Color(0xFFFFC371),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserResults();
  }

  Future<void> _loadUserResults() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await Provider.of<TryOnResultProvider>(context, listen: false).fetchUserResults();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load results: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectUserImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? photo = await _picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (photo != null) {
                    setState(() {
                      _userImage = File(photo.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null) {
                    setState(() {
                      _userImage = File(image.path);
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectGarmentImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? photo = await _picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (photo != null) {
                    setState(() {
                      _garmentImage = File(photo.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null) {
                    setState(() {
                      _garmentImage = File(image.path);
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processImages() async {
    if (_userImage == null || _garmentImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both images first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get the VirtualTryOnProvider
    final virtualTryOnProvider = Provider.of<VirtualTryOnProvider>(context, listen: false);
    
    // Clear any previous errors
    virtualTryOnProvider.clearResult();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing during processing
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                const Text(
                  'Processing...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'This may take 2-3 minutes',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Please wait...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Call the provider to generate try-on
      await virtualTryOnProvider.generateTryOn(_userImage!, _garmentImage!);

      // Dismiss loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Check for errors
      if (virtualTryOnProvider.errorMessage != null) {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(virtualTryOnProvider.errorMessage!),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Check if result is available
      if (virtualTryOnProvider.resultImage != null && mounted) {
        // Convert base64 to Uint8List for display
        final imageBytes = base64Decode(virtualTryOnProvider.resultImage!);
        
        // Navigate to result screen with the result image
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              userImage: _userImage!,
              garmentImage: _garmentImage!,
              resultImageBase64: virtualTryOnProvider.resultImage!,
            ),
          ),
        ).then((_) {
          // Refresh results when returning from the ResultScreen
          _loadUserResults();
          // Clear the result from provider
          virtualTryOnProvider.clearResult();
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No result received from API'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Dismiss loading dialog if still showing
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Function to save image to gallery
  Future<void> _saveToGallery(String base64Image, String title) async {
    try {
      // Check if permission is granted
      final status = await Permission.storage.request();
      
      if (status.isGranted) {
        // Convert base64 to bytes
        // final Uint8List bytes = base64Decode(base64Image);
        
        // Save to gallery
        // final result = await ImageGallerySaver.saveImage(
        //   bytes,
        //   quality: 100,
        //   name: '${title}_${DateTime.now().millisecondsSinceEpoch}',
        // );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image saved to gallery')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permission denied to save image')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save image: $e')),
      );
    }
  }

  // Function to show image preview - navigates to ResultScreen
  void _showImagePreview(TryOnResultModel result) {
    try {
      // Get complete base64 image
      final String completeBase64 = result.isChunked 
        ? result.getCompleteImage() 
        : result.resultImage;
      
      // Navigate to ResultScreen with the result image and ID
      // This allows users to view and delete saved results
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            userImage: null, // Not available for saved results
            garmentImage: null, // Not available for saved results
            resultImageBase64: completeBase64,
            resultId: result.id, // Pass result ID for delete functionality
          ),
        ),
      ).then((deleted) {
        // Refresh results when returning from the ResultScreen
        // If deleted is true, the result was deleted
        _loadUserResults();
      });
    } catch (e) {
      print("Error opening result: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening result: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userResults = Provider.of<TryOnResultProvider>(context).userResults;
    
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false,
        title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              // Navigate to history screen
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Home tab
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Virtual Fitting Room',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Try on clothes virtually before you buy them',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Upload Images',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildImageSelector(
                          'Your Photo',
                          _userImage,
                          Icons.person,
                          _selectUserImage,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildImageSelector(
                          'Garment',
                          _garmentImage,
                          Icons.checkroom,
                          _selectGarmentImage,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ElevatedButton(
                    onPressed: (_userImage != null && _garmentImage != null)
                        ? _processImages
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ).copyWith(
                      backgroundColor: MaterialStateProperty.resolveWith<
                        Color
                      >((Set<MaterialState> states) {
                        if (states.contains(MaterialState.disabled)) {
                          return Colors.grey;
                        }
                        return gradientColors[0]; // Using the first color from gradient
                      }),
                    ),
                    child: const Text(
                      'Try It On',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Recents',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  height: 120,
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : userResults.isEmpty
                      ? Center(
                          child: Text(
                            'No try-on results yet',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          scrollDirection: Axis.horizontal,
                          itemCount: userResults.length,
                          itemBuilder: (context, index) {
                            return _buildResultCard(userResults[index]);
                          },
                        ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultCard(TryOnResultModel result) {
    try {
      // Decode base64 image
      final String completeBase64 = result.isChunked 
        ? result.getCompleteImage() 
        : result.resultImage;
    
      // Decode base64 image
      final imageBytes = base64Decode(completeBase64);
      
      return GestureDetector(
        onTap: () => _showImagePreview(result),
        child: Container(
          width: 100,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Hero(
                  tag: 'tryonresult_${result.id}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    child: Image.memory(
                      imageBytes,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      gaplessPlayback: true, // Prevents flickering during loading
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback if image can't be displayed
                        return Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.broken_image, color: Colors.grey[400]),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  result.title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print("Error displaying result card: $e");
      // Fallback if image loading fails
      return _buildCategoryCard(result.title, Icons.checkroom);
    }
  }

  Widget _buildImageSelector(
    String title,
    File? image,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: image != null ? gradientColors[0] : Colors.grey[300]!,
            width: image != null ? 2 : 1,
          ),
        ),
        child:
            image != null
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(image, fit: BoxFit.cover),
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 40, color: Colors.grey[500]),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Tap to select',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildCategoryCard(String title, IconData icon) {
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 35, color: gradientColors[0]),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}