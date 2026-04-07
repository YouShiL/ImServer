import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/theme/conversation_ui_tokens.dart';
import 'package:hailiao_flutter/utils/network_avatar_url.dart';
import 'package:hailiao_flutter/widgets/profile/profile_display_utils.dart';

/// 列表行圆形头像：与会话列表同款规则——仅 `http`/`https` 加载网络图，失败则字头像；
/// 字头像首字须与行标题同源（一般传入 [ProfileDisplayTexts.singleChatDisplayTitle] 的结果）。
class ProfileListAvatar extends StatelessWidget {
  const ProfileListAvatar({
    super.key,
    required this.title,
    this.imageUrl,
    this.size = 56,
    this.highlight = false,
  });

  final String title;
  final String? imageUrl;
  final double size;

  /// 与会话未读高亮背景一致；好友行通常传 `false`。
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final String initial = ProfileDisplayTexts.listAvatarInitial(title);
    final double radius = size / 2;
    final String? url = httpOrHttpsAvatarUrlOrNull(imageUrl);
    if (url != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          width: size,
          height: size,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (BuildContext context, Object error,
                    StackTrace? stackTrace) =>
                _textAvatar(initial, radius),
          ),
        ),
      );
    }
    return _textAvatar(initial, radius);
  }

  Widget _textAvatar(String initial, double radius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: highlight
            ? ConversationUiTokens.avatarHighlightBackground
            : ConversationUiTokens.avatarBackground,
      ),
      child: Center(
        child: Text(
          initial,
          style: CommonTokens.subtitle.copyWith(
            color: ConversationUiTokens.avatarText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
