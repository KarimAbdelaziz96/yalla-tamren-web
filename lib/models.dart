class AdminModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String imageUrl;

  AdminModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.imageUrl,
  });

  factory AdminModel.fromMap(Map<String, dynamic> map, String id) {
    return AdminModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'imageUrl': imageUrl,
    };
  }
}
