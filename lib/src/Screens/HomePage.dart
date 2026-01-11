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
import 'package:permission_handler/permission_handler.dart';
import 'package:try_space/src/Screens/CatalogScreen.dart';
import 'package:path_provider/path_provider.dart';

class HomePage extends StatefulWidget {
  final GlobalKey? key;

  const HomePage({this.key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();
  File? _userImage;
  File? _garmentImage;
  bool _isLoading = true;
  int _currentIndex = 0;
  
  String _selectedCategory = 'upper';
  
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
              ListTile(
  leading: const Icon(Icons.shopping_bag),
  title: const Text('Choose from catalog'),
  onTap: () async {
    Navigator.pop(context); // Close bottom sheet
    
    // Navigate to catalog with callback
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CatalogScreen(
          onGarmentSelected: (imageBytes, garmentType, garmentName) async {
            // Set the garment for try-on
            await setCatalogGarment(imageBytes, garmentType);
            
            // Go back to home
            Navigator.of(context).popUntil((route) => route.isFirst);
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$garmentName added for try-on!'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  },
),
            ],
          ),
        );
      },
    );
  }

  // Method to receive catalog garment from CatalogScreen
  Future<void> setCatalogGarment(Uint8List imageBytes, String garmentType) async {
    try {
      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/catalog_garment_${DateTime.now().millisecondsSinceEpoch}.png');
      
      // Write bytes to file
      await file.writeAsBytes(imageBytes);
      
      // Update state
      setState(() {
        _garmentImage = file;
        _selectedCategory = garmentType; // Set the category based on garment type
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading catalog garment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

    final virtualTryOnProvider = Provider.of<VirtualTryOnProvider>(context, listen: false);
    
    virtualTryOnProvider.clearResult();

    showDialog(
      context: context,
      barrierDismissible: false,
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
                  'This may take 30-40 seconds',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Category: $_selectedCategory',
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
      // UPDATED: Pass garment category to provider
      await virtualTryOnProvider.generateTryOn(
        _userImage!, 
        _garmentImage!,
        garmentCategory: _selectedCategory, // NEW
      );

      if (mounted) {
        Navigator.of(context).pop();
      }

      if (virtualTryOnProvider.errorMessage != null) {
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

      if (virtualTryOnProvider.resultImage != null && mounted) {
        final imageBytes = base64Decode(virtualTryOnProvider.resultImage!);
        
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              userImage: _userImage!,
              garmentImage: _garmentImage!,
              resultImageBase64: virtualTryOnProvider.resultImage!,
            ),
          ),
        ).then((_) {
          _loadUserResults();
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
      if (mounted) {
        Navigator.of(context).pop();
      }
      
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

  void _showImagePreview(TryOnResultModel result) {
    try {
      final String completeBase64 = result.isChunked 
        ? result.getCompleteImage() 
        : result.resultImage;
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            userImage: null,
            garmentImage: null,
            resultImageBase64: completeBase64,
            resultId: result.id,
          ),
        ),
      ).then((deleted) {
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
            onPressed: () {},
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
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
                
                // NEW: Garment Category Selector
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Garment Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[300]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            isExpanded: true,
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            items: const [
                              DropdownMenuItem(
                                value: 'upper',
                                child: Row(
                                  children: [
                                    Icon(Icons.checkroom, size: 20),
                                    SizedBox(width: 10),
                                    Text('Upper (Tops, Shirts, Jackets)'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'lower',
                                child: Row(
                                  children: [
                                    Icon(Icons.roller_skating, size: 20),
                                    SizedBox(width: 10),
                                    Text('Lower (Pants, Jeans)'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'overall',
                                child: Row(
                                  children: [
                                    Icon(Icons.accessibility_new, size: 20),
                                    SizedBox(width: 10),
                                    Text('Overall (Dresses, Full Outfits)'),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (String? value) {
                              if (value != null) {
                                setState(() {
                                  _selectedCategory = value;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Select the type of garment you want to try on',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
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
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.disabled)) {
                            return Colors.grey;
                          }
                          return gradientColors[0];
                        },
                      ),
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
      final String completeBase64 = result.isChunked 
        ? result.getCompleteImage() 
        : result.resultImage;
    
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
                      gaplessPlayback: true,
                      errorBuilder: (context, error, stackTrace) {
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
        child: image != null
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