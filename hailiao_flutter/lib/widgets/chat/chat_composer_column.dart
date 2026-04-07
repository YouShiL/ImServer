import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/emoji.dart';
import 'package:hailiao_flutter/widgets/chat/chat_attach_panel.dart';
import 'package:hailiao_flutter/widgets/chat/chat_blocked_banner.dart';
import 'package:hailiao_flutter/widgets/chat/chat_emoji_panel.dart';
import 'package:hailiao_flutter/widgets/chat/chat_input_actions.dart';
import 'package:hailiao_flutter/widgets/chat/chat_input_bar.dart';
import 'package:hailiao_flutter/widgets/chat/chat_input_panel_host.dart';
import 'package:hailiao_flutter/widgets/chat/chat_input_reply_banner.dart';
import 'package:hailiao_flutter/widgets/chat/chat_scene.dart';
import 'package:hailiao_flutter/widgets/chat/chat_status_banner.dart';

/// 聊天页底部整段 Composer：拉黑条、群禁言提示、回复条、输入条、表情/附件面板。
///
/// 单聊 / 群聊共用；差异通过 [scene]、[inputEnabled]、[showGroupMuteHint] 等参数注入。
class ChatComposerColumn extends StatelessWidget {
  const ChatComposerColumn({
    super.key,
    required this.scene,
    required this.controller,
    required this.focusNode,
    required this.inputEnabled,
    required this.canSendMessage,
    required this.hintText,
    required this.isTyping,
    required this.isVoiceMode,
    required this.voiceModeAllowed,
    required this.onVoiceModeToggle,
    required this.isEmojiPanelOpen,
    required this.isAttachPanelOpen,
    required this.onEmojiPanelToggle,
    required this.onAttachPanelToggle,
    required this.onTextChanged,
    required this.onSubmitText,
    required this.onHoldToSpeakTap,
    required this.showBlockedBanner,
    required this.showGroupMuteHint,
    required this.replyBannerVisible,
    required this.replyBannerEditing,
    required this.replySummaryText,
    required this.onCloseReplyBanner,
    required this.onDeleteLastComposerChar,
    required this.onClearComposerFromEmojiPanel,
    required this.onEmojiAuxiliarySend,
    required this.onOpenGalleryChooser,
    required this.onPickCameraImage,
    required this.onAttachFileStub,
    this.onVoiceCall,
    this.onVideoCall,
    this.showAttachmentActions = true,
  });

  final ChatScene scene;

  final TextEditingController controller;
  final FocusNode focusNode;

  /// 输入框与面板可操作（未拉黑、未全员禁言等）。
  final bool inputEnabled;

  /// 是否允许发起发送（与 [inputEnabled] 通常一致，预留与草稿等业务区分）。
  final bool canSendMessage;

  final String hintText;
  final bool isTyping;
  final bool isVoiceMode;
  final bool voiceModeAllowed;
  final VoidCallback? onVoiceModeToggle;

  final bool isEmojiPanelOpen;
  final bool isAttachPanelOpen;
  final VoidCallback? onEmojiPanelToggle;
  final VoidCallback? onAttachPanelToggle;

  final ValueChanged<String> onTextChanged;
  final VoidCallback onSubmitText;
  final VoidCallback? onHoldToSpeakTap;

  final bool showBlockedBanner;
  final bool showGroupMuteHint;

  final bool replyBannerVisible;
  final bool replyBannerEditing;
  final String replySummaryText;
  final VoidCallback onCloseReplyBanner;

  final VoidCallback onDeleteLastComposerChar;
  final VoidCallback onClearComposerFromEmojiPanel;
  final VoidCallback onEmojiAuxiliarySend;

  final VoidCallback onOpenGalleryChooser;
  final VoidCallback onPickCameraImage;
  final VoidCallback onAttachFileStub;
  final VoidCallback? onVoiceCall;
  final VoidCallback? onVideoCall;

  /// 为 false 时禁用「+」与附件相关回调（默认 true）。
  final bool showAttachmentActions;

  @override
  Widget build(BuildContext context) {
    final bool effectiveEnabled = inputEnabled && canSendMessage;
    final bool attachEnabled =
        effectiveEnabled && showAttachmentActions;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (showBlockedBanner) const ChatBlockedBanner(),
        if (showGroupMuteHint)
          ChatStatusBanner(
            icon: Icons.mic_off_outlined,
            title: '全员禁言中',
            subtitle: '暂不可在本群发送消息',
            tone: ChatStatusBannerTone.warning,
            compact: true,
          ),
        ChatInputReplyBanner(
          visible: replyBannerVisible,
          isEditing: replyBannerEditing,
          summaryText: replySummaryText,
          onClose: onCloseReplyBanner,
        ),
        ChatInputBar(
          controller: controller,
          focusNode: focusNode,
          enabled: effectiveEnabled,
          hintText: hintText,
          isVoiceMode: isVoiceMode,
          voiceModeAllowed: voiceModeAllowed && effectiveEnabled,
          onVoiceModeToggle: effectiveEnabled ? onVoiceModeToggle : null,
          isEmojiPanelOpen: isEmojiPanelOpen,
          isAttachPanelOpen: isAttachPanelOpen,
          onEmojiPressed: attachEnabled ? onEmojiPanelToggle : null,
          onAttachPressed: attachEnabled ? onAttachPanelToggle : null,
          hasComposeText: isTyping,
          onTextSubmitted:
              effectiveEnabled && isTyping ? onSubmitText : null,
          onHoldToSpeakTap: effectiveEnabled ? onHoldToSpeakTap : null,
          onChanged: onTextChanged,
        ),
        ChatInputPanelHost(
          children: <Widget>[
            if (isEmojiPanelOpen)
              ChatEmojiPanel(
                controller: controller,
                canCompose: effectiveEnabled,
                onEmojiSelected: (Emoji emoji) {
                  ChatInputActions.insertEmoji(emoji, controller);
                  onTextChanged(controller.text);
                },
                onDeleteLast: onDeleteLastComposerChar,
                onDeleteLongClear: onClearComposerFromEmojiPanel,
                onAuxiliarySend: onEmojiAuxiliarySend,
              ),
            if (isAttachPanelOpen)
              ChatAttachPanel(
                isSingleChat: ChatInputActions.attachPanelIsSingleChat(scene),
                onGallery: onOpenGalleryChooser,
                onCamera: onPickCameraImage,
                onFile: onAttachFileStub,
                onVoiceCall: ChatInputActions.attachPanelIsSingleChat(scene)
                    ? onVoiceCall
                    : null,
                onVideoCall: ChatInputActions.attachPanelIsSingleChat(scene)
                    ? onVideoCall
                    : null,
              ),
          ],
        ),
      ],
    );
  }
}
