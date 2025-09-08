import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

void showToast(String message, String type) {
  Color bgColor;
  IconData icon;

  switch (type.toLowerCase()) {
    case 'success':
      bgColor = Colors.green.shade600;
      icon = Icons.check_circle;
      break;
    case 'error':
      bgColor = Colors.red.shade600;
      icon = Icons.error;
      break;
    case 'warning':
      bgColor = Colors.orange.shade600;
      icon = Icons.warning;
      break;
    case 'info':
    default:
      bgColor = Colors.blue.shade600;
      icon = Icons.info;
  }

  Fluttertoast.showToast(
    msg: "${message}",
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM_RIGHT,
    backgroundColor: bgColor,
    textColor: Colors.white,
    fontSize: 18.0,
  );
}
