import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trackmentalhealth/utils/StompService.dart';

class ConnectionStatusWidget extends StatefulWidget {
  final StompService stompService;
  final bool showInAppBar;
  
  const ConnectionStatusWidget({
    Key? key,
    required this.stompService,
    this.showInAppBar = true,
  }) : super(key: key);

  @override
  State<ConnectionStatusWidget> createState() => _ConnectionStatusWidgetState();
}

class _ConnectionStatusWidgetState extends State<ConnectionStatusWidget> {
  bool _isConnected = false;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _startStatusMonitoring();
  }

  void _startStatusMonitoring() {
    _statusTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _isConnected = widget.stompService.isConnected;
          _isConnecting = widget.stompService.isConnecting;
          _reconnectAttempts = widget.stompService.reconnectAttempts;
        });
      }
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showInAppBar) {
      return _buildAppBarIndicator();
    } else {
      return _buildFloatingIndicator();
    }
  }

  Widget _buildAppBarIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatusIcon(),
        SizedBox(width: 4),
        _buildStatusText(),
      ],
    );
  }

  Widget _buildFloatingIndicator() {
    return Positioned(
      top: 50,
      right: 16,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getStatusColor().withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusIcon(),
            SizedBox(width: 6),
            _buildStatusText(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (_isConnected) {
      return Icon(
        Icons.wifi,
        color: Colors.white,
        size: 16,
      );
    } else if (_isConnecting) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else {
      return Icon(
        Icons.wifi_off,
        color: Colors.white,
        size: 16,
      );
    }
  }

  Widget _buildStatusText() {
    String text;
    if (_isConnected) {
      text = "Đã kết nối";
    } else if (_isConnecting) {
      text = "Đang kết nối...";
    } else {
      text = "Mất kết nối";
      if (_reconnectAttempts > 0) {
        text += " ($_reconnectAttempts/5)";
      }
    }

    return Text(
      text,
      style: TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Color _getStatusColor() {
    if (_isConnected) {
      return Colors.green;
    } else if (_isConnecting) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}

/// Widget hiển thị dialog trạng thái kết nối chi tiết
class ConnectionStatusDialog extends StatelessWidget {
  final StompService stompService;

  const ConnectionStatusDialog({
    Key? key,
    required this.stompService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.network_check, color: Colors.blue),
          SizedBox(width: 8),
          Text("Trạng thái kết nối"),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusRow(
            "Kết nối:",
            stompService.isConnected ? "Đã kết nối" : "Chưa kết nối",
            stompService.isConnected ? Colors.green : Colors.red,
          ),
          _buildStatusRow(
            "Đang kết nối:",
            stompService.isConnecting ? "Có" : "Không",
            stompService.isConnecting ? Colors.orange : Colors.grey,
          ),
          _buildStatusRow(
            "Số lần thử:",
            "${stompService.reconnectAttempts}/5",
            Colors.blue,
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  stompService.reconnect();
                  Navigator.pop(context);
                },
                icon: Icon(Icons.refresh),
                label: Text("Kết nối lại"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(Icons.close),
                label: Text("Đóng"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
