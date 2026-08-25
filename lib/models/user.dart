class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String password;
  final String role;
  final String adminLevel;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
    this.adminLevel = 'none',
  });

  // ============================================================
  // ROLE HELPERS
  // ============================================================

  bool get isBuyer {
    return role == 'buyer';
  }

  bool get isSeller {
    return role == 'seller';
  }

  bool get isAdmin {
    return role == 'admin';
  }

  bool get isLeaderAdmin {
    return role == 'admin' &&
        adminLevel == 'leader';
  }

  bool get isNormalAdmin {
    return role == 'admin' &&
        adminLevel == 'normal';
  }

  bool get isAnyAdmin {
    return role == 'admin';
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
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      role: role ?? this.role,
      adminLevel: adminLevel ?? this.adminLevel,
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
    );
  }
}