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
      throw 'Error launching Google Meet: $e';
    }
  }

  static String generateMeetUrl(String title, String participant) {
    // Tạo meeting ID ngẫu nhiên
    final meetingId = _generateMeetingId();
    
    // Tạo Google Meet URL với title
    final encodedTitle = Uri.encodeComponent(title);
    final encodedParticipant = Uri.encodeComponent(participant);
    
    return 'https://meet.google.com/$meetingId?title=$encodedTitle&participant=$encodedParticipant';
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
