class CatalogCategory {
  final String id;
  final String name;
  final String icon;
  final List<CatalogItem> items;

  CatalogCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.items,
  });

  factory CatalogCategory.fromJson(Map<String, dynamic> json) {
    return CatalogCategory(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      items: (json['items'] as List)
          .map((item) => CatalogItem.fromJson(item))
          .toList(),
    );
  }
}

class CatalogItem {
  final String id;
  final String name;
  final String image;
  final String type;

  CatalogItem({
    required this.id,
    required this.name,
    required this.image,
    required this.type,
  });

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    return CatalogItem(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      type: json['type'],
    );
  }
}

