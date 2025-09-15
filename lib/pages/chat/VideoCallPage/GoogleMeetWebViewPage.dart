import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class GoogleMeetWebViewPage extends StatefulWidget {
  final String meetingUrl;
  final String meetingTitle;

  const GoogleMeetWebViewPage({
    Key? key,
    required this.meetingUrl,
    required this.meetingTitle,
  }) : super(key: key);

  @override
  State<GoogleMeetWebViewPage> createState() => _GoogleMeetWebViewPageState();
}

class _GoogleMeetWebViewPageState extends State<GoogleMeetWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    try {
      // Initialize WebView platform if not already initialized
      if (WebViewPlatform.instance == null) {
        WebViewPlatform.instance = AndroidWebViewPlatform();
      }
      
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (mounted) {
                setState(() => _isLoading = true);
              }
            },
            onPageFinished: (String url) {
              if (mounted) {
                setState(() => _isLoading = false);
              }
            },
            onWebResourceError: (WebResourceError error) {
              print('WebView error: ${error.description}');
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.meetingUrl));
    } catch (e) {
      print('Error initializing WebView: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.meetingTitle),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _controller.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Loading Google Meet...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
