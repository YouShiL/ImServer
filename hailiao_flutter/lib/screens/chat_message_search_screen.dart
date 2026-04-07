import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hailiao_flutter/models/message_dto.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/services/api_service.dart';
import 'package:hailiao_flutter/theme/chat_date_format.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/theme/search_ux_strings.dart';
import 'package:hailiao_flutter/theme/ui_tokens.dart';
import 'package:hailiao_flutter/widgets/chat/chat_message_body_types.dart';
import 'package:hailiao_flutter/widgets/chat/chat_message_search_support.dart';
import 'package:hailiao_flutter/widgets/chat/message_dto_chat_display.dart';
import 'package:hailiao_flutter/widgets/common/im_search_bar.dart';
import 'package:provider/provider.dart';

/// 自聊天页返回时的结果（定位 / 转发 / 回到底部）。
class ChatMessageSearchPop {
  const ChatMessageSearchPop._({
    this.focusId,
    this.forward,
    this.scrollToLatest = false,
  });

  final int? focusId;
  final MessageDTO? forward;
  final bool scrollToLatest;

  factory ChatMessageSearchPop.focus(int id) =>
      ChatMessageSearchPop._(focusId: id);

  factory ChatMessageSearchPop.forward(MessageDTO m) =>
      ChatMessageSearchPop._(forward: m);

  factory ChatMessageSearchPop.latest() =>
      ChatMessageSearchPop._(scrollToLatest: true);
}

class ChatMessageSearchScreen extends StatefulWidget {
  const ChatMessageSearchScreen({
    super.key,
    required this.targetId,
    required this.type,
    required this.selectedMessageIds,
  });

  final int targetId;
  final int type;
  final Set<int> selectedMessageIds;

  static const List<String> filters = <String>[
    '全部',
    '文本',
    '图片',
    '音频',
    '视频',
  ];

  static const List<String> senderFilters = <String>[
    '全部来源',
    '我发的',
    '对方发送',
  ];

  @override
  State<ChatMessageSearchScreen> createState() =>
      _ChatMessageSearchScreenState();
}

class _ChatMessageSearchScreenState extends State<ChatMessageSearchScreen> {
  final _keywordController = TextEditingController();
  final _results = <MessageDTO>[];
  bool _loading = false;
  String? _errorText;
  String? _note;
  String _typeFilter = '全部';
  String _senderFilter = '全部来源';
  String _sort = '最新优先';
  bool _selectedFirst = false;

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  bool _isSelected(MessageDTO message) =>
      message.id != null && widget.selectedMessageIds.contains(message.id);

  void _toggleSelection(MessageDTO message) {
    final id = message.id;
    if (id == null) {
      return;
    }
    setState(() {
      if (widget.selectedMessageIds.contains(id)) {
        widget.selectedMessageIds.remove(id);
      } else {
        widget.selectedMessageIds.add(id);
      }
    });
  }

  Future<List<MessageDTO>> _queryServer(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) {
      return [];
    }
    final response = widget.type == 1
        ? await ApiService.searchMessages(trimmed, page: 1, size: 50)
        : await ApiService.searchGroupMessages(
            widget.targetId,
            trimmed,
            page: 1,
            size: 50,
          );
    if (!response.isSuccess || response.data == null) {
      return [];
    }
    if (widget.type != 1) {
      return response.data!;
    }
    return response.data!
        .where((message) {
          final relatedUser = message.fromUserId == widget.targetId ||
              message.toUserId == widget.targetId;
          return relatedUser;
        })
        .toList();
  }

  Future<void> _runSearch() async {
    final trimmed = _keywordController.text.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results.clear();
        _errorText = SearchUxStrings.errorKeywordRequired;
      });
      return;
    }
    setState(() {
      _loading = true;
      _errorText = null;
      _note = null;
      _results.clear();
    });
    try {
      final data = await _queryServer(trimmed);
      setState(() {
        _loading = false;
        _results.addAll(data);
        if (data.isEmpty) {
          _errorText = SearchUxStrings.emptyNoResults;
        }
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _errorText = SearchUxStrings.errorSearchFailed;
      });
    }
  }

  Future<void> _openMediaDetails(MessageDTO message) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${chatSearchMessageTypeLabel(message)}详情'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('类型：${chatSearchMessageTypeLabel(message)}'),
            const SizedBox(height: 8),
            Text('时间：${ChatDateFormat.display(message.createdAt) ?? '-'}'),
            const SizedBox(height: 8),
            Text('路径：${chatSearchMessagePathLabel(message)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('关闭'),
          ),
          if (!message.showsTextBubblePayload)
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _openMediaPreview(message);
              },
              child: const Text('打开预览'),
            ),
          OutlinedButton(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: chatSearchMediaSummaryText(message)),
              );
              if (context.mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${chatSearchMessageTypeLabel(message)}摘要已复制',
                    ),
                  ),
                );
              }
            },
            child: const Text('复制摘要'),
          ),
        ],
      ),
    );
  }

  Future<void> _openMediaPreview(MessageDTO message) async {
    final path = message.content ?? '';
    if (path.isEmpty) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.black87,
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: message.safeBodyType == ChatMessageBodyTypes.image
                      ? (path.startsWith('http')
                          ? InteractiveViewer(
                              child: Image.network(
                                path,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Text(
                                  '图片预览加载失败。',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            )
                          : InteractiveViewer(
                              child: Image.file(
                                File(path),
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Text(
                                  '图片预览加载失败。',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ))
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.play_circle_fill,
                              size: 72,
                              color: Colors.white,
                            ),
                            SizedBox(height: 16),
                            Text(
                              '暂未内嵌视频预览。',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChipRow({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final label = options[index];
          final on = label == selected;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelect(label),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: on
                      ? CommonTokens.brandSoft
                      : CommonTokens.surfacePrimary,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: on ? CommonTokens.brandBlue : CommonTokens.lineSubtle,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                    color: on ? CommonTokens.brandBlue : CommonTokens.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().user?.id;
    final filtered = _results
        .where(
          (item) =>
              chatSearchMatchesTypeFilter(item, _typeFilter) &&
              chatSearchMatchesSenderFilter(item, _senderFilter, uid),
        )
        .toList();
    filtered.sort((a, b) {
      final timeCompare =
          (b.createdAt ?? '').compareTo(a.createdAt ?? '');
      final primary = _sort == '最早优先' ? -timeCompare : timeCompare;
      return primary;
    });
    if (_selectedFirst) {
      filtered.sort((a, b) {
        final aSel = _isSelected(a) ? 1 : 0;
        final bSel = _isSelected(b) ? 1 : 0;
        return bSel.compareTo(aSel);
      });
    }
    final selectedInResults =
        filtered.where((e) => _isSelected(e)).toList();

    return Scaffold(
      backgroundColor: CommonTokens.bgPrimary,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: CommonTokens.bgPrimary,
        foregroundColor: CommonTokens.textPrimary,
        title: const Text('搜索聊天记录'),
        surfaceTintColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, ChatMessageSearchPop.latest()),
            child: Text(
              '回到底部',
              style: TextStyle(color: UiTokens.primaryBlue, fontSize: 14),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: ImSearchBar(
              controller: _keywordController,
              hintText: '搜索',
              showClear: _keywordController.text.isNotEmpty,
              onChanged: (_) => setState(() {}),
              onClear: () {
                _keywordController.clear();
                setState(() {
                  _results.clear();
                  _errorText = null;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: _filterChipRow(
                    options: ChatMessageSearchScreen.filters,
                    selected: _typeFilter,
                    onSelect: (v) => setState(() => _typeFilter = v),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: _filterChipRow(
              options: ChatMessageSearchScreen.senderFilters,
              selected: _senderFilter,
              onSelect: (v) => setState(() => _senderFilter = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                FilledButton(
                  style: UiTokens.filledPrimary(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  onPressed: _loading ? null : _runSearch,
                  child: Text(_loading ? '搜索中…' : '搜索'),
                ),
                const SizedBox(width: 8),
                if (_results.isNotEmpty) ...[
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    onSelected: (v) => setState(() => _sort = v),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: '最新优先', child: Text('最新优先')),
                      PopupMenuItem(value: '最早优先', child: Text('最早优先')),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sort, size: 18, color: UiTokens.textSecondary),
                          const SizedBox(width: 4),
                          Text(_sort, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_note != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _note!,
                style: const TextStyle(fontSize: 12, color: Color(0xFF166534)),
              ),
            ),
          if (_loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorText != null && _results.isEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _errorText!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: CommonTokens.textSecondary),
                  ),
                ),
              ),
            )
          else if (_results.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  SearchUxStrings.idleEnterKeyword,
                  style: TextStyle(color: CommonTokens.textSecondary),
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  if (filtered.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(SearchUxStrings.emptyNoFilterMatch),
                      ),
                    )
                  else ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: _SearchSummaryBar(
                        filteredLen: filtered.length,
                        selectedLen: selectedInResults.length,
                        typeStats: chatSearchMessageTypeStats(filtered),
                        mine: filtered
                            .where((e) => e.isSameSenderAs(uid))
                            .length,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          FilterChip(
                            label: const Text('已选优先', style: TextStyle(fontSize: 12)),
                            selected: _selectedFirst,
                            visualDensity: VisualDensity.compact,
                            onSelected: (v) =>
                                setState(() => _selectedFirst = v),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _results.clear();
                                _errorText = null;
                                _note = '已清空，请输入关键词重新搜索。';
                              });
                            },
                            child: const Text('清空'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final isSel = _isSelected(item);
                          final senderLabel =
                              _senderFilter == '全部来源'
                                  ? (item.isSameSenderAs(uid) ? '我发的' : '对方发送')
                                  : _senderFilter;
                          return ListTile(
                            dense: true,
                            selected: isSel,
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(chatSearchMessageTypeIcon(item), size: 18),
                                const SizedBox(width: 6),
                                Icon(
                                  isSel
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  size: 18,
                                  color: isSel
                                      ? CommonTokens.brandBlue
                                      : CommonTokens.textTertiary,
                                ),
                              ],
                            ),
                            title: RichText(
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: const TextStyle(
                                  color: CommonTokens.textPrimary,
                                  fontSize: 14,
                                ),
                                children: [
                                  chatSearchHighlightedSummarySpan(
                                    item,
                                    _keywordController.text,
                                  ),
                                ],
                              ),
                            ),
                            subtitle: Text(
                              chatSearchResultContext(item, senderLabel),
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_horiz, size: 20),
                              onSelected: (value) async {
                                if (value == 'select') {
                                  _toggleSelection(item);
                                } else if (value == 'copy') {
                                  await Clipboard.setData(
                                    ClipboardData(text: chatSearchSummary(item)),
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('搜索结果已复制'),
                                      ),
                                    );
                                  }
                                } else if (value == 'details') {
                                  if (item.showsTextBubblePayload) {
                                    await Clipboard.setData(
                                      ClipboardData(
                                        text: chatSearchMediaSummaryText(item),
                                      ),
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('消息详情已复制'),
                                        ),
                                      );
                                    }
                                  } else {
                                    await _openMediaDetails(item);
                                  }
                                } else if (value == 'preview') {
                                  if (!item.showsTextBubblePayload) {
                                    await _openMediaPreview(item);
                                  }
                                } else if (value == 'forward') {
                                  if (context.mounted) {
                                    Navigator.pop(
                                      context,
                                      ChatMessageSearchPop.forward(item),
                                    );
                                  }
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'select',
                                  child:
                                      Text(isSel ? '移出选择' : '加入选择'),
                                ),
                                const PopupMenuItem(
                                  value: 'copy',
                                  child: Text('复制摘要'),
                                ),
                                const PopupMenuItem(
                                  value: 'forward',
                                  child: Text('转发'),
                                ),
                                if (!item.showsTextBubblePayload)
                                  const PopupMenuItem(
                                    value: 'preview',
                                    child: Text('预览'),
                                  ),
                                const PopupMenuItem(
                                  value: 'details',
                                  child: Text('打开详情'),
                                ),
                              ],
                            ),
                            onLongPress: () => _toggleSelection(item),
                            onTap: () {
                              final id = item.id;
                              if (id == null) {
                                return;
                              }
                              Navigator.pop(
                                context,
                                ChatMessageSearchPop.focus(id),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchSummaryBar extends StatelessWidget {
  const _SearchSummaryBar({
    required this.filteredLen,
    required this.selectedLen,
    required this.typeStats,
    required this.mine,
  });

  final int filteredLen;
  final int selectedLen;
  final Map<String, int> typeStats;
  final int mine;

  @override
  Widget build(BuildContext context) {
    final other = filteredLen - mine;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: CommonTokens.surfacePrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CommonTokens.lineSubtle),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          _miniStat('条数', '$filteredLen'),
          _miniStat('已选', '$selectedLen'),
          _miniStat('我发', '$mine'),
          _miniStat('对方', '$other'),
          for (final e in typeStats.entries)
            if (e.value > 0) _miniStat(e.key, '${e.value}'),
        ],
      ),
    );
  }

  Widget _miniStat(String k, String v) {
    return Text(
      '$k $v',
      style: const TextStyle(fontSize: 11, color: CommonTokens.textSecondary),
    );
  }
}
