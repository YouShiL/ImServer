import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';
import 'package:hailiao_flutter/widgets/chat/chat_scene.dart';

/// 聊天页 AppBar 中间标题区（单聊在线点 + 副标题 / 群聊人数与静音文案）。
class ChatAppBarTitle extends StatelessWidget {
  const ChatAppBarTitle({
    super.key,
    required this.scene,
    required this.title,
    required this.centered,
    this.singleStatusLabel = '状态同步中',
    this.groupSubtitle = '',
  });

  final ChatScene scene;
  final String title;
  final bool centered;
  final String singleStatusLabel;
  final String groupSubtitle;

  @override
  Widget build(BuildContext context) {
    final TextAlign align = centered ? TextAlign.center : TextAlign.start;
    final CrossAxisAlignment cx =
        centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;

    if (scene == ChatScene.single) {
      final bool online = singleStatusLabel == '在线';
      return Column(
        crossAxisAlignment: cx,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: align,
            style: ChatUiTokens.chatHeaderTitleText,
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment:
                centered ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: online ? Colors.green : ChatUiTokens.headerStatusIdle,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  singleStatusLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: align,
                  style: ChatUiTokens.chatHeaderSubtitleText.copyWith(
                    color: ChatUiTokens.subtleText.withValues(alpha: 0.9),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: cx,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
          style: ChatUiTokens.chatHeaderTitleText,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            groupSubtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: align,
            style: ChatUiTokens.chatHeaderSubtitleText.copyWith(
              color: ChatUiTokens.subtleText.withValues(alpha: 0.9),
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
