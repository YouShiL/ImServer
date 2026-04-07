import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/utils/network_avatar_url.dart';

void main() {
  test('httpOrHttpsAvatarUrlOrNull accepts trim and valid schemes', () {
    expect(httpOrHttpsAvatarUrlOrNull('  https://a/b  '), 'https://a/b');
    expect(httpOrHttpsAvatarUrlOrNull('http://x'), 'http://x');
  });

  test('httpOrHttpsAvatarUrlOrNull rejects empty and non-http schemes', () {
    expect(httpOrHttpsAvatarUrlOrNull(null), isNull);
    expect(httpOrHttpsAvatarUrlOrNull(''), isNull);
    expect(httpOrHttpsAvatarUrlOrNull('   '), isNull);
    expect(httpOrHttpsAvatarUrlOrNull('ftp://a'), isNull);
    expect(httpOrHttpsAvatarUrlOrNull('relative/path'), isNull);
    expect(httpOrHttpsAvatarUrlOrNull('data:image/png;base64,xx'), isNull);
  });

  test('isHttpOrHttpsAvatarUrl matches httpOrHttpsAvatarUrlOrNull nullability', () {
    expect(isHttpOrHttpsAvatarUrl('https://x'), isTrue);
    expect(isHttpOrHttpsAvatarUrl('not-url'), isFalse);
    expect(isHttpOrHttpsAvatarUrl(null), isFalse);
  });
}
