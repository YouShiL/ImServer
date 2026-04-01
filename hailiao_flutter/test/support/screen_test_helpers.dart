import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/providers/blacklist_provider.dart';
import 'package:hailiao_flutter/providers/content_audit_provider.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/providers/group_provider.dart';
import 'package:hailiao_flutter/providers/message_provider.dart';
import 'package:hailiao_flutter/providers/report_provider.dart';
import 'package:provider/provider.dart';

String routeLabel(String routeName) {
  return routeName.startsWith('/') ? routeName.substring(1) : routeName;
}

WidgetBuilder buildTextRoute(String label) {
  return (_) => Scaffold(body: Text(label));
}

Map<String, WidgetBuilder> buildTextRoutes(Iterable<String> routeNames) {
  return <String, WidgetBuilder>{
    for (final String routeName in routeNames)
      routeName: buildTextRoute(routeLabel(routeName)),
  };
}

Future<void> pumpHomeScreenApp(
  WidgetTester tester, {
  required AuthProvider authProvider,
  required FriendProvider friendProvider,
  required MessageProvider messageProvider,
  required Widget home,
  Map<String, WidgetBuilder> routes = const <String, WidgetBuilder>{},
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<FriendProvider>.value(value: friendProvider),
        ChangeNotifierProvider<MessageProvider>.value(value: messageProvider),
      ],
      child: MaterialApp(routes: routes, home: home),
    ),
  );
}

Future<void> pumpHomeGroupFlowApp(
  WidgetTester tester, {
  required AuthProvider authProvider,
  required FriendProvider friendProvider,
  required MessageProvider messageProvider,
  required GroupProvider groupProvider,
  required Widget home,
  Map<String, WidgetBuilder> routes = const <String, WidgetBuilder>{},
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<FriendProvider>.value(value: friendProvider),
        ChangeNotifierProvider<MessageProvider>.value(value: messageProvider),
        ChangeNotifierProvider<GroupProvider>.value(value: groupProvider),
      ],
      child: MaterialApp(routes: routes, home: home),
    ),
  );
}

Future<void> pumpHomeGroupChatFlowApp(
  WidgetTester tester, {
  required AuthProvider authProvider,
  required FriendProvider friendProvider,
  required MessageProvider messageProvider,
  required BlacklistProvider blacklistProvider,
  required GroupProvider groupProvider,
  required Widget home,
  Map<String, WidgetBuilder> routes = const <String, WidgetBuilder>{},
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<FriendProvider>.value(value: friendProvider),
        ChangeNotifierProvider<MessageProvider>.value(value: messageProvider),
        ChangeNotifierProvider<BlacklistProvider>.value(
          value: blacklistProvider,
        ),
        ChangeNotifierProvider<GroupProvider>.value(value: groupProvider),
      ],
      child: MaterialApp(routes: routes, home: home),
    ),
  );
}

Future<void> pumpHomeChatUserFlowApp(
  WidgetTester tester, {
  required AuthProvider authProvider,
  required FriendProvider friendProvider,
  required MessageProvider messageProvider,
  required BlacklistProvider blacklistProvider,
  required Widget home,
  Map<String, WidgetBuilder> routes = const <String, WidgetBuilder>{},
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<FriendProvider>.value(value: friendProvider),
        ChangeNotifierProvider<MessageProvider>.value(value: messageProvider),
        ChangeNotifierProvider<BlacklistProvider>.value(
          value: blacklistProvider,
        ),
      ],
      child: MaterialApp(routes: routes, home: home),
    ),
  );
}

Future<void> pumpHomeReportFlowApp(
  WidgetTester tester, {
  required AuthProvider authProvider,
  required FriendProvider friendProvider,
  required MessageProvider messageProvider,
  required ReportProvider reportProvider,
  required Widget home,
  Map<String, WidgetBuilder> routes = const <String, WidgetBuilder>{},
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<FriendProvider>.value(value: friendProvider),
        ChangeNotifierProvider<MessageProvider>.value(value: messageProvider),
        ChangeNotifierProvider<ReportProvider>.value(value: reportProvider),
      ],
      child: MaterialApp(routes: routes, home: home),
    ),
  );
}

Future<void> pumpHomeContentAuditFlowApp(
  WidgetTester tester, {
  required AuthProvider authProvider,
  required FriendProvider friendProvider,
  required MessageProvider messageProvider,
  required ContentAuditProvider contentAuditProvider,
  required Widget home,
  Map<String, WidgetBuilder> routes = const <String, WidgetBuilder>{},
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<FriendProvider>.value(value: friendProvider),
        ChangeNotifierProvider<MessageProvider>.value(value: messageProvider),
        ChangeNotifierProvider<ContentAuditProvider>.value(
          value: contentAuditProvider,
        ),
      ],
      child: MaterialApp(routes: routes, home: home),
    ),
  );
}

Future<void> pumpAuthScreenApp(
  WidgetTester tester, {
  required AuthProvider authProvider,
  required Widget home,
  Map<String, WidgetBuilder> routes = const <String, WidgetBuilder>{},
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: MaterialApp(routes: routes, home: home),
    ),
  );
}

Future<void> pumpReportScreenApp(
  WidgetTester tester, {
  required ReportProvider reportProvider,
  required Widget home,
  Map<String, WidgetBuilder> routes = const <String, WidgetBuilder>{},
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<ReportProvider>.value(
      value: reportProvider,
      child: MaterialApp(routes: routes, home: home),
    ),
  );
}

Future<void> pumpContentAuditScreenApp(
  WidgetTester tester, {
  required ContentAuditProvider contentAuditProvider,
  required Widget home,
  Map<String, WidgetBuilder> routes = const <String, WidgetBuilder>{},
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<ContentAuditProvider>.value(
      value: contentAuditProvider,
      child: MaterialApp(routes: routes, home: home),
    ),
  );
}

Future<void> pumpGroupListScreenApp(
  WidgetTester tester, {
  required GroupProvider groupProvider,
  required Widget home,
  Map<String, WidgetBuilder> routes = const <String, WidgetBuilder>{},
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<GroupProvider>.value(
      value: groupProvider,
      child: MaterialApp(routes: routes, home: home),
    ),
  );
}

Future<void> pumpChatScreenApp(
  WidgetTester tester, {
  required AuthProvider authProvider,
  required MessageProvider messageProvider,
  required BlacklistProvider blacklistProvider,
  required WidgetBuilder builder,
  required Map<String, dynamic> arguments,
  Map<String, WidgetBuilder> routes = const <String, WidgetBuilder>{},
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<MessageProvider>.value(value: messageProvider),
        ChangeNotifierProvider<BlacklistProvider>.value(
          value: blacklistProvider,
        ),
      ],
      child: MaterialApp(
        routes: routes,
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: RouteSettings(name: '/', arguments: arguments),
          builder: builder,
        ),
      ),
    ),
  );
}

Future<void> pumpGroupDetailScreenApp(
  WidgetTester tester, {
  required AuthProvider authProvider,
  required GroupProvider groupProvider,
  required WidgetBuilder builder,
  required Map<String, dynamic> arguments,
  Map<String, WidgetBuilder> routes = const <String, WidgetBuilder>{},
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<GroupProvider>.value(value: groupProvider),
      ],
      child: MaterialApp(
        routes: routes,
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: RouteSettings(name: '/', arguments: arguments),
          builder: builder,
        ),
      ),
    ),
  );
}

Future<void> pumpUserDetailScreenApp(
  WidgetTester tester, {
  required AuthProvider authProvider,
  required FriendProvider friendProvider,
  required BlacklistProvider blacklistProvider,
  required WidgetBuilder builder,
  required Map<String, dynamic> arguments,
  Map<String, WidgetBuilder> routes = const <String, WidgetBuilder>{},
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<FriendProvider>.value(value: friendProvider),
        ChangeNotifierProvider<BlacklistProvider>.value(
          value: blacklistProvider,
        ),
      ],
      child: MaterialApp(
        routes: routes,
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: RouteSettings(name: '/', arguments: arguments),
          builder: builder,
        ),
      ),
    ),
  );
}
