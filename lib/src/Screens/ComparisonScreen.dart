import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:try_space/Providers/TryOnResultProvider.dart';
import 'package:try_space/Models/TryOnResultModel.dart';
import 'package:path_provider/path_provider.dart';

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  File? _firstImage;
  File? _secondImage;
  bool _showResult = false;
  bool _isLoading = true;

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load results: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage(bool isFirst) async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        if (isFirst) {
          _firstImage = File(pickedFile.path);
        } else {
          _secondImage = File(pickedFile.path);
        }
      });
    }
  }

  void _onTryOnPressed() {
    if (_firstImage != null && _secondImage != null) {
      setState(() {
        _showResult = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select both images before trying on.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false,
        title: const Text("Compare Outfits",style: TextStyle(color: Colors.white),),
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
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            children: [
              const Text(
                "Upload Two Images to Compare",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _pickImage(true),
                              child: Container(
                                height: 100,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: Colors.white70),
                                  color: Colors.white.withOpacity(0.2),
                                ),
                                child: _firstImage != null
                                    ? ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.file(
                                    _firstImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                    : const Center(
                                  child: Text(
                                    "Tap to select first image",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                              ),
                            )
                          ),
                          const SizedBox(width: 16), // spacing between images
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _pickImage(false),
                              child: Container(
                                height: 100,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: Colors.white70),
                                  color: Colors.white.withOpacity(0.2),
                                ),
                                child: _secondImage != null
                                    ? ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.file(
                                    _secondImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                    : const Center(
                                  child: Text(
                                    "Tap to select second image",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Result section (optional)
                      if (_showResult)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Comparison Result",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _firstImage != null
                                      ? Image.file(_firstImage!)
                                      : const SizedBox(),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _secondImage != null
                                      ? Image.file(_secondImage!)
                                      : const SizedBox(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "This is a basic visual comparison. AI styling suggestions will be added soon.",
                              style:
                              TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      
                      // Recent Results Section (similar to HomePage)
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: Text(
                          'Recents',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        height: 120,
                        child: _isLoading 
                          ? const Center(child: CircularProgressIndicator(color: Colors.white))
                          : Consumer<TryOnResultProvider>(
                              builder: (context, provider, _) {
                                final userResults = provider.userResults;
                                return userResults.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No try-on results yet',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 0),
                                      scrollDirection: Axis.horizontal,
                                      itemCount: userResults.length,
                                      itemBuilder: (context, index) {
                                        return _buildResultCard(userResults[index]);
                                      },
                                    );
                              },
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, -3),
            )
          ],
        ),
        child: ElevatedButton(
          onPressed: _onTryOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: gradientColors[0],
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "Compare",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
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
        onTap: () => _selectImageForComparison(result), // Only select for comparison, no navigation
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
      return Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Icon(Icons.image, color: Colors.grey[400]),
        ),
      );
    }
  }

  /// Select an image from recents for comparison
  /// First click selects first image, second click selects second image
  Future<void> _selectImageForComparison(TryOnResultModel result) async {
    try {
      // Get complete base64 image
      final String completeBase64 = result.isChunked 
        ? result.getCompleteImage() 
        : result.resultImage;
      
      // Decode base64 to bytes
      final imageBytes = base64Decode(completeBase64);
      
      // Create temporary file from bytes
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/comparison_${result.id}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(imageBytes);
      
      // Determine which image slot to fill
      if (_firstImage == null) {
        // First image is empty, select for first slot
        setState(() {
          _firstImage = tempFile;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ First image selected'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      } else if (_secondImage == null) {
        // Second image is empty, select for second slot
        setState(() {
          _secondImage = tempFile;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Second image selected'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        // Both images are already selected, ask user which to replace
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Replace Image'),
            content: const Text('Both images are already selected. Which one would you like to replace?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _firstImage = tempFile;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ First image replaced'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: const Text('Replace First'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _secondImage = tempFile;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Second image replaced'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: const Text('Replace Second'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print("Error selecting image for comparison: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

}
