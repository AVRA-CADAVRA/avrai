
enum UserRole {
  user,
  admin,
  moderator,
}

class User {
  final String id;
  final String email;
  final String name;
  final String? displayName;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool? isOnline;
  // Legacy fields used in integration tests
  final List<String> curatedLists = const [];
  final List<String> collaboratedLists = const [];
  final List<String> followedLists = const [];

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.displayName,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.isOnline,
  });

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? displayName,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isOnline,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'displayName': displayName,
      'role': role.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isOnline': isOnline,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      displayName: json['displayName'],
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.user,
      ),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      isOnline: json['isOnline'],
    );
  }

  // Convenience getter
  String get displayNameOrName => displayName ?? name;

  int get totalListInvolvement =>
      curatedLists.length + collaboratedLists.length + followedLists.length;
}
