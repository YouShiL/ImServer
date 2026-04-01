import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/models/auth_response_dto.dart';
import 'package:hailiao_flutter/models/login_request_dto.dart';
import 'package:hailiao_flutter/models/register_request_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/screens/register_screen.dart';
import '../support/auth_test_fakes.dart';
import '../support/screen_test_helpers.dart';

void main() {
  testWidgets('RegisterScreen should submit and show api error', (
    WidgetTester tester,
  ) async {
    final provider = AuthProvider(
      api: FakeAuthApi(
        registerHandler: (RegisterRequestDTO request) async =>
            ResponseDTO<AuthResponseDTO>(
              code: 400,
              message: 'nickname exists',
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
      routes: buildTextRoutes(<String>['/login', '/home']),
      home: const RegisterScreen(),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'tester');
    await tester.enterText(find.byType(TextFormField).at(1), '13800000000');
    await tester.enterText(find.byType(TextFormField).at(2), 'secret1');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    await tester.pump();

    expect(find.text('nickname exists'), findsOneWidget);
  });
}
