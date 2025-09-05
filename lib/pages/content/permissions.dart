import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

Future<void> requestAppPermissions() async {
  // Camera
  if (!await Permission.camera.isGranted) {
    var camStatus = await Permission.camera.request();
    if (camStatus.isGranted) {
      print("✅ Quyền camera đã được cấp");
    } else {
      print("❌ Quyền camera bị từ chối");
    }
  } else {
    print("✅ Quyền camera đã có sẵn");
  }

  // Lưu trữ
  if (Platform.isAndroid) {
    int sdkInt = (await Permission.storage.status).isGranted ? 29 : 30; // bạn có thể dùng device_info_plus để lấy SDK thực

    if (sdkInt < 30) {
      // Android 10 trở xuống
      if (await Permission.storage.isDenied) {
        var storeStatus = await Permission.storage.request();
        if (storeStatus.isGranted) {
          print("✅ Quyền lưu trữ đã được cấp");
        } else {
          print("❌ Quyền lưu trữ bị từ chối");
        }
      } else {
        print("✅ Quyền lưu trữ đã có sẵn");
      }
    } else {
      // Android 11 trở lên
      if (await Permission.manageExternalStorage.isDenied) {
        var manageStatus = await Permission.manageExternalStorage.request();
        if (manageStatus.isGranted) {
          print("✅ Quyền truy cập toàn bộ bộ nhớ đã được cấp");
        } else {
          print("❌ Quyền truy cập toàn bộ bộ nhớ bị từ chối");
        }
      } else {
        print("✅ Quyền truy cập toàn bộ bộ nhớ đã có sẵn");
      }
    }
  }
}
