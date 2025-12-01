import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../Models/CatalogItem.dart';
import '../../Services/CatalogService.dart';
import 'FullImageViewScreen.dart';

class CatalogScreen extends StatefulWidget {
  final Function(Uint8List, String, String)? onGarmentSelected;

  const CatalogScreen({Key? key, this.onGarmentSelected}) : super(key: key);

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  List<CatalogCategory> categories = [];
  String selectedCategoryId = 'upper';
  bool isLoading = true;

  final List<Color> gradientColors = const [
    Color(0xFFFF5F6D),
    Color(0xFFFFC371),
  ];

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final loadedCategories = await CatalogService.loadCatalog();
      setState(() {
        categories = loadedCategories;
        if (categories.isNotEmpty) {
          selectedCategoryId = categories.first.id;
        }
        isLoading = false;
      });
    } catch (e) {
      print('Error loading catalog: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading catalog: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onItemTapped(CatalogItem item) async {
    try {
      final ByteData data = await rootBundle.load(item.image);
      final Uint8List bytes = data.buffer.asUint8List();

      if (!mounted) return;

      // Show dialog with two options
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              item.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    bytes,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'What would you like to do?',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _viewFullImage(item, bytes);
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFFC371),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fullscreen, size: 20),
                    SizedBox(width: 8),
                    Text('View Full Image'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _addForTryOn(item, bytes);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC371),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_circle_outline, size: 20),
                    SizedBox(width: 8),
                    Text('Add for Try-On'),
                  ],
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewFullImage(CatalogItem item, Uint8List bytes) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullImageViewScreen(
          imagePath: item.image,
          itemName: item.name,
          imageBytes: bytes,
        ),
      ),
    );
  }

  void _addForTryOn(CatalogItem item, Uint8List bytes) {
    if (widget.onGarmentSelected != null) {
      widget.onGarmentSelected!(bytes, item.type, item.name);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} added for try-on! Switched to Home.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to add garment. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Catalog', style: TextStyle(color: Colors.white)),
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
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (categories.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Catalog', style: TextStyle(color: Colors.white)),
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
        ),
        body: const Center(
          child: Text('No catalog items available'),
        ),
      );
    }

    final selectedCategory = categories.firstWhere(
      (cat) => cat.id == selectedCategoryId,
      orElse: () => categories.first,
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Clothing Catalog', style: TextStyle(color: Colors.white)),
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Category Tabs
            Container(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = category.id == selectedCategoryId;

                  return GestureDetector(
                    onTap: () => setState(() => selectedCategoryId = category.id),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      constraints: const BoxConstraints(
                        minHeight: 64,
                        maxHeight: 64,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFC371) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            category.icon,
                            style: const TextStyle(fontSize: 22),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // Items Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: selectedCategory.items.length,
                itemBuilder: (context, index) {
                  final item = selectedCategory.items[index];

                  return GestureDetector(
                    onTap: () => _onItemTapped(item),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: Image.asset(
                                item.image,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image, size: 48),
                                  );
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              item.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

