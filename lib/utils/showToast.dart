import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

enum ToastType { success, error, warning, info }

void showToast(String message, String type) {
  Color bgColor;

  switch (type.toLowerCase()) {
    case 'success':
      bgColor = Colors.green;
      break;
    case 'error':
      bgColor = Colors.red;
      break;
    case 'warning':
      bgColor = Colors.orange;
      break;
    case 'info':
      bgColor = Colors.blue;
      break;
    default:
      bgColor = Colors.black;
  }

  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.TOP,
    backgroundColor: bgColor,
    textColor: Colors.white,
    fontSize: 16.0,
  );
}
