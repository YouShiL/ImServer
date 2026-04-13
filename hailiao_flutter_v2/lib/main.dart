import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/providers/group_provider.dart';
import 'package:hailiao_flutter/providers/message_provider.dart';
import 'package:hailiao_flutter_v2/providers/social_notification_provider.dart';
import 'package:hailiao_flutter/services/api_service.dart';
import 'package:hailiao_flutter/sqlite_desktop_init.dart';
import 'package:hailiao_flutter_v2/domain_v2/social/social_notification_socket_binder.dart';
import 'package:hailiao_flutter_v2/screens_v2/auth/auth_gate_v2.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';
import 'package:provider/provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
  }
  await initSqfliteForCurrentPlatform();
  runApp(const HailiaoV2App());
}

final GlobalKey<NavigatorState> _v2NavigatorKey = GlobalKey<NavigatorState>();

class HailiaoV2App extends StatelessWidget {
  const HailiaoV2App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(autoLoadSavedToken: true),
        ),
        ChangeNotifierProvider<MessageProvider>(
          create: (_) => MessageProvider(),
        ),
        ChangeNotifierProvider<FriendProvider>(
          create: (_) => FriendProvider(),
        ),
        ChangeNotifierProvider<GroupProvider>(
          create: (_) => GroupProvider(),
        ),
        ChangeNotifierProvider<SocialNotificationProvider>(
          create: (_) => SocialNotificationProvider(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: _v2NavigatorKey,
        title: 'Hailiao Flutter V2',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: ChatV2Tokens.accent,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: ChatV2Tokens.pageBackground,
        ),
        builder: (BuildContext context, Widget? child) {
          ApiService.setUnauthorizedHandler(() async {
            final AuthProvider authProvider = context.read<AuthProvider>();
            await authProvider.handleUnauthorized();
            _v2NavigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute<void>(
                builder: (_) => const AuthGateV2(),
              ),
              (_) => false,
            );
          });
          return SocialNotificationSocketBinder(
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const AuthGateV2(),
      ),
    );
  }
}
