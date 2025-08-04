class UserMetadata {
  final String? uid;
  final String? email;
  final String? role;
  final String? section;
  final bool isVerified;
  final DateTime? createdAt;

  UserMetadata({
    this.uid,
    this.email,
    this.role,
    this.section,
    this.isVerified = false,
    this.createdAt,
  });

  factory UserMetadata.fromMap(Map<String, dynamic> map) {
    try {
      return UserMetadata(
        uid: map['uid'] as String?,
        email: map['email'] as String?,
        role: map['role'] as String?,
        section: map['section'] as String?,
        isVerified: (map['is_verified'] as bool?) ?? false,
        createdAt: map['created_at']?.toDate(),
      );
    } catch (e) {
      print('Error creating UserMetadata: $e');
      print('Map data: $map');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'section': section,
      'is_verified': isVerified,
      'created_at': createdAt,
    };
  }
  
  @override
  String toString() => toMap().toString();
}