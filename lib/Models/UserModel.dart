class UserModel {
  final String uid;
  final String name;
  final String email;
  final String profileImageUrl;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.profileImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      profileImageUrl: map['profileImageUrl'],
    );
  }

  
}
