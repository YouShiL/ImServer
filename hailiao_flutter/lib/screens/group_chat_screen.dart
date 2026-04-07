import 'package:flutter/material.dart';
import 'package:hailiao_flutter/screens/chat_screen.dart';
import 'package:hailiao_flutter/widgets/chat/chat_scene.dart';

/// 群聊正式入口壳：仍注册在路由 `/chat` 下，由本类统一整理 [ChatScreen] 所需参数，避免业务侧散落 `type: 2`。
///
/// 路由表可继续指向 [ChatScreen]（[main.dart] 不变）；打开本壳或直接 push [ChatScreen] 等价。
class GroupChatScreen extends StatelessWidget {
  const GroupChatScreen({super.key, this.api});

  final ChatScreenApi? api;

  /// 与 `Navigator.pushNamed(context, '/chat', arguments: …)` 配合使用。
  static Map<String, dynamic> navigationArguments({
    required int targetId,
    required String title,
    String? avatarUrl,
  }) {
    final Map<String, dynamic> args = <String, dynamic>{
      'targetId': targetId,
      'type': ChatScene.group.conversationType,
      'title': title,
    };
    if (avatarUrl != null) {
      args['avatarUrl'] = avatarUrl;
    }
    return args;
  }

  @override
  Widget build(BuildContext context) {
    return ChatScreen(api: api);
  }
}
