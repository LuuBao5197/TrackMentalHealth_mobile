import 'package:flutter/material.dart';
import 'package:trackmentalhealth/helper/AgoraService.dart';
import 'package:trackmentalhealth/pages/chat/VideoCallPage/AgoraVideoCallPage.dart';

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
    required this.isCaller,

  });
  @override
  State<PrivateCallPage> createState() => _PrivateCallPageState();
}

class _PrivateCallPageState extends State<PrivateCallPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startVideoCall();
  }

  Future<void> _startVideoCall() async {
    setState(() => _isLoading = true);
    
    try {
      // Khởi tạo Agora
      await AgoraService.initialize();
      
      // Mở trang video call Agora
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AgoraVideoCallPage(
              channelName: widget.sessionId ?? 'test_session',
              uid: int.parse(widget.currentUserId),
              callerName: widget.currentUserName,
              calleeName: widget.currentUserName,
              isCaller: widget.isCaller,
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
                'Initializing Agora...',
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
                'Starting Agora video call...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _startVideoCall,
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

