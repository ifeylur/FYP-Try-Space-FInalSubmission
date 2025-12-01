import 'dart:convert';
import 'package:flutter/services.dart';
import '../Models/CatalogItem.dart';

class CatalogService {
  static Future<List<CatalogCategory>> loadCatalog() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/clothing_catalog.json');
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      return (jsonData['categories'] as List)
          .map((cat) => CatalogCategory.fromJson(cat as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading catalog: $e');
      rethrow;
    }
  }
}

