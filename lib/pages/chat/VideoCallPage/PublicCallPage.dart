import 'package:flutter/material.dart';
import 'package:trackmentalhealth/helper/GoogleMeetService.dart';

class PublicCallPage extends StatefulWidget {
  const PublicCallPage({Key? key}) : super(key: key);

  @override
  State<PublicCallPage> createState() => _PublicCallPageState();
}

class _PublicCallPageState extends State<PublicCallPage> {
  final String roomID = "public_room"; // phòng chung test
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startPublicGoogleMeet();
  }

  Future<void> _startPublicGoogleMeet() async {
    setState(() => _isLoading = true);
    
    try {
      await GoogleMeetService.startVideoCall(
        meetingTitle: 'Public Group Meeting - $roomID',
        participantName: 'Group Participant',
      );
      
      // Quay lại màn hình trước sau khi mở Google Meet
      if (mounted) {
        // Use a delayed pop to avoid Navigator lock issues
        Future.delayed(Duration(milliseconds: 100), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting group meeting: $e'),
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
        title: const Text("Group Video Call"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
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
                  Icons.groups,
                  size: 80,
                  color: Colors.teal,
                ),
                SizedBox(height: 20),
                Text(
                  'Group Video Call',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Room: $roomID',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 20),
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
                  onPressed: _startPublicGoogleMeet,
                  icon: Icon(Icons.groups),
                  label: Text('Join Group Meeting'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                ),
                SizedBox(height: 15),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.arrow_back),
                  label: Text('Back to Chat'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
