import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  File? _firstImage;
  File? _secondImage;
  bool _showResult = false;


  final List<Color> gradientColors = const [
    Color(0xFFFF5F6D),
    Color(0xFFFFC371),
  ];

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
}
