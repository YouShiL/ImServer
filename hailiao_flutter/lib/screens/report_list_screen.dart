import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/report_dto.dart';
import 'package:hailiao_flutter/providers/report_provider.dart';
import 'package:provider/provider.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ReportProvider>().loadReports();
      }
    });
  }

  String _formatTime(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }
    final normalized = value.replaceFirst('T', ' ').split('.').first;
    return normalized.length >= 16 ? normalized.substring(0, 16) : normalized;
  }

  Widget _buildReportTile(ReportDTO report) {
    final statusText = report.statusLabel ?? '\u5f85\u5904\u7406';
    final statusColor = switch (report.status) {
      1 => const Color(0xFF2E7D32),
      2 => const Color(0xFFC62828),
      _ => const Color(0xFFEF6C00),
    };
    final targetText = report.targetTypeLabel ?? '\u7528\u6237';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$targetText #${report.targetId ?? '-'}',
                  style: const TextStyle(
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '\u4e3e\u62a5\u539f\u56e0\uff1a${report.reason ?? '-'}',
            style: const TextStyle(color: Color(0xFF333333)),
          ),
          if ((report.evidence ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '\u8865\u5145\u8bf4\u660e\uff1a${report.evidence!}',
              style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
            ),
          ],
          if ((report.handleResult ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '\u5904\u7406\u7ed3\u679c\uff1a${report.handleResult!}',
              style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            '\u63d0\u4ea4\u65f6\u95f4\uff1a${_formatTime(report.createdAt)}',
            style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
          ),
          if ((report.handledAt ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '\u5904\u7406\u65f6\u95f4\uff1a${_formatTime(report.handledAt)}',
              style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    final reports = provider.reports;
    return Scaffold(
      appBar: AppBar(title: const Text('\u6211\u7684\u4e3e\u62a5')),
      body: provider.isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            )
          : provider.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF666666)),
                    ),
                  ),
                )
              : reports.isEmpty
                  ? const Center(
                      child: Text(
                        '\u6682\u65e0\u4e3e\u62a5\u8bb0\u5f55',
                        style: TextStyle(color: Color(0xFF9E9E9E)),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: context.read<ReportProvider>().loadReports,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        children: reports.map(_buildReportTile).toList(),
                      ),
                    ),
    );
  }
}
