import 'package:flutter/material.dart';
import 'package:hailiao_flutter/utils/network_avatar_url.dart';
import 'package:hailiao_flutter/widgets/profile/profile_display_utils.dart';

/// 列表 / 弹窗共用的圆形头像：仅当 [avatarRaw] 为 http(s) 时用网络图，否则展示与 [title] 一致的首字。
class ProfileCircleAvatar extends StatelessWidget {
  const ProfileCircleAvatar({
    super.key,
    required this.title,
    this.avatarRaw,
    this.size = 40,
    this.fontSize = 16,
  });

  final String title;
  final String? avatarRaw;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final String initial = ProfileDisplayTexts.listAvatarInitial(title);
    final Color tint = Theme.of(context).primaryColor;
    final String? url = httpOrHttpsAvatarUrlOrNull(avatarRaw);
    if (url != null) {
      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder:
                (BuildContext context, Object error, StackTrace? stackTrace) =>
                    _letterAvatar(context, initial, tint),
          ),
        ),
      );
    }
    return _letterAvatar(context, initial, tint);
  }

  Widget _letterAvatar(BuildContext context, String initial, Color tint) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: tint.withValues(alpha: 0.1),
      child: Text(
        initial,
        style: TextStyle(
          color: tint,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
