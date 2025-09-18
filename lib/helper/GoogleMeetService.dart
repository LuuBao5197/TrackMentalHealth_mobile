import 'package:url_launcher/url_launcher.dart';

class GoogleMeetService {
  static Future<void> startVideoCall({
    required String meetingTitle,
    required String participantName,
  }) async {
    // Tạo Google Meet link với title và participant name
    final meetingUrl = generateMeetUrl(meetingTitle, participantName);
    
    try {
      final Uri url = Uri.parse(meetingUrl);
      
      // Thử mở với external browser trước (để tránh mở Gmail)
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return;
      } catch (e) {
        print('External application failed: $e');
      }
      
      // Fallback: thử với platform default
      try {
        await launchUrl(url, mode: LaunchMode.platformDefault);
        return;
      } catch (e) {
        print('Platform default failed: $e');
      }
      
      // Fallback cuối: thử với external browser
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return;
      } catch (e) {
        print('External browser failed: $e');
      }
      
      throw 'Could not launch Google Meet. Please install a web browser.';
    } catch (e) {
      throw 'Error launching Google Meet: $e';
    }
  }

  static String generateMeetUrl(String title, String participant) {
    // Tạo meeting ID ngẫu nhiên
    final meetingId = _generateMeetingId();
    
    // Tạo Google Meet URL đơn giản (không có query parameters để tránh lỗi)
    return 'https://meet.google.com/$meetingId';
  }

  // Phương thức tạo URL cho WebView (đơn giản hơn)
  static String generateWebViewUrl(String title, String participant) {
    // Sử dụng meeting ID cố định để test, hoặc tạo mới
    final meetingId = _generateMeetingId();
    
    // URL đơn giản cho WebView
    return 'https://meet.google.com/$meetingId';
  }

  // Phương thức mở Google Meet với URL scheme chính xác
  static Future<void> openGoogleMeetDirectly({
    required String meetingTitle,
    required String participantName,
  }) async {
    final meetingId = _generateMeetingId();
    
    // Tạo URL Google Meet chính xác
    final meetUrl = 'https://meet.google.com/$meetingId';
    
    try {
      final Uri url = Uri.parse(meetUrl);
      
      // Thử mở với external browser
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Error opening Google Meet: $e');
      rethrow;
    }
  }

  // Phương thức mở Google Meet với fallback
  static Future<void> openGoogleMeetWithFallback({
    required String meetingTitle,
    required String participantName,
  }) async {
    final meetingId = _generateMeetingId();
    final meetUrl = 'https://meet.google.com/$meetingId';
    final Uri url = Uri.parse(meetUrl);
    
    print('🔗 Generated Google Meet URL: $meetUrl');
    print('🔗 Parsed URI: $url');


    try {
      // Thử mở với external browser
      print('🌐 Attempting to open with external browser...');
      await launchUrl(url, mode: LaunchMode.externalApplication);
      print('✅ Successfully opened with external browser');
    } catch (e) {
      print('❌ External browser failed: $e');
      
      // Fallback: thử mở với platform default
      try {
        print('🌐 Attempting to open with platform default...');
        await launchUrl(url, mode: LaunchMode.platformDefault);
        print('✅ Successfully opened with platform default');
      } catch (e2) {
        print('❌ Platform default failed: $e2');
        throw 'Could not open Google Meet. Please check your browser settings.';
      }
    }
  }

  // Phương thức mở Google Meet thông minh (kiểm tra app có sẵn)
  static Future<void> openGoogleMeetSmart({
    required String meetingTitle,
    required String participantName,
  }) async {
    final meetingId = _generateMeetingId();
    final meetUrl = 'https://meet.google.com/$meetingId';
    
    print('🔗 Generated Google Meet URL: $meetUrl');
    
    try {
      final Uri url = Uri.parse(meetUrl);
      
      // Kiểm tra xem có thể mở URL không
      if (await canLaunchUrl(url)) {
        print('✅ URL can be launched');
        
        // Thử mở với external browser
        try {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          print('✅ Successfully opened with external browser');
          return;
        } catch (e) {
          print('❌ External browser failed: $e');
        }
        
        // Fallback: thử mở với platform default
        try {
          await launchUrl(url, mode: LaunchMode.platformDefault);
          print('✅ Successfully opened with platform default');
          return;
        } catch (e) {
          print('❌ Platform default failed: $e');
        }
      } else {
        print('❌ URL cannot be launched');
        throw 'Cannot open Google Meet URL. Please check your device settings.';
      }
    } catch (e) {
      print('❌ Error opening Google Meet: $e');
      rethrow;
    }
  }

  static String _generateMeetingId() {
    // Tạo meeting ID ngẫu nhiên (10 ký tự)
    const chars = 'abcdefghijklmnopqrstuvwxyz';
    int random = DateTime.now().millisecondsSinceEpoch;
    String result = '';
    
    for (int i = 0; i < 10; i++) {
      result += chars[random % chars.length];
      random ~/= chars.length;
    }
    
    return result;
  }


  static Future<void> joinMeeting(String meetingId) async {
    final meetingUrl = 'https://meet.google.com/$meetingId';
    
    try {
      final Uri url = Uri.parse(meetingUrl);
      
      // Thử mở với external application trước
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return;
      } catch (e) {
        print('External application failed: $e');
      }
      
      // Fallback: thử với platform default
      try {
        await launchUrl(url, mode: LaunchMode.platformDefault);
        return;
      } catch (e) {
        print('Platform default failed: $e');
      }
      
      // Fallback cuối: thử với external browser
      try {
        await launchUrl(url, mode: LaunchMode.externalNonBrowserApplication);
        return;
      } catch (e) {
        print('External non-browser failed: $e');
      }
      
      throw 'Could not launch Google Meet. Please install a web browser.';
    } catch (e) {
      throw 'Error joining Google Meet: $e';
    }
  }
}
