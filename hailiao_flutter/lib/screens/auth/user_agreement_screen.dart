import 'package:flutter/material.dart';

/// 用户协议（最小合规版正文，后续可由法务替换为正式版本）。
class UserAgreementScreen extends StatelessWidget {
  const UserAgreementScreen({super.key});

  static const String _body = '''
欢迎使用嗨聊服务。在使用本应用前，请你仔细阅读本协议。当你点击同意并完成注册或登录，即表示你已阅读并理解本协议的全部内容。

一、服务说明
1. 嗨聊向你提供即时通讯、会话管理及相关辅助功能。我们会尽力保障服务的连续性与安全性，但因网络、设备、第三方服务或不可抗力导致的中断、延迟或数据丢失，我们将在法律法规允许的范围内承担责任。
2. 我们可能根据业务需要对功能进行升级、调整或下线，并将通过合理方式予以提示。

二、用户行为规范
1. 你应保证注册信息真实、准确，并妥善保管账号与密码，对帐号下发生的一切行为负责。
2. 你不得利用本服务从事违法违规、侵害他人合法权益、传播恶意程序或垃圾信息等行为。
3. 我们有权依据法律法规及服务规则，对违规内容或行为采取警告、限制功能、暂停或终止服务等措施。

三、账号责任
1. 一个手机号对应一个账号（以产品规则为准）。未经允许，不得转让、借用或售卖账号。
2. 如发现账号被盗用或存在安全风险，请你及时通过应用内安全或客服渠道处理。

四、风险提示
1. 互联网传输并非绝对安全，请你理解并自行评估使用即时通讯的风险。
2. 请你自行备份重要信息；因你未尽到合理注意义务导致的损失，我们在法律法规允许的范围内不承担责任。

五、联系方式
如对本协议有疑问或需要投诉、举报，可通过应用内反馈入口或产品公示的客服渠道与我们联系。我们将在合理期限内予以答复。
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户协议'),
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
