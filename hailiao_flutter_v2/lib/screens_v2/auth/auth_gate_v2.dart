import 'package:flutter/material.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter_v2/domain_v2/repositories/conversation_repository.dart';
import 'package:hailiao_flutter_v2/screens_v2/auth/login_v2_page.dart';
import 'package:hailiao_flutter_v2/screens_v2/main/main_v2_shell_page.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';
import 'package:provider/provider.dart';

class AuthGateV2 extends StatefulWidget {
  const AuthGateV2({super.key});

  @override
  State<AuthGateV2> createState() => _AuthGateV2State();
}

class _AuthGateV2State extends State<AuthGateV2> {
  bool _wasAuthenticated = false;

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();

    if (auth.isAuthenticated) {
      _wasAuthenticated = true;
    } else if (_wasAuthenticated) {
      _wasAuthenticated = false;
      ApiConversationRepository.resetSessionState();
    }

    if (!auth.isReady) {
      return const Scaffold(
        backgroundColor: ChatV2Tokens.pageBackground,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (auth.isAuthenticated) {
      return const MainV2ShellPage();
    }

    return const LoginV2Page();
  }
}
