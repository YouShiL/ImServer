import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';

/// 聊天页定制 AppBar：居中标题、左侧返回/关闭、右侧操作列。
class ChatConversationAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChatConversationAppBar({
    super.key,
    required this.selectionMode,
    required this.centerTitle,
    required this.onLeadingPressed,
    required this.actions,
  });

  final bool selectionMode;
  final Widget centerTitle;
  final VoidCallback onLeadingPressed;
  final List<Widget> actions;

  @override
  Size get preferredSize =>
      Size.fromHeight(ChatUiTokens.appBarToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final double h = ChatUiTokens.appBarToolbarHeight;
    return AppBar(
      toolbarHeight: h,
      backgroundColor: ChatUiTokens.chatAppBarBackground,
      foregroundColor: ChatUiTokens.incomingBubbleText,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: 0,
      titleSpacing: 0,
      title: SizedBox(
        width: double.infinity,
        height: h,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: <Widget>[
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      (MediaQuery.sizeOf(context).width - 112).clamp(0, 900),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: centerTitle,
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(
                    selectionMode ? Icons.close : Icons.arrow_back_ios_new_rounded,
                  ),
                  iconSize: selectionMode ? 24 : 20,
                  onPressed: onLeadingPressed,
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
