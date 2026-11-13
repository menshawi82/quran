import 'package:flutter/services.dart';

class StorageInfo {
  static const _channel = MethodChannel('com.talawat.talawat/storage');

  static Future<int?> freeBytes(String path) async {
    try {
      return await _channel.invokeMethod<int>('getFreeSpace', {'path': path});
    } on PlatformException {
      return null;
    }
  }
}
