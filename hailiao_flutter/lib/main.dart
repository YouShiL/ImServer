import 'package:flutter/material.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/providers/blacklist_provider.dart';
import 'package:hailiao_flutter/providers/content_audit_provider.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/providers/group_provider.dart';
import 'package:hailiao_flutter/providers/message_provider.dart';
import 'package:hailiao_flutter/providers/report_provider.dart';
import 'package:hailiao_flutter/screens/chat_screen.dart';
import 'package:hailiao_flutter/screens/content_audit_list_screen.dart';
import 'package:hailiao_flutter/screens/group_detail_screen.dart';
import 'package:hailiao_flutter/screens/group_list_screen.dart';
import 'package:hailiao_flutter/screens/home_screen.dart';
import 'package:hailiao_flutter/screens/login_screen.dart';
import 'package:hailiao_flutter/screens/report_list_screen.dart';
import 'package:hailiao_flutter/screens/register_screen.dart';
import 'package:hailiao_flutter/screens/security_screen.dart';
import 'package:hailiao_flutter/screens/user_detail_screen.dart';
import 'package:hailiao_flutter/services/api_service.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class CheckAuthWidget extends StatefulWidget {
  const CheckAuthWidget({super.key});

  @override
  State<CheckAuthWidget> createState() => _CheckAuthWidgetState();
}

class _CheckAuthWidgetState extends State<CheckAuthWidget> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAuthenticated) {
        await authProvider.refreshUserInfo();
      }
      if (mounted) {
        setState(() {
          _checking = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final authProvider = context.watch<AuthProvider>();
    if (authProvider.isAuthenticated) {
      return const HomeScreen();
    }
    return const LoginScreen();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme(
      bodyLarge: const TextStyle(
        fontFamily: 'Source Han Sans SC',
        fontSize: 16,
        color: Color(0xFF333333),
      ),
      bodyMedium: const TextStyle(
        fontFamily: 'Source Han Sans SC',
        fontSize: 14,
        color: Color(0xFF666666),
      ),
      bodySmall: const TextStyle(
        fontFamily: 'Source Han Sans SC',
        fontSize: 12,
        color: Color(0xFF666666),
      ),
      titleLarge: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF333333),
      ),
      titleMedium: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 14,
        color: Color(0xFF666666),
      ),
      labelLarge: const TextStyle(fontFamily: 'Roboto'),
      labelMedium: const TextStyle(fontFamily: 'Roboto'),
      labelSmall: const TextStyle(fontFamily: 'Roboto'),
    );

    final theme = ThemeData(
      fontFamily: 'Source Han Sans SC',
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      iconTheme: const IconThemeData(),
      primaryColor: const Color(0xFF1E88E5),
      primaryColorDark: const Color(0xFF1565C0),
      primaryColorLight: const Color(0xFF42A5F5),
      colorScheme: ColorScheme.fromSwatch().copyWith(
        secondary: const Color(0xFFFF4081),
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      cardColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 1,
        titleTextStyle: TextStyle(
          fontFamily: 'Source Han Sans SC',
          color: Color(0xFF333333),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Color(0xFF333333)),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: const Color(0xFF1E88E5),
        textTheme: ButtonTextTheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
        ),
        hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(create: (_) => FriendProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => BlacklistProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => ContentAuditProvider()),
      ],
      child: Builder(
        builder: (context) {
          ApiService.setUnauthorizedHandler(() async {
            final authProvider = context.read<AuthProvider>();
            await authProvider.handleUnauthorized();
            final navigator = appNavigatorKey.currentState;
            if (navigator != null) {
              navigator.pushNamedAndRemoveUntil('/login', (_) => false);
            }
          });

          return MaterialApp(
            navigatorKey: appNavigatorKey,
            title: '海聊',
            debugShowCheckedModeBanner: false,
            theme: theme,
            initialRoute: '/checkAuth',
            routes: {
              '/checkAuth': (context) => const CheckAuthWidget(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => RegisterScreen(),
              '/home': (context) => const HomeScreen(),
              '/chat': (context) => ChatScreen(),
              '/groups': (context) => const GroupListScreen(),
              '/group-detail': (context) => const GroupDetailScreen(),
              '/content-audit-list': (context) => const ContentAuditListScreen(),
              '/report-list': (context) => const ReportListScreen(),
              '/security': (context) => const SecurityScreen(),
              '/user-detail': (context) => const UserDetailScreen(),
            },
          );
        },
      ),
    );
  }
}
