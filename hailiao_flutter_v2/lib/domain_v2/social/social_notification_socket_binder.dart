import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hailiao_flutter/config/app_config.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter_v2/providers/social_notification_provider.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const String _kSocialHintEventType = 'social_notification_hint';

/// 合并刷新窗口：窗口内多条 hint 只触发一次 [SocialNotificationProvider.loadPendingCount]。
const Duration _kMergeWindow = Duration(milliseconds: 600);

/// 长时间无 hint、WS 也未断时的兜底校准（与断线补偿互补）。
const Duration _kSilentCalibrationInterval = Duration(minutes: 3);

/// 连接 `AppConfig.notificationWebSocketUrl`，接收 Redis 桥接下行的社交通知 hint。
///
/// - 断线：指数退避自动重连；从后台恢复时立即重连。
/// - 每次成功连上后 [loadPendingCount] 补偿一次（WS 非可靠队列，断线期间 hint 可能丢）。
/// - hint 仍走 600ms 合并窗口，避免短时间多次 HTTP。
///
/// 握手通过 URL `token` 与后端 WebSocket JWT 拦截器对齐；与 WuKong IM 聊天链路完全分离。
class SocialNotificationSocketBinder extends StatefulWidget {
  const SocialNotificationSocketBinder({required this.child, super.key});

  /// Debug/ops：通知 WebSocket 是否已连接（未登录或 binder 未挂载时为 false）。
  static final ValueNotifier<bool> connectionState = ValueNotifier<bool>(false);

  static bool get isNotificationWsConnected => connectionState.value;

  final Widget child;

  @override
  State<SocialNotificationSocketBinder> createState() =>
      _SocialNotificationSocketBinderState();
}

class _SocialNotificationSocketBinderState extends State<SocialNotificationSocketBinder>
    with WidgetsBindingObserver {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  Timer? _silentCalibrationTimer;
  AuthProvider? _auth;

  /// 连续失败重连次数，成功连上后归零。
  int _reconnectAttempt = 0;

  /// 合并窗口：窗口内多次 hint 只触发一次刷新（与上次**已调度/已执行**的刷新对齐）。
  DateTime? _mergeWindowAnchor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _auth = context.read<AuthProvider>();
      _auth!.addListener(_onAuthChanged);
      _onAuthChanged();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }
    final AuthProvider? auth = _auth;
    if (auth == null || !auth.isAuthenticated) {
      return;
    }
    final String? token = auth.token;
    if (token == null || token.isEmpty) {
      return;
    }
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempt = 0;
    _wsLog('lifecycle resumed → reconnect');
    unawaited(_connect(token));
  }

  void _onAuthChanged() {
    final AuthProvider auth = _auth ?? context.read<AuthProvider>();
    final String? token = auth.token;
    if (auth.isAuthenticated && token != null && token.isNotEmpty) {
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      _reconnectAttempt = 0;
      _startSilentCalibrationTimer();
      unawaited(_connect(token));
    } else {
      _reconnectAttempt = 0;
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      _stopSilentCalibrationTimer();
      _disconnect();
    }
  }

  void _startSilentCalibrationTimer() {
    _silentCalibrationTimer?.cancel();
    _silentCalibrationTimer = Timer.periodic(_kSilentCalibrationInterval, (_) {
      if (!mounted) {
        return;
      }
      final AuthProvider? auth = _auth;
      if (auth == null || !auth.isAuthenticated) {
        return;
      }
      unawaited(context.read<SocialNotificationProvider>().loadPendingCount());
    });
  }

  void _stopSilentCalibrationTimer() {
    _silentCalibrationTimer?.cancel();
    _silentCalibrationTimer = null;
  }

  void _setConnectionState(bool connected) {
    if (SocialNotificationSocketBinder.connectionState.value != connected) {
      SocialNotificationSocketBinder.connectionState.value = connected;
    }
  }

  void _wsLog(String message) {
    if (kDebugMode) {
      debugPrint('[notification.ws] $message');
    }
  }

  Future<void> _connect(String token) async {
    _wsLog('connecting attempt=$_reconnectAttempt');
    _disconnectSocketOnly();
    try {
      final Uri uri = Uri.parse(AppConfig.notificationWebSocketUrl).replace(
        queryParameters: <String, String>{'token': token},
      );
      final WebSocketChannel ch = WebSocketChannel.connect(uri);
      await ch.ready;
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      _reconnectAttempt = 0;
      _channel = ch;
      _subscription = ch.stream.listen(
        _onSocketData,
        onError: (_) {
          _wsLog('socket error → reconnecting');
          _setConnectionState(false);
          _scheduleReconnect();
        },
        onDone: () {
          _wsLog('socket closed → reconnecting');
          _setConnectionState(false);
          _scheduleReconnect();
        },
      );
      _setConnectionState(true);
      _wsLog('connected');
      _onConnectedCompensation();
    } catch (e, st) {
      _setConnectionState(false);
      _wsLog('connect failed: $e');
      if (kDebugMode) {
        debugPrint('$st');
      }
      _scheduleReconnect();
    }
  }

  /// 首次上线 / 每次重连成功：用 REST 对齐一次（hint 在断线时可能丢失）。
  /// 同时锚定合并窗口，避免紧接着的 hint 与补偿重复打 HTTP。
  void _onConnectedCompensation() {
    if (!mounted) {
      return;
    }
    _mergeWindowAnchor = DateTime.now();
    unawaited(context.read<SocialNotificationProvider>().loadPendingCount());
  }

  void _onSocketData(dynamic data) {
    if (data is! String) {
      return;
    }
    try {
      final dynamic j = jsonDecode(data);
      if (j is! Map) {
        return;
      }
      final String? type = j['type'] as String?;
      if (type != _kSocialHintEventType) {
        return;
      }
      _scheduleMergedRefresh();
    } catch (_) {}
  }

  /// 600ms 合并窗口内多次 hint → 只触发一次 [loadPendingCount]。
  void _scheduleMergedRefresh() {
    final DateTime now = DateTime.now();
    if (_mergeWindowAnchor != null &&
        now.difference(_mergeWindowAnchor!) < _kMergeWindow) {
      return;
    }
    _mergeWindowAnchor = now;
    if (!mounted) {
      return;
    }
    unawaited(context.read<SocialNotificationProvider>().loadPendingCount());
  }

  Duration _nextBackoffDelay() {
    final int exp = min(_reconnectAttempt, 6);
    final int ms = min(60000, 1000 * (1 << exp));
    return Duration(milliseconds: ms);
  }

  void _scheduleReconnect() {
    final AuthProvider? auth = _auth;
    if (auth == null || !mounted) {
      return;
    }
    final String? token = auth.token;
    if (!auth.isAuthenticated || token == null || token.isEmpty) {
      return;
    }
    _reconnectTimer?.cancel();
    final Duration delay = _nextBackoffDelay();
    _reconnectAttempt = min(_reconnectAttempt + 1, 32);
    _wsLog(
      'reconnect scheduled in ${delay.inMilliseconds}ms nextAttempt=$_reconnectAttempt',
    );
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      if (!mounted) {
        return;
      }
      unawaited(_connect(token));
    });
  }

  /// 仅关闭 socket，不取消重连定时器（供 _connect 开头清理旧连接）。
  void _disconnectSocketOnly() {
    _setConnectionState(false);
    _subscription?.cancel();
    _subscription = null;
    final WebSocketChannel? ch = _channel;
    _channel = null;
    unawaited(ch?.sink.close());
  }

  void _disconnect() {
    _wsLog('disconnected (logout or tear down)');
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempt = 0;
    _disconnectSocketOnly();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _auth?.removeListener(_onAuthChanged);
    _stopSilentCalibrationTimer();
    _disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
