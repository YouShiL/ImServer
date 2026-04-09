import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Windows / Linux / macOS：WuKongIM SDK 使用 [sqflite]；桌面端必须注入 FFI 的
/// [databaseFactory]，否则 [openDatabase] 无法正常工作，[WKDBHelper.getDB] 会长期为 null，
/// 收消息落库时 `getDB()!` 崩溃。
Future<void> initSqfliteForCurrentPlatform() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    if (kDebugMode) {
      // ignore: avoid_print
      print(
        '[sqlite] sqflite_common_ffi enabled for ${Platform.operatingSystem}',
      );
    }
  }
}
