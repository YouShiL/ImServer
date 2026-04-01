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
    final normalized = value.replaceFirst('T', ' ').split('.').first;
    return normalized.length >= 16 ? normalized.substring(0, 16) : normalized;
  }

  Widget _buildAuditTile(ContentAuditDTO audit) {
    final statusText = audit.statusLabel ?? '\u5f85\u5ba1\u6838';
    final statusColor = switch (audit.status) {
      1 => const Color(0xFF2E7D32),
      _ => const Color(0xFFEF6C00),
    };
    final contentType = audit.contentTypeLabel ?? '\u6587\u672c';
    final resultText = audit.finalResultLabel ?? '\u5f85\u5904\u7406';

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
            '\u5ba1\u6838\u7ed3\u679c\uff1a$resultText',
            style: const TextStyle(color: Color(0xFF333333)),
          ),
          if ((audit.handleNote ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '\u5904\u7406\u8bf4\u660e\uff1a${audit.handleNote!}',
              style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
            ),
          ],
          if ((audit.content ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '\u5185\u5bb9\u6458\u8981\uff1a${audit.content!}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            '\u63d0\u4ea4\u65f6\u95f4\uff1a${_formatTime(audit.createdAt)}',
            style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
          ),
          if ((audit.handledAt ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '\u5904\u7406\u65f6\u95f4\uff1a${_formatTime(audit.handledAt)}',
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
      appBar: AppBar(title: const Text('\u6211\u7684\u5185\u5bb9\u5ba1\u6838')),
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
                        '\u6682\u65e0\u5ba1\u6838\u8bb0\u5f55',
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
