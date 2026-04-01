import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/models/content_audit_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/providers/content_audit_provider.dart';

import '../support/provider_test_fakes.dart';

void main() {
  group('ContentAuditProvider', () {
    test('loadAudits should populate audits on success', () async {
      final provider = ContentAuditProvider(
        api: FakeContentAuditApi()
          ..getMyContentAuditsHandler =
              () async => ResponseDTO<List<ContentAuditDTO>>(
                    code: 200,
                    message: 'ok',
                    data: <ContentAuditDTO>[
                      ContentAuditDTO(id: 1, targetId: 99, content: 'hello'),
                    ],
                  ),
      );

      await provider.loadAudits();

      expect(provider.audits.length, 1);
      expect(provider.audits.first.id, 1);
      expect(provider.error, isNull);
      expect(provider.isLoading, isFalse);
    });

    test('loadAudits should expose api error on failure', () async {
      final provider = ContentAuditProvider(
        api: FakeContentAuditApi()
          ..getMyContentAuditsHandler =
              () async => ResponseDTO<List<ContentAuditDTO>>(
                    code: 500,
                    message: 'load failed',
                    data: null,
                  ),
      );

      await provider.loadAudits();

      expect(provider.audits, isEmpty);
      expect(provider.error, 'load failed');
      expect(provider.isLoading, isFalse);
    });
  });
}
