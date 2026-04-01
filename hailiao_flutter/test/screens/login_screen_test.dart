import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/models/auth_response_dto.dart';
import 'package:hailiao_flutter/models/login_request_dto.dart';
import 'package:hailiao_flutter/models/register_request_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/screens/login_screen.dart';
import '../support/auth_test_fakes.dart';
import '../support/screen_test_helpers.dart';

void main() {
  testWidgets('LoginScreen should submit and show api error', (
    WidgetTester tester,
  ) async {
    final provider = AuthProvider(
      api: FakeAuthApi(
        loginHandler: (LoginRequestDTO request) async =>
            ResponseDTO<AuthResponseDTO>(
              code: 400,
              message: 'bad credentials',
              data: null,
            ),
      ),
      storage: FakeAuthStorage(),
      deviceInfoProvider: FakeDeviceInfoProvider(),
      autoLoadSavedToken: false,
    );

    await pumpAuthScreenApp(
      tester,
      authProvider: provider,
      routes: buildTextRoutes(<String>['/register', '/home']),
      home: const LoginScreen(),
    );

    await tester.enterText(find.byType(TextFormField).at(0), '13800000000');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    await tester.pump();

    expect(find.text('bad credentials'), findsOneWidget);
  });
}
