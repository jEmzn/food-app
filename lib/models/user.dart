class AppUser {
  final String id; // firebase_uid
  final String name;
  final String email;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'email': email};

  @override
  String toString() => 'AppUser(id: $id, name: $name, email: $email)';
}
