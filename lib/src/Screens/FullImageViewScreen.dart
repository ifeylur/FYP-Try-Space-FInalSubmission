import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class FullImageViewScreen extends StatelessWidget {
  final String imagePath;
  final String itemName;
  final Uint8List? imageBytes;

  const FullImageViewScreen({
    Key? key,
    required this.imagePath,
    required this.itemName,
    this.imageBytes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          itemName,
          style: const TextStyle(color: Colors.white),
        ),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: imageBytes != null
              ? Image.memory(
                  imageBytes!,
                  fit: BoxFit.contain,
                )
              : Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 64,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Image not found',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

