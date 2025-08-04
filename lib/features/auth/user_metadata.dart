

class UserMetadata {
  final String uid;
  final String email;
  final String role;
  final bool isVerified;
  final DateTime createdAt;

  UserMetadata({
    required this.uid,
    required this.email,
    required this.role,
    required this.isVerified,
    required this.createdAt,
  });

  factory UserMetadata.fromMap(Map<String, dynamic> map) {
    return UserMetadata(
      uid: map['uid'],
      email: map['email'],
      role: map['role'],
      isVerified: map['isVerified'],
      createdAt: map['createdAt'],
    );
  }
}