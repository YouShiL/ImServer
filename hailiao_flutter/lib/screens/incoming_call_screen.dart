import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hailiao_flutter/providers/call_provider.dart';
import 'package:hailiao_flutter/screens/call_screen.dart';
import 'package:hailiao_flutter/services/call_signal_bridge.dart';
import 'package:hailiao_flutter/theme/call_ui_tokens.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/widgets/call/call_avatar_panel.dart';
import 'package:hailiao_flutter/widgets/call/call_control_bar.dart';
import 'package:hailiao_flutter/widgets/call/call_status_header.dart';
import 'package:provider/provider.dart';

class IncomingCallScreen extends StatefulWidget {
  const IncomingCallScreen({
    super.key,
    required this.payload,
  });

  final CallSignalPayload payload;

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  late final CallProvider _provider;
  Timer? _exitTimer;
  bool _handoffToCallScreen = false;

  @override
  void initState() {
    super.initState();
    _provider = CallProvider(
      callType: widget.payload.callType ?? CallMediaType.audio,
      name: (widget.payload.name?.trim().isNotEmpty ?? false)
          ? widget.payload.name!.trim()
          : '新的来电',
      stage: CallStage.waiting,
      avatarUrl: widget.payload.avatarUrl,
      subtitle: widget.payload.subtitle,
      isIncoming: true,
      isMuted: false,
      isSpeakerOn: false,
      isCameraEnabled:
          (widget.payload.callType ?? CallMediaType.audio) == CallMediaType.video,
      isFrontCamera: true,
    );
    _provider.addListener(_handleStageChange);
    CallSignalBridge.instance.attachProvider(_provider);
  }

  @override
  void dispose() {
    _exitTimer?.cancel();
    _provider.removeListener(_handleStageChange);
    if (!_handoffToCallScreen) {
      CallSignalBridge.instance.detachProvider(_provider);
      _provider.dispose();
    }
    super.dispose();
  }

  void _handleStageChange() {
    _exitTimer?.cancel();
    if (_provider.stage == CallStage.connected) {
      _handoffToCallScreen = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => CallScreen(
            name: _provider.name,
            mediaType: _provider.callType,
            stage: _provider.stage,
            avatarUrl: _provider.avatarUrl,
            subtitle: _provider.subtitle,
            provider: _provider,
            disposeProvidedProvider: true,
          ),
        ),
      );
      return;
    }

    if (_provider.stage == CallStage.declined ||
        _provider.stage == CallStage.ended) {
      _exitTimer = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) {
          return;
        }
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  void _handleAccept() {
    _provider.acceptCall();
  }

  void _handleDecline() {
    _provider.declineCall();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CallProvider>.value(
      value: _provider,
      child: Consumer<CallProvider>(
        builder: (BuildContext context, CallProvider call, _) {
          final bool isVideo = call.callType == CallMediaType.video;
          return Scaffold(
            backgroundColor: isVideo
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
                      vertical: CommonTokens.xl,
                    ),
                    child: Column(
                      children: <Widget>[
                        const Spacer(flex: 2),
                        CallAvatarPanel(name: call.name, avatarUrl: call.avatarUrl),
                        const SizedBox(height: CommonTokens.xl),
                        CallStatusHeader(
                          title: call.name,
                          status: call.incomingPrimaryStatus,
                          subtitle: call.incomingDetailSubtitle,
                          dark: isVideo,
                        ),
                        const Spacer(flex: 3),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(
                            CommonTokens.lg,
                            CommonTokens.lg,
                            CommonTokens.lg,
                            CommonTokens.xl,
                          ),
                          decoration: BoxDecoration(
                            color: isVideo
                                ? CallUiTokens.videoCallOverlayBackground
                                : CallUiTokens.callSurface.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(CommonTokens.xlRadius),
                            border: Border.all(
                              color: isVideo
                                  ? CallUiTokens.callSoftBorder
                                  : CallUiTokens.callSoftBorderLight,
                            ),
                            boxShadow: isVideo
                                ? null
                                : CallUiTokens.audioCardShadow,
                          ),
                          child: CallControlBar(
                            dark: isVideo,
                            actions: <CallControlAction>[
                              CallControlAction(
                                icon: Icons.call_rounded,
                                label: '接听',
                                active: true,
                                onTap: _handleAccept,
                              ),
                              CallControlAction(
                                icon: Icons.call_end_rounded,
                                label: '拒接',
                                destructive: true,
                                onTap: _handleDecline,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
