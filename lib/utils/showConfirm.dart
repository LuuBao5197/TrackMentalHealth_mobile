import 'package:flutter/material.dart';

Future<bool> showConfirm(BuildContext context, String message,
    {String title = 'Confirm', String confirmText = 'OK', String cancelText = 'Cancel'}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false, // người dùng phải chọn
    builder: (BuildContext ctx) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmText),
          ),
        ],
      );
    },
  );
  return result ?? false; // nếu người dùng bấm back hoặc đóng dialog => false
}
