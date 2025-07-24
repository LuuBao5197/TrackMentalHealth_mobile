class ApiConstants {
  // Base URL có thể đổi 1 nơi duy nhất ở đây
  static const String baseUrl = 'http://192.168.1.6:9999/api';

  // Ví dụ: các endpoint cụ thể
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String getTests = '$baseUrl/test/';
  static const String getProfile = '$baseUrl/users/profile';
}
