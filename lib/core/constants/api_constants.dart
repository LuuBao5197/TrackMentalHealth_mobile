class ApiConstants {
  // Base URL có thể đổi 1 nơi duy nhất ở đây
  static const String ipLocal = '192.168.0.252';
  static const String baseUrl = 'http://' + ipLocal + ':9999/api';
  // Ví dụ: các endpoint cụ thể
  static const String login = baseUrl + '/users/login';
  static const String register = baseUrl + '/users/register';
  static const String getTests = baseUrl + '/test/';
  static String getProfileById(int id) => '$baseUrl/users/profile/$id';
  static const String sendOtp = baseUrl + '/users/send-otp-register';
  static const String verifyOtp = baseUrl + '/users/verify-otp-register';
  static const String checkEmailExists = baseUrl + '/users/check-email';
  static const String loginWithGoogle = baseUrl + '/auth/oauth/google';
  static const String loginWithFaceId = baseUrl + '/users/login-faceid';
  static const String flaskBaseUrl = 'http://' + ipLocal + ':5000';
  //Lesson,Article,Exercise
  static const String getLessons = '$baseUrl/lesson';
  static const String getExercises = '$baseUrl/exercise/';
  static const String getArticles = '$baseUrl/article/';

}
