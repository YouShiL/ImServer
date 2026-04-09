// Web 与 VM 共用入口；Web 侧由 stub 提供空实现。
export 'sqlite_desktop_init_stub.dart'
    if (dart.library.io) 'sqlite_desktop_init_io.dart';
