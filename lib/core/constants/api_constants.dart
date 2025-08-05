class ApiConstants {
  // Base URL có thể đổi 1 nơi duy nhất ở đây
  static const String ipLocal = '10.0.2.2';
  static const String baseUrl = 'http://${ipLocal}:9999/api';

  // Ví dụ: các endpoint cụ thể
  static const String login = '$baseUrl/users/login';
  static const String register = '$baseUrl/auth/register';
  static const String getTests = '$baseUrl/test/';
  static const String getProfile = '$baseUrl/users/profile';
  //Lesson,Article,Exercise
  static const String getLessons = '$baseUrl/lesson';
  static const String getExercises = '$baseUrl/exercise/';
  static const String getArticles = '$baseUrl/article/';


  //chat api
  static const String getChatSessionByUserId = '$baseUrl/chat/session';



}
