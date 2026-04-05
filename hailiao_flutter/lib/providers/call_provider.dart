import 'dart:async';

import 'package:flutter/foundation.dart';

enum CallMediaType { audio, video }

enum CallStage { calling, waiting, connected, declined, ended }

typedef CallBoolHandler = FutureOr<void> Function(bool nextValue);
typedef CallVoidHandler = FutureOr<void> Function();

class CallProvider extends ChangeNotifier {
  CallProvider({
    required CallMediaType callType,
    required String name,
    required CallStage stage,
    String? avatarUrl,
    String? subtitle,
    Duration? duration,
    DateTime? connectedAt,
    bool isIncoming = false,
    bool isMuted = false,
    bool isSpeakerOn = false,
    bool isCameraEnabled = true,
    bool isFrontCamera = true,
    this.onMuteChanged,
    this.onSpeakerChanged,
    this.onCameraChanged,
    this.onSwitchCameraChanged,
    this.onEndCall,
  })  : _callType = callType,
        _name = name,
        _stage = stage,
        _avatarUrl = avatarUrl,
        _subtitle = subtitle,
        _connectedAt = connectedAt,
        _duration = duration ?? Duration.zero,
        _isIncoming = isIncoming,
        _isMuted = isMuted,
        _isSpeakerOn = isSpeakerOn,
        _isCameraEnabled = isCameraEnabled,
        _isFrontCamera = isFrontCamera {
    if (_stage == CallStage.connected) {
      _connectedAt ??= DateTime.now().subtract(_duration);
      _startTimer();
    } else if (_stage == CallStage.calling || _stage == CallStage.waiting) {
      _preparePendingStage();
    }
  }

  factory CallProvider.fromRouteArgs({
    required CallMediaType fallbackType,
    required String fallbackName,
    required CallStage fallbackStage,
    String? fallbackAvatarUrl,
    String? fallbackSubtitle,
    Duration? fallbackDuration,
    DateTime? fallbackConnectedAt,
    bool fallbackIncoming = false,
    bool fallbackMuted = false,
    bool fallbackSpeakerOn = false,
    bool fallbackCameraEnabled = true,
    bool fallbackFrontCamera = true,
    Map<String, dynamic>? args,
    CallBoolHandler? onMuteChanged,
    CallBoolHandler? onSpeakerChanged,
    CallBoolHandler? onCameraChanged,
    CallBoolHandler? onSwitchCameraChanged,
    CallVoidHandler? onEndCall,
  }) {
    final Map<String, dynamic> map = args ?? const <String, dynamic>{};
    final CallMediaType callType =
        _parseCallType(map['callType'] ?? map['mediaType']) ?? fallbackType;
    final CallStage stage =
        _parseStage(map['callStage'] ?? map['stage']) ?? fallbackStage;
    final Duration duration =
        _parseDuration(map['duration']) ?? fallbackDuration ?? Duration.zero;
    final DateTime? connectedAt =
        _parseDateTime(map['connectedAt']) ?? fallbackConnectedAt;

    return CallProvider(
      callType: callType,
      name: (map['name'] ?? map['title'])?.toString() ?? fallbackName,
      stage: stage,
      avatarUrl: map['avatarUrl']?.toString() ?? fallbackAvatarUrl,
      subtitle: map['subtitle']?.toString() ?? fallbackSubtitle,
      duration: duration,
      connectedAt: connectedAt,
      isIncoming:
          map['isIncoming'] is bool ? map['isIncoming'] as bool : fallbackIncoming,
      isMuted: map['isMuted'] is bool ? map['isMuted'] as bool : fallbackMuted,
      isSpeakerOn: map['isSpeakerOn'] is bool
          ? map['isSpeakerOn'] as bool
          : fallbackSpeakerOn,
      isCameraEnabled: map['isCameraEnabled'] is bool
          ? map['isCameraEnabled'] as bool
          : fallbackCameraEnabled,
      isFrontCamera: map['isFrontCamera'] is bool
          ? map['isFrontCamera'] as bool
          : fallbackFrontCamera,
      onMuteChanged: onMuteChanged,
      onSpeakerChanged: onSpeakerChanged,
      onCameraChanged: onCameraChanged,
      onSwitchCameraChanged: onSwitchCameraChanged,
      onEndCall: onEndCall,
    );
  }

  final CallBoolHandler? onMuteChanged;
  final CallBoolHandler? onSpeakerChanged;
  final CallBoolHandler? onCameraChanged;
  final CallBoolHandler? onSwitchCameraChanged;
  final CallVoidHandler? onEndCall;

  CallMediaType _callType;
  String _name;
  String? _avatarUrl;
  String? _subtitle;
  CallStage _stage;
  DateTime? _connectedAt;
  Duration _duration;
  bool _isIncoming;
  bool _isMuted;
  bool _isSpeakerOn;
  bool _isCameraEnabled;
  bool _isFrontCamera;
  Timer? _timer;
  Timer? _pendingStageTimer;
  bool _isEnding = false;

  CallMediaType get callType => _callType;
  String get name => _name;
  String? get avatarUrl => _avatarUrl;
  String? get subtitle => _subtitle;
  CallStage get stage => _stage;
  DateTime? get connectedAt => _connectedAt;
  Duration get duration => _duration;
  bool get isIncoming => _isIncoming;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isCameraEnabled => _isCameraEnabled;
  bool get isFrontCamera => _isFrontCamera;
  bool get isConnected => _stage == CallStage.connected;
  bool get isVideo => _callType == CallMediaType.video;
  bool get isEnded => _stage == CallStage.ended || _stage == CallStage.declined;
  bool get canAccept =>
      _isIncoming && (_stage == CallStage.calling || _stage == CallStage.waiting);

  String get statusText {
    switch (_stage) {
      case CallStage.calling:
        return '正在呼叫…';
      case CallStage.waiting:
        return _isIncoming ? '等待接听' : '等待对方接听';
      case CallStage.connected:
        return isVideo ? '视频通话中' : '语音通话中';
      case CallStage.declined:
        return _isIncoming ? '已拒接来电' : '对方已拒接';
      case CallStage.ended:
        return '通话已结束';
    }
  }

  String get helperText {
    switch (_stage) {
      case CallStage.calling:
        return '正在建立连接';
      case CallStage.waiting:
        return _isIncoming ? '你可以选择接听或拒接' : '等待对方接听';
      case CallStage.connected:
        return isVideo ? '画面与声音已连接' : '通话已连接，保持安静环境会更清晰';
      case CallStage.declined:
        return _isIncoming ? '你已拒绝本次通话' : '你可以稍后再次发起通话';
      case CallStage.ended:
        return '本次通话已结束';
    }
  }

  String? get durationText {
    if (!isConnected) {
      return null;
    }
    final int totalSeconds = _duration.inSeconds;
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    final int hours = minutes ~/ 60;
    if (hours > 0) {
      final int remainMinutes = minutes % 60;
      return '${hours.toString().padLeft(2, '0')}:${remainMinutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void updateRouteArgs(Map<String, dynamic> args) {
    final CallMediaType? parsedType =
        _parseCallType(args['callType'] ?? args['mediaType']);
    final CallStage? parsedStage =
        _parseStage(args['callStage'] ?? args['stage']);
    final Duration? parsedDuration = _parseDuration(args['duration']);
    final DateTime? parsedConnectedAt = _parseDateTime(args['connectedAt']);

    var changed = false;
    if (parsedType != null && parsedType != _callType) {
      _callType = parsedType;
      changed = true;
    }
    if (args['name'] != null || args['title'] != null) {
      final String nextName = (args['name'] ?? args['title']).toString().trim();
      if (nextName.isNotEmpty && nextName != _name) {
        _name = nextName;
        changed = true;
      }
    }
    if (args.containsKey('avatarUrl')) {
      final String? nextAvatar = args['avatarUrl']?.toString();
      if (nextAvatar != _avatarUrl) {
        _avatarUrl = nextAvatar;
        changed = true;
      }
    }
    if (args.containsKey('subtitle')) {
      final String? nextSubtitle = args['subtitle']?.toString();
      if (nextSubtitle != _subtitle) {
        _subtitle = nextSubtitle;
        changed = true;
      }
    }
    if (parsedDuration != null && parsedDuration != _duration) {
      _duration = parsedDuration;
      changed = true;
    }
    if (parsedConnectedAt != null && parsedConnectedAt != _connectedAt) {
      _connectedAt = parsedConnectedAt;
      changed = true;
    }
    if (args['isIncoming'] is bool && args['isIncoming'] != _isIncoming) {
      _isIncoming = args['isIncoming'] as bool;
      changed = true;
    }
    if (args['isMuted'] is bool && args['isMuted'] != _isMuted) {
      _isMuted = args['isMuted'] as bool;
      changed = true;
    }
    if (args['isSpeakerOn'] is bool && args['isSpeakerOn'] != _isSpeakerOn) {
      _isSpeakerOn = args['isSpeakerOn'] as bool;
      changed = true;
    }
    if (args['isCameraEnabled'] is bool &&
        args['isCameraEnabled'] != _isCameraEnabled) {
      _isCameraEnabled = args['isCameraEnabled'] as bool;
      changed = true;
    }
    if (args['isFrontCamera'] is bool &&
        args['isFrontCamera'] != _isFrontCamera) {
      _isFrontCamera = args['isFrontCamera'] as bool;
      changed = true;
    }
    if (parsedStage != null && parsedStage != _stage) {
      _setStageInternal(parsedStage);
      changed = true;
    } else if (_stage == CallStage.connected) {
      _connectedAt ??= DateTime.now().subtract(_duration);
      _startTimer();
    } else if (_stage == CallStage.calling || _stage == CallStage.waiting) {
      _preparePendingStage();
    }
    if (changed) {
      notifyListeners();
    }
  }

  void startOutgoingCall() {
    _isIncoming = false;
    _duration = Duration.zero;
    _connectedAt = null;
    _setStageInternal(CallStage.calling);
    notifyListeners();
  }

  void startIncomingCall({
    required CallMediaType callType,
    required String name,
    String? avatarUrl,
    String? subtitle,
  }) {
    resetCall(
      callType: callType,
      name: name,
      avatarUrl: avatarUrl,
      subtitle: subtitle,
      stage: CallStage.waiting,
      isIncoming: true,
    );
  }

  void markWaiting() {
    _setStageInternal(CallStage.waiting);
    notifyListeners();
  }

  void setStage(CallStage nextStage) {
    if (nextStage == _stage) {
      return;
    }
    _setStageInternal(nextStage);
    notifyListeners();
  }

  void connectCall() {
    _setStageInternal(CallStage.connected);
    notifyListeners();
  }

  void acceptCall() {
    _isIncoming = false;
    _setStageInternal(CallStage.connected);
    notifyListeners();
  }

  void declineCall() {
    _setStageInternal(CallStage.declined);
    notifyListeners();
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    notifyListeners();
    await onMuteChanged?.call(_isMuted);
  }

  Future<void> toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    notifyListeners();
    await onSpeakerChanged?.call(_isSpeakerOn);
  }

  Future<void> toggleCamera() async {
    _isCameraEnabled = !_isCameraEnabled;
    notifyListeners();
    await onCameraChanged?.call(_isCameraEnabled);
  }

  Future<void> switchCamera() async {
    _isFrontCamera = !_isFrontCamera;
    notifyListeners();
    await onSwitchCameraChanged?.call(_isFrontCamera);
  }

  Future<void> endCall() async {
    if (_isEnding) {
      return;
    }
    _isEnding = true;
    _setStageInternal(CallStage.ended);
    notifyListeners();
    await onEndCall?.call();
    _isEnding = false;
  }

  void remoteEnded() {
    _setStageInternal(CallStage.ended);
    notifyListeners();
  }

  void resetCall({
    CallMediaType? callType,
    String? name,
    String? avatarUrl,
    String? subtitle,
    CallStage stage = CallStage.calling,
    bool isIncoming = false,
  }) {
    _callType = callType ?? _callType;
    _name = name ?? _name;
    _avatarUrl = avatarUrl ?? _avatarUrl;
    _subtitle = subtitle ?? _subtitle;
    _stage = stage;
    _isIncoming = isIncoming;
    _connectedAt = null;
    _duration = Duration.zero;
    _isMuted = false;
    _isSpeakerOn = _callType == CallMediaType.audio;
    _isCameraEnabled = _callType == CallMediaType.video;
    _isFrontCamera = true;
    _isEnding = false;
    _pendingStageTimer?.cancel();
    _stopTimer();
    if (stage == CallStage.connected) {
      _connectedAt = DateTime.now();
      _startTimer();
    } else if (stage == CallStage.calling || stage == CallStage.waiting) {
      _preparePendingStage();
    }
    notifyListeners();
  }

  void _setStageInternal(CallStage nextStage) {
    _stage = nextStage;
    if (nextStage == CallStage.connected) {
      _pendingStageTimer?.cancel();
      _connectedAt ??= DateTime.now().subtract(_duration);
      _startTimer();
      return;
    }

    _stopTimer();
    if (nextStage == CallStage.calling || nextStage == CallStage.waiting) {
      _preparePendingStage();
      return;
    }
    _pendingStageTimer?.cancel();
  }

  void _preparePendingStage() {
    _pendingStageTimer?.cancel();
    if (_isIncoming) {
      _stage = CallStage.waiting;
      return;
    }
    if (_stage == CallStage.waiting) {
      return;
    }
    _pendingStageTimer = Timer(const Duration(milliseconds: 1200), () {
      if (_stage == CallStage.calling) {
        _stage = CallStage.waiting;
        notifyListeners();
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_stage != CallStage.connected || _connectedAt == null) {
        return;
      }
      _duration = DateTime.now().difference(_connectedAt!);
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _pendingStageTimer?.cancel();
    _stopTimer();
    super.dispose();
  }

  static CallMediaType? _parseCallType(Object? value) {
    if (value is CallMediaType) {
      return value;
    }
    final String text = value?.toString().trim().toLowerCase() ?? '';
    switch (text) {
      case 'audio':
      case 'voice':
        return CallMediaType.audio;
      case 'video':
        return CallMediaType.video;
      default:
        return null;
    }
  }

  static CallStage? _parseStage(Object? value) {
    if (value is CallStage) {
      return value;
    }
    final String text = value?.toString().trim().toLowerCase() ?? '';
    switch (text) {
      case 'calling':
      case 'outgoing':
      case 'dialing':
        return CallStage.calling;
      case 'waiting':
      case 'ringing':
        return CallStage.waiting;
      case 'connected':
      case 'answered':
      case 'active':
        return CallStage.connected;
      case 'declined':
      case 'rejected':
      case 'refused':
        return CallStage.declined;
      case 'ended':
      case 'hangup':
      case 'finished':
        return CallStage.ended;
      default:
        return null;
    }
  }

  static Duration? _parseDuration(Object? value) {
    if (value is Duration) {
      return value;
    }
    if (value is int) {
      return Duration(seconds: value);
    }
    final int? seconds = int.tryParse(value?.toString() ?? '');
    return seconds == null ? null : Duration(seconds: seconds);
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
