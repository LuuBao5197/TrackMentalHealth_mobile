import 'package:flutter/material.dart';
import 'package:trackmentalhealth/helper/GoogleMeetService.dart';
import 'package:trackmentalhealth/pages/chat/VideoCallPage/GoogleMeetWebViewPage.dart';

class PrivateCallPage extends StatefulWidget {
  final String? sessionId;
  final String currentUserId;
  final String currentUserName;
  final bool isCaller;


  const PrivateCallPage({
    super.key,
    this.sessionId,
    required this.currentUserId,
    required this.currentUserName,
    required this.isCaller, //

  });
  @override
  State<PrivateCallPage> createState() => _PrivateCallPageState();
}

class _PrivateCallPageState extends State<PrivateCallPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startGoogleMeetCall();
  }

  Future<void> _startGoogleMeetCall() async {
    setState(() => _isLoading = true);
    
    try {
      // Tạo Google Meet URL
      final meetingUrl = GoogleMeetService.generateMeetUrl(
        'Chat with ${widget.currentUserName}',
        widget.currentUserName,
      );
      
      // Mở Google Meet trong WebView
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GoogleMeetWebViewPage(
              meetingUrl: meetingUrl,
              meetingTitle: 'Chat with ${widget.currentUserName}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting video call: $e'),
            backgroundColor: Colors.red,
          ),
        );
        // Use a delayed pop to avoid Navigator lock issues
        Future.delayed(Duration(milliseconds: 100), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Starting Video Call'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading) ...[
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
              SizedBox(height: 20),
              Text(
                'Opening Google Meet...',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
            ] else ...[
              Icon(
                Icons.video_call,
                size: 80,
                color: Colors.teal,
              ),
              SizedBox(height: 20),
              Text(
                'Video call with ${widget.currentUserName}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Google Meet will open in your browser',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _startGoogleMeetCall,
                icon: Icon(Icons.video_call),
                label: Text('Start Video Call'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
