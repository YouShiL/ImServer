/// 与后端 `APP_ENV` / `SPRING_PROFILES_ACTIVE` 对齐的 Flutter 运行环境。
///
/// **方式一（推荐打包/CI）**  
/// `flutter run --dart-define=APP_ENV=dev`  
/// `flutter build apk --dart-define=APP_ENV=prod`
///
/// **方式二（本地调试不想带参数）**  
/// 修改下面 [_kEditorDefaultEnvironment]；各环境默认 API 见 [_devApiBaseUrl] 等常量。
///
/// **覆盖某一环境的完整 API 根路径（含 `/api`）**  
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8082/api`  
/// （Android 模拟器访问本机常用 `10.0.2.2`。）
///
/// **WuKong IM（TCP）地址** 为 `host:port`，与各环境一同切换；也可：  
/// `flutter run --dart-define=IM_TCP_ADDR=10.0.2.2:5200`
library;

enum AppEnvironment {
  dev,
  test,
  prod,
}

// ---------------------------------------------------------------------------
// 未传 --dart-define=APP_ENV 时，使用此处作为默认环境（改这一行即可切换）。
// ---------------------------------------------------------------------------
const AppEnvironment _kEditorDefaultEnvironment = AppEnvironment.dev;

const String _kEnvFromDefine =
    String.fromEnvironment('APP_ENV', defaultValue: '');

/// 非空时优先于各环境下的默认 [apiBaseUrl]。
const String _kApiBaseUrlOverride =
    String.fromEnvironment('API_BASE_URL', defaultValue: '');

/// 非空时优先于各环境下的默认 [imTcpAddr]（`host:port`，与 wukongimfluttersdk [Options.addr] 一致）。
const String _kImTcpAddrOverride =
    String.fromEnvironment('IM_TCP_ADDR', defaultValue: '');

// ---------------------------------------------------------------------------
// 各环境默认 API 基址（须以 `/api` 结尾，与现有 [ApiService] 路径拼接方式一致）。
// dev 默认用本机局域网 IP，便于安卓真机联调（真机无法访问 127.0.0.1）。
// 若电脑 IP 变化或其它同事拉代码，请改此处或用 --dart-define=API_BASE_URL=...
// ---------------------------------------------------------------------------
const String _devApiBaseUrl = 'http://192.168.2.3:8082/api';
const String _testApiBaseUrl = 'http://127.0.0.1:8082/api';
const String _prodApiBaseUrl = 'https://api.yourdomain.com/api';

// ---------------------------------------------------------------------------
// WuKongIM TCP 连接地址（`host:port`）。端口须与 WuKongIM 服务端 `wk.yaml` 中
// 客户端接入端口一致（常见默认 5200，请按实际部署修改）。
// ---------------------------------------------------------------------------
const String _devImTcpAddr = '192.168.2.3:5200';
const String _testImTcpAddr = '127.0.0.1:5200';
const String _prodImTcpAddr = 'im.yourdomain.com:5200';

/// 全局可读的应用环境配置（惰性解析一次）。
abstract final class AppConfig {
  AppConfig._();

  static AppEnvironment? _environment;
  static String? _apiBaseUrl;
  static String? _imTcpAddr;

  /// 当前环境：`APP_ENV`（dart-define）优先，否则 [_kEditorDefaultEnvironment]。
  static AppEnvironment get environment {
    return _environment ??= _resolveEnvironment();
  }

  /// 后端 REST API 前缀，例如 `http://localhost:8082/api`。
  static String get apiBaseUrl {
    return _apiBaseUrl ??= _resolveApiBaseUrl(environment);
  }

  /// WuKongIM SDK [Options.addr]：`IP或域名:端口`。
  static String get imTcpAddr {
    return _imTcpAddr ??= _resolveImTcpAddr(environment);
  }

  /// 是否开启 IM SDK 调试日志（仅建议 dev 为 true）。
  static bool get imSdkDebug {
    return environment == AppEnvironment.dev;
  }

  static AppEnvironment _resolveEnvironment() {
    final flag = _kEnvFromDefine.trim().toLowerCase();
    if (flag.isEmpty) {
      return _kEditorDefaultEnvironment;
    }
    switch (flag) {
      case 'dev':
        return AppEnvironment.dev;
      case 'test':
        return AppEnvironment.test;
      case 'prod':
      case 'production':
        return AppEnvironment.prod;
      default:
        return _kEditorDefaultEnvironment;
    }
  }

  static String _resolveApiBaseUrl(AppEnvironment env) {
    final override = _kApiBaseUrlOverride.trim();
    if (override.isNotEmpty) {
      return _normalizeBaseUrl(override);
    }
    switch (env) {
      case AppEnvironment.dev:
        return _normalizeBaseUrl(_devApiBaseUrl);
      case AppEnvironment.test:
        return _normalizeBaseUrl(_testApiBaseUrl);
      case AppEnvironment.prod:
        return _normalizeBaseUrl(_prodApiBaseUrl);
    }
  }

  static String _resolveImTcpAddr(AppEnvironment env) {
    final override = _kImTcpAddrOverride.trim();
    if (override.isNotEmpty) {
      return override;
    }
    switch (env) {
      case AppEnvironment.dev:
        return _devImTcpAddr;
      case AppEnvironment.test:
        return _testImTcpAddr;
      case AppEnvironment.prod:
        return _prodImTcpAddr;
    }
  }

  static String _normalizeBaseUrl(String url) {
    var u = url.trim();
    if (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }
}
