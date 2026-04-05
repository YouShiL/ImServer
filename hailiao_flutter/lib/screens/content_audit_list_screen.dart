import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/content_audit_dto.dart';
import 'package:hailiao_flutter/providers/content_audit_provider.dart';
import 'package:provider/provider.dart';

class ContentAuditListScreen extends StatefulWidget {
  const ContentAuditListScreen({super.key});

  @override
  State<ContentAuditListScreen> createState() => _ContentAuditListScreenState();
}

class _ContentAuditListScreenState extends State<ContentAuditListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ContentAuditProvider>().loadAudits();
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

  Widget _buildAuditTile(ContentAuditDTO audit) {
    final statusText = audit.statusLabel ?? '待审核';
    final statusColor = switch (audit.status) {
      1 => const Color(0xFF2E7D32),
      _ => const Color(0xFFEF6C00),
    };
    final contentType = audit.contentTypeLabel ?? '文本';
    final resultText = audit.finalResultLabel ?? '待处理';

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
                  '$contentType #${audit.targetId ?? '-'}',
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
            '审核结果：$resultText',
            style: const TextStyle(color: Color(0xFF333333)),
          ),
          if ((audit.handleNote ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '处理说明：${audit.handleNote!}',
              style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
            ),
          ],
          if ((audit.content ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '内容摘要：${audit.content!}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            '提交时间：${_formatTime(audit.createdAt)}',
            style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
          ),
          if ((audit.handledAt ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '处理时间：${_formatTime(audit.handledAt)}',
              style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContentAuditProvider>();
    final audits = provider.audits;
    return Scaffold(
      appBar: AppBar(title: const Text('我的内容审核')),
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
              : audits.isEmpty
                  ? const Center(
                      child: Text(
                        '暂无审核记录',
                        style: TextStyle(color: Color(0xFF9E9E9E)),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh:
                          context.read<ContentAuditProvider>().loadAudits,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        children: audits.map(_buildAuditTile).toList(),
                      ),
                    ),
    );
  }
}
