import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/models/blacklist_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/providers/blacklist_provider.dart';

import '../support/provider_test_fakes.dart';

void main() {
  group('BlacklistProvider', () {
    test('loadBlacklist should populate blacklist on success', () async {
      final provider = BlacklistProvider(
        api: FakeBlacklistApi(
          getBlacklistHandler: () async => ResponseDTO<List<BlacklistDTO>>(
            code: 200,
            message: 'ok',
            data: <BlacklistDTO>[
              BlacklistDTO(id: 1, userId: 100, blockedUserId: 200),
            ],
          ),
        ),
      );

      await provider.loadBlacklist();

      expect(provider.blacklist.length, 1);
      expect(provider.blacklist.first.blockedUserId, 200);
      expect(provider.error, isNull);
      expect(provider.isLoading, isFalse);
    });

    test('addToBlacklist should append item on success', () async {
      final provider = BlacklistProvider(
        api: FakeBlacklistApi(
          addToBlacklistHandler: (int blockedUserId) async =>
              ResponseDTO<BlacklistDTO>(
                code: 200,
                message: 'ok',
                data: BlacklistDTO(
                  id: 2,
                  userId: 100,
                  blockedUserId: blockedUserId,
                ),
              ),
        ),
      );

      final result = await provider.addToBlacklist(300);

      expect(result, isTrue);
      expect(provider.blacklist.length, 1);
      expect(provider.blacklist.first.blockedUserId, 300);
      expect(provider.isBlocked(300), isTrue);
    });

    test('removeFromBlacklist should remove matching item on success', () async {
      final provider = BlacklistProvider(
        api: FakeBlacklistApi(
          getBlacklistHandler: () async => ResponseDTO<List<BlacklistDTO>>(
            code: 200,
            message: 'ok',
            data: <BlacklistDTO>[
              BlacklistDTO(id: 1, userId: 100, blockedUserId: 200),
              BlacklistDTO(id: 2, userId: 100, blockedUserId: 300),
            ],
          ),
          removeFromBlacklistHandler: (int blockedUserId) async =>
              ResponseDTO<String>(
                code: 200,
                message: 'ok',
                data: 'removed',
              ),
        ),
      );

      await provider.loadBlacklist();
      final result = await provider.removeFromBlacklist(200);

      expect(result, isTrue);
      expect(provider.blacklist.length, 1);
      expect(provider.blacklist.first.blockedUserId, 300);
      expect(provider.isBlocked(200), isFalse);
    });

    test('loadBlacklist should expose api error message on failure', () async {
      final provider = BlacklistProvider(
        api: FakeBlacklistApi(
          getBlacklistHandler: () async => ResponseDTO<List<BlacklistDTO>>(
            code: 500,
            message: 'load failed',
            data: null,
          ),
        ),
      );

      await provider.loadBlacklist();

      expect(provider.blacklist, isEmpty);
      expect(provider.error, 'load failed');
      expect(provider.isLoading, isFalse);
    });
  });
}
