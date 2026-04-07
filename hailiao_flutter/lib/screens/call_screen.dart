import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hailiao_flutter/providers/call_provider.dart';
import 'package:hailiao_flutter/services/call_signal_bridge.dart';
import 'package:hailiao_flutter/theme/call_ui_tokens.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/widgets/call/call_avatar_panel.dart';
import 'package:hailiao_flutter/widgets/call/call_control_bar.dart';
import 'package:hailiao_flutter/widgets/call/call_status_header.dart';
import 'package:hailiao_flutter/widgets/call/local_preview_tile.dart';
import 'package:hailiao_flutter/widgets/call/video_call_surface.dart';
import 'package:provider/provider.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({
    super.key,
    required this.name,
    required this.mediaType,
    required this.stage,
    this.avatarUrl,
    this.subtitle,
    this.duration,
    this.connectedAt,
    this.isIncoming = false,
    this.isMuted = false,
    this.isSpeakerOn = false,
    this.isCameraEnabled = true,
    this.isFrontCamera = true,
    this.provider,
    this.disposeProvidedProvider = false,
    this.onMuteTap,
    this.onSpeakerTap,
    this.onCameraTap,
    this.onSwitchCameraTap,
    this.onMoreTap,
    this.onEndCallTap,
  });

  final String name;
  final CallMediaType mediaType;
  final CallStage stage;
  final String? avatarUrl;
  final String? subtitle;
  final Duration? duration;
  final DateTime? connectedAt;
  final bool isIncoming;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isCameraEnabled;
  final bool isFrontCamera;
  final CallProvider? provider;
  final bool disposeProvidedProvider;
  final CallBoolHandler? onMuteTap;
  final CallBoolHandler? onSpeakerTap;
  final CallBoolHandler? onCameraTap;
  final CallBoolHandler? onSwitchCameraTap;
  final VoidCallback? onMoreTap;
  final CallVoidHandler? onEndCallTap;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late final CallProvider _provider;
  late final bool _ownsProvider;
  bool _routeArgsApplied = false;
  Timer? _exitTimer;

  @override
  void initState() {
    super.initState();
    _ownsProvider = widget.provider == null || widget.disposeProvidedProvider;
    _provider = widget.provider ??
        CallProvider(
          callType: widget.mediaType,
          name: widget.name,
          stage: widget.stage,
          avatarUrl: widget.avatarUrl,
          subtitle: widget.subtitle,
          duration: widget.duration,
          connectedAt: widget.connectedAt,
          isIncoming: widget.isIncoming,
          isMuted: widget.isMuted,
          isSpeakerOn: widget.isSpeakerOn,
          isCameraEnabled: widget.isCameraEnabled,
          isFrontCamera: widget.isFrontCamera,
          onMuteChanged: widget.onMuteTap,
          onSpeakerChanged: widget.onSpeakerTap,
          onCameraChanged: widget.onCameraTap,
          onSwitchCameraChanged: widget.onSwitchCameraTap,
          onEndCall: widget.onEndCallTap,
        );
    _provider.addListener(_handleStageChange);
    CallSignalBridge.instance.attachProvider(_provider);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeArgsApplied) {
      return;
    }
    _routeArgsApplied = true;
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _provider.updateRouteArgs(args);
    }
  }

  @override
  void didUpdateWidget(covariant CallScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_ownsProvider) {
      return;
    }
    _provider.updateRouteArgs(<String, dynamic>{
      'callType': widget.mediaType.name,
      'name': widget.name,
      'avatarUrl': widget.avatarUrl,
      'subtitle': widget.subtitle,
      'callStage': widget.stage.name,
      'duration': widget.duration?.inSeconds,
      'connectedAt': widget.connectedAt?.toIso8601String(),
      'isIncoming': widget.isIncoming,
      'isMuted': widget.isMuted,
      'isSpeakerOn': widget.isSpeakerOn,
      'isCameraEnabled': widget.isCameraEnabled,
      'isFrontCamera': widget.isFrontCamera,
    });
  }

  @override
  void dispose() {
    _exitTimer?.cancel();
    _provider.removeListener(_handleStageChange);
    CallSignalBridge.instance.detachProvider(_provider);
    if (_ownsProvider) {
      _provider.dispose();
    }
    super.dispose();
  }

  void _handleStageChange() {
    _exitTimer?.cancel();
    if (_provider.stage == CallStage.declined ||
        _provider.stage == CallStage.ended) {
      _exitTimer = Timer(const Duration(milliseconds: 900), () {
        if (!mounted) {
          return;
        }
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  Future<void> _handleEndCall() async {
    await _provider.endCall();
  }

  void _handleAcceptCall() {
    _provider.acceptCall();
  }

  void _handleDeclineCall() {
    _provider.declineCall();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CallProvider>.value(
      value: _provider,
      child: Consumer<CallProvider>(
        builder: (BuildContext context, CallProvider call, _) {
          final bool dark = call.isVideo;
          return Scaffold(
            backgroundColor: dark
                ? CallUiTokens.videoCallBackground
                : CallUiTokens.audioCallBackground,
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: CallUiTokens.callPageMaxWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CallUiTokens.pagePadding,
                      vertical: CommonTokens.lg,
                    ),
                    child: call.isVideo
                        ? _buildVideoLayout(call)
                        : _buildAudioLayout(call),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAudioLayout(CallProvider call) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            CallUiTokens.audioCallBackground,
            Color(0xFFEFF4FD),
          ],
        ),
      ),
      child: Column(
        children: <Widget>[
          const Spacer(flex: 2),
          CallAvatarPanel(name: call.name, avatarUrl: call.avatarUrl),
          const SizedBox(height: CommonTokens.xl),
          CallStatusHeader(
            title: call.name,
            status: call.statusText,
            subtitle: call.headerSubtitle,
            duration: call.durationText,
          ),
          const Spacer(flex: 3),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: CallUiTokens.audioPanelMaxWidth,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  CommonTokens.lg,
                  CommonTokens.lg,
                  CommonTokens.lg,
                  CommonTokens.xl,
                ),
                decoration: BoxDecoration(
                  color: CallUiTokens.callSurface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(CommonTokens.xlRadius),
                  border: Border.all(color: CallUiTokens.callSoftBorderLight),
                  boxShadow: CallUiTokens.audioCardShadow,
                ),
                child: CallControlBar(actions: _buildAudioActions(call)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoLayout(CallProvider call) {
    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: CommonTokens.md,
            vertical: CallUiTokens.videoTopOverlayPadding,
          ),
          decoration: BoxDecoration(
            color: CallUiTokens.videoCallOverlayBackground,
            borderRadius: BorderRadius.circular(CommonTokens.lgRadius),
            border: Border.all(color: CallUiTokens.callSoftBorder),
          ),
          child: CallStatusHeader(
            title: call.name,
            status: call.statusText,
            subtitle: call.headerSubtitle,
            duration: call.durationText,
            dark: true,
          ),
        ),
        const SizedBox(height: CommonTokens.md),
        Expanded(
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: VideoCallSurface(
                  title: '',
                  status: null,
                  subtitle: call.videoSurfaceHint.trim().isEmpty
                      ? null
                      : call.videoSurfaceHint,
                  icon: call.isCameraEnabled
                      ? Icons.videocam_outlined
                      : Icons.videocam_off_rounded,
                ),
              ),
              Positioned(
                top: CommonTokens.md,
                right: CommonTokens.md,
                child: LocalPreviewTile(
                  label: call.isFrontCamera ? '前置摄像头' : '后置摄像头',
                  cameraOff: !call.isCameraEnabled,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: CommonTokens.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            CommonTokens.md,
            CommonTokens.md,
            CommonTokens.md,
            CommonTokens.xl,
          ),
          decoration: BoxDecoration(
            color: CallUiTokens.videoCallOverlayBackground,
            borderRadius: BorderRadius.circular(CommonTokens.xlRadius),
            border: Border.all(color: CallUiTokens.callSoftBorder),
          ),
          child: CallControlBar(
            actions: _buildVideoActions(call),
            dark: true,
          ),
        ),
      ],
    );
  }

  List<CallControlAction> _buildAudioActions(CallProvider call) {
    if (call.canAccept) {
      return <CallControlAction>[
        CallControlAction(
          icon: Icons.call_rounded,
          label: '接听',
          active: true,
          onTap: _handleAcceptCall,
        ),
        CallControlAction(
          icon: Icons.call_end_rounded,
          label: '拒接',
          destructive: true,
          onTap: _handleDeclineCall,
        ),
      ];
    }

    return <CallControlAction>[
      if (call.isConnected)
        CallControlAction(
          icon: call.isMuted ? Icons.mic_off_rounded : Icons.mic_none_rounded,
          label: call.isMuted ? '已静音' : '静音',
          active: call.isMuted,
          enabled: !call.isEnded,
          onTap: call.isEnded ? null : call.toggleMute,
        ),
      if (call.isConnected)
        CallControlAction(
          icon: call.isSpeakerOn
              ? Icons.volume_up_rounded
              : Icons.volume_down_rounded,
          label: call.isSpeakerOn ? '扬声器' : '听筒',
          active: call.isSpeakerOn,
          enabled: !call.isEnded,
          onTap: call.isEnded ? null : call.toggleSpeaker,
        ),
      if (call.isConnected)
        CallControlAction(
          icon: Icons.more_horiz_rounded,
          label: '更多',
          enabled: widget.onMoreTap != null,
          onTap: widget.onMoreTap,
        ),
      CallControlAction(
        icon: Icons.call_end_rounded,
        label: call.isConnected ? '挂断' : '取消',
        destructive: true,
        onTap: _handleEndCall,
      ),
    ];
  }

  List<CallControlAction> _buildVideoActions(CallProvider call) {
    if (call.canAccept) {
      return <CallControlAction>[
        CallControlAction(
          icon: Icons.call_rounded,
          label: '接听',
          active: true,
          onTap: _handleAcceptCall,
        ),
        CallControlAction(
          icon: Icons.call_end_rounded,
          label: '拒接',
          destructive: true,
          onTap: _handleDeclineCall,
        ),
      ];
    }

    if (!call.isConnected) {
      return <CallControlAction>[
        CallControlAction(
          icon: Icons.call_end_rounded,
          label: '取消',
          destructive: true,
          onTap: _handleEndCall,
        ),
      ];
    }

    return <CallControlAction>[
      CallControlAction(
        icon: call.isMuted ? Icons.mic_off_rounded : Icons.mic_none_rounded,
        label: call.isMuted ? '已静音' : '静音',
        active: call.isMuted,
        enabled: !call.isEnded,
        onTap: call.isEnded ? null : call.toggleMute,
      ),
      CallControlAction(
        icon: call.isCameraEnabled
            ? Icons.videocam_rounded
            : Icons.videocam_off_rounded,
        label: call.isCameraEnabled ? '摄像头' : '摄像头已关闭',
        active: !call.isCameraEnabled,
        enabled: !call.isEnded,
        onTap: call.isEnded ? null : call.toggleCamera,
      ),
      CallControlAction(
        icon: call.isSpeakerOn ? Icons.volume_up_rounded : Icons.hearing_rounded,
        label: call.isSpeakerOn ? '扬声器' : '听筒',
        active: call.isSpeakerOn,
        enabled: !call.isEnded,
        onTap: call.isEnded ? null : call.toggleSpeaker,
      ),
      CallControlAction(
        icon: Icons.flip_camera_ios_rounded,
        label: '切换镜头',
        enabled: !call.isEnded,
        onTap: call.isEnded ? null : call.switchCamera,
      ),
      CallControlAction(
        icon: Icons.call_end_rounded,
        label: '挂断',
        destructive: true,
        onTap: _handleEndCall,
      ),
    ];
  }
}
