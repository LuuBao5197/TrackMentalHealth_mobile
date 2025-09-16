import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:url_launcher/url_launcher.dart';

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
              print('WebView loading: $url');
              if (mounted) {
                setState(() => _isLoading = true);
              }
            },
            onPageFinished: (String url) {
              print('WebView loaded: $url');
              if (mounted) {
                setState(() => _isLoading = false);
              }
            },
            onWebResourceError: (WebResourceError error) {
              print('WebView error: ${error.description}');
              print('Error code: ${error.errorCode}');
              print('Error type: ${error.errorType}');
              
              if (mounted) {
                setState(() => _isLoading = false);
                _showErrorDialog(error.description);
              }
            },
            onNavigationRequest: (NavigationRequest request) {
              print('Navigation request: ${request.url}');
              
              // Nếu URL có scheme không được hỗ trợ, thử mở bằng external app
              if (request.url.startsWith('intent://') || 
                  request.url.startsWith('market://') ||
                  request.url.startsWith('tel:') ||
                  request.url.startsWith('mailto:')) {
                _launchExternalUrl(request.url);
                return NavigationDecision.prevent;
              }
              
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.meetingUrl));
    } catch (e) {
      print('Error initializing WebView: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('Failed to initialize WebView: $e');
      }
    }
  }

  void _launchExternalUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Error launching external URL: $e');
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('WebView Error'),
        content: Text('Failed to load Google Meet: $error'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Quay lại màn hình trước
            },
            child: const Text('Go Back'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _controller.reload(); // Thử load lại
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
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
