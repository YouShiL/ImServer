import 'package:flutter/material.dart';

/// 隐私政策（最小合规版正文，后续可由法务替换为正式版本）。
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String _body = '''
嗨聊非常重视你的个人信息与隐私保护。本政策说明我们收集哪些信息、如何使用、是否共享、如何保障安全以及你享有的权利。使用本应用即表示你同意本政策描述的处理方式。

一、我们收集哪些信息
1. 账号与身份相关：如手机号、昵称、登录凭证及为保障账号安全所需的设备或会话信息（以实际功能为准）。
2. 使用过程信息：为保障聊天、同步与排错，可能产生消息传输、操作日志、崩溃统计等技术数据。
3. 你主动提供的信息：如你在个人资料、客服反馈中填写的内容。

二、我们如何使用
1. 用于注册登录、提供即时通讯与相关功能、保障账号与系统安全。
2. 用于改进产品体验、发现与修复故障，在匿名或去标识化前提下用于统计分析。
3. 在法律法规要求或征得你同意的情况下，用于其他特定目的。

三、是否共享
1. 我们不会向第三方出售你的个人信息。
2. 仅在法律法规明确允许或要求、为履行法定义务、或为保护用户及公众重大利益时，我们可能依法向主管机关或合作方提供必要信息。
3. 如涉及受托处理（如云存储、统计服务），我们会要求受托方遵守严格的保密与安全义务。

四、数据安全
我们采取合理的技术与管理措施保护信息安全，防止未经授权的访问、泄露、篡改或丢失。请你同时妥善保管设备与密码。

五、你的权利
在适用法律允许的范围内，你可能享有查询、更正、删除个人信息、撤回同意、注销账号等权利。具体路径以应用内「设置」「安全」或客服指引为准。

如对本政策有疑问，请通过应用内反馈或产品公示的客服渠道联系我们。我们可能适时更新本政策，并以适当方式提示你查阅更新后的版本。
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('隐私政策'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SelectableText(
            _body.trim(),
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
