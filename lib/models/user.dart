class User {
  final String id;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final String? address;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final bool isActive;
  final DateTime? createdAt;
  final List<String>? roles;

  User({
    required this.id,
    required this.email,
    this.fullName,
    this.phoneNumber,
    this.address,
    this.avatarUrl,
    this.dateOfBirth,
    this.isActive = true,
    this.createdAt,
    this.roles,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Hỗ trợ cả PascalCase (từ backend) và camelCase
    final dobStr = json['DateOfBirth'] ?? json['dateOfBirth'];
    final createdStr = json['CreatedAt'] ?? json['createdAt'];

    return User(
      id: json['Id'] ?? json['id'] ?? '',
      email: json['Email'] ?? json['email'] ?? '',
      fullName:
          json['FullName'] ??
          json['fullName'] ??
          json['UserName'] ??
          json['userName'],
      phoneNumber: json['PhoneNumber'] ?? json['phoneNumber'],
      address: json['Address'] ?? json['address'],
      avatarUrl: json['AvatarUrl'] ?? json['avatarUrl'],
      dateOfBirth: dobStr != null ? DateTime.parse(dobStr) : null,
      isActive: json['IsActive'] ?? json['isActive'] ?? true,
      createdAt: createdStr != null ? DateTime.parse(createdStr) : null,
      roles: (json['Roles'] ?? json['roles']) != null
          ? List<String>.from(json['Roles'] ?? json['roles'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'fullName': fullName,
    'phoneNumber': phoneNumber,
    'address': address,
    'avatarUrl': avatarUrl,
    'dateOfBirth': dateOfBirth?.toIso8601String(),
    'isActive': isActive,
    'roles': roles,
  };

  bool get isAdmin => roles?.contains('Administrator') ?? false;

  String get displayName => fullName ?? email;
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class LoginResponse {
  final String token;
  final User user;

  LoginResponse({required this.token, required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // Backend trả về format: { token, userId, userName, roles }
    // Không có object user riêng, nên tạo User từ các field
    return LoginResponse(
      token: json['Token'] ?? json['token'] ?? '',
      user: User(
        id: json['UserId'] ?? json['userId'] ?? '',
        email: json['UserName'] ?? json['userName'] ?? '',
        fullName: json['UserName'] ?? json['userName'],
        roles: json['Roles'] != null
            ? List<String>.from(json['Roles'])
            : (json['roles'] != null ? List<String>.from(json['roles']) : null),
      ),
    );
  }
}
