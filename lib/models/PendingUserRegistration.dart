class PendingUserRegistration {
  final String email;
  final String fullName;
  final String password;
  final String confirmPassword;
  final int roleId;
  final String? avatar;

  PendingUserRegistration({
    required this.email,
    required this.fullName,
    required this.password,
    required this.confirmPassword,
    required this.roleId,
    this.avatar,
  });

  Map<String, String> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'password': password,
      'confirmPassword': confirmPassword,
      'roleId': roleId.toString(),
      if (avatar != null) 'avatar': avatar!,
    };
  }
}
