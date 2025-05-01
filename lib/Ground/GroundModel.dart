class GroundModel {
  String? id;
  String name;
  String location;
  String phone;
  String email;

  GroundModel({
    this.id,
    required this.name,
    required this.location,
    required this.phone,
    required this.email,
  });

  factory GroundModel.fromMap(Map<String, dynamic> data, String id) {
    return GroundModel(
      id: id,
      name: data['name'],
      location: data['location'],
      phone: data['phone'],
      email: data['email'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'phone': phone,
      'email': email,
    };
  }
}