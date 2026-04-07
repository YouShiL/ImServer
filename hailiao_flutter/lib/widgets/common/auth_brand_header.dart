import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/auth_ui_tokens.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';

/// 认证页（登录 / 注册）轻量品牌区，与卡片式欢迎区分离开。
class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AuthUiTokens.brandBlue,
            borderRadius: BorderRadius.circular(CommonTokens.radiusMd),
          ),
          child: const Icon(
            Icons.chat_bubble_rounded,
            size: 28,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: CommonTokens.space8),
        Text(
          '嗨聊',
          textAlign: TextAlign.center,
          style: AuthUiTokens.title.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
