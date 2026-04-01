import 'package:flutter_test/flutter_test.dart';
import 'package:hailiao_flutter/models/report_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/providers/report_provider.dart';

import '../support/provider_test_fakes.dart';

void main() {
  group('ReportProvider', () {
    test('loadReports should populate reports on success', () async {
      final provider = ReportProvider(
        api: FakeReportApi()
          ..getMyReportsHandler = () async => ResponseDTO<List<ReportDTO>>(
                code: 200,
                message: 'ok',
                data: <ReportDTO>[
                  ReportDTO(id: 1, targetId: 10, reason: 'spam'),
                ],
              ),
      );

      await provider.loadReports();

      expect(provider.reports.length, 1);
      expect(provider.reports.first.id, 1);
      expect(provider.error, isNull);
      expect(provider.isLoading, isFalse);
    });

    test('createReport should prepend report on success', () async {
      final provider = ReportProvider(
        api: FakeReportApi()
          ..createReportHandler = (
            int targetId,
            int targetType,
            String reason, {
            String? evidence,
          }) async => ResponseDTO<ReportDTO>(
                code: 200,
                message: 'ok',
                data: ReportDTO(
                  id: 2,
                  targetId: targetId,
                  targetType: targetType,
                  reason: reason,
                  evidence: evidence,
                ),
              ),
      );

      final result = await provider.createReport(
        20,
        1,
        'abuse',
        evidence: 'details',
      );

      expect(result, isTrue);
      expect(provider.reports.length, 1);
      expect(provider.reports.first.reason, 'abuse');
      expect(provider.reports.first.evidence, 'details');
    });

    test('loadReports should expose api error on failure', () async {
      final provider = ReportProvider(
        api: FakeReportApi()
          ..getMyReportsHandler = () async => ResponseDTO<List<ReportDTO>>(
                code: 500,
                message: 'load failed',
                data: null,
              ),
      );

      await provider.loadReports();

      expect(provider.reports, isEmpty);
      expect(provider.error, 'load failed');
      expect(provider.isLoading, isFalse);
    });
  });
}
