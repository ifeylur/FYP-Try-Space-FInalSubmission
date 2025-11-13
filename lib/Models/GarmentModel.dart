class GarmentModel {
  final String id;
  final String imageUrl;
  final String uploadedBy;

  GarmentModel({
    required this.id,
    required this.imageUrl,
    required this.uploadedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'uploadedBy': uploadedBy,
    };
  }

  factory GarmentModel.fromMap(Map<String, dynamic> map) {
    return GarmentModel(
      id: map['id'],
      imageUrl: map['imageUrl'],
      uploadedBy: map['uploadedBy'],
    );
  }
}
