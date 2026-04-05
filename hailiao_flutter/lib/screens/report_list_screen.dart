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
    final normalized = value.replaceFirst('T', ' ').split('.').first.trim();
    if (normalized.length >= 19) {
      return normalized.substring(0, 19);
    }
    if (normalized.length == 16) {
      return '$normalized:00';
    }
    return normalized;
  }

  Widget _buildReportTile(ReportDTO report) {
    final statusText = report.statusLabel ?? '待处理';
    final statusColor = switch (report.status) {
      1 => const Color(0xFF2E7D32),
      2 => const Color(0xFFC62828),
      _ => const Color(0xFFEF6C00),
    };
    final targetText = report.targetTypeLabel ?? '用户';

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
            '举报原因：${report.reason ?? '-'}',
            style: const TextStyle(color: Color(0xFF333333)),
          ),
          if ((report.evidence ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '补充说明：${report.evidence!}',
              style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
            ),
          ],
          if ((report.handleResult ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '处理结果：${report.handleResult!}',
              style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            '提交时间：${_formatTime(report.createdAt)}',
            style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
          ),
          if ((report.handledAt ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '处理时间：${_formatTime(report.handledAt)}',
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
      appBar: AppBar(title: const Text('我的举报')),
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
                        '暂无举报记录',
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
