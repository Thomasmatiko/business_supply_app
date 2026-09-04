
class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String password;
  final String role;
  final String adminLevel;
  final String? profileImage;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
    this.adminLevel = 'none',
    this.profileImage,
  });

  // ============================================================
  // ROLE HELPERS
  // ============================================================

  bool get isBuyer {
    return role.trim().toLowerCase() == 'buyer';
  }

  bool get isSeller {
    return role.trim().toLowerCase() == 'seller';
  }

  bool get isAdmin {
    return role.trim().toLowerCase() == 'admin';
  }

  bool get isLeaderAdmin {
    return isAdmin &&
        adminLevel.trim().toLowerCase() == 'leader';
  }

  bool get isNormalAdmin {
    return isAdmin &&
        adminLevel.trim().toLowerCase() == 'normal';
  }

  bool get isAnyAdmin {
    return isAdmin;
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? password,
    String? role,
    String? adminLevel,
    String? profileImage,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      role: role ?? this.role,
      adminLevel: adminLevel ?? this.adminLevel,
      profileImage: profileImage ?? this.profileImage,
    );
  }

  // ============================================================
  // SQLITE
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role,
      'admin_level': adminLevel,
      'profile_image': profileImage,
    };
  }

  // ============================================================
  // FROM SQLITE
  // ============================================================

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      adminLevel:
          map['admin_level']?.toString() ?? 'none',
      profileImage:
          map['profile_image']?.toString(),
    );
  }
}
