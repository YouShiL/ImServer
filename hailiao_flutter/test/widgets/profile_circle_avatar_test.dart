import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/widgets/profile/profile_circle_avatar.dart';
import 'package:hailiao_flutter/widgets/profile/profile_display_utils.dart';

void main() {
  testWidgets('uses letter from title when avatar is not a network url', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ProfileCircleAvatar(
              title: '王五',
              avatarRaw: '/local/path.png',
            ),
          ),
        ),
      ),
    );
    expect(find.byType(Image), findsNothing);
    expect(find.text(ProfileDisplayTexts.listAvatarInitial('王五')), findsOneWidget);
  });

  testWidgets('renders Image for https avatarRaw', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ProfileCircleAvatar(
              title: 'X',
              avatarRaw: 'https://example.com/a.jpg',
            ),
          ),
        ),
      ),
    );
    expect(find.byType(Image), findsOneWidget);
  });
}
