import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/group_dto.dart';
import 'package:hailiao_flutter/services/api_service.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/theme/search_ux_strings.dart';
import 'package:hailiao_flutter/theme/ui_tokens.dart';
import 'package:hailiao_flutter/widgets/common/im_search_bar.dart';
import 'package:hailiao_flutter/widgets/profile/profile_circle_avatar.dart';

String _groupDisplayName(GroupDTO group) {
  final String n = (group.groupName ?? '').trim();
  return n.isEmpty ? '未命名群组' : n;
}

/// 按群号搜索并进入群资料（独立页）。
class SearchGroupScreen extends StatefulWidget {
  const SearchGroupScreen({super.key});

  @override
  State<SearchGroupScreen> createState() => _SearchGroupScreenState();
}

class _SearchGroupScreenState extends State<SearchGroupScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  GroupDTO? _group;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final keyword = _controller.text.trim();
    if (keyword.isEmpty) {
      setState(() => _error = SearchUxStrings.errorGroupIdRequired);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _group = null;
    });
    try {
      final response = await ApiService.getGroupByBusinessId(keyword);
      setState(() {
        if (response.isSuccess) {
          _group = response.data;
          if (_group == null) {
            _error = SearchUxStrings.emptyNoResults;
          }
        } else {
          _error = SearchUxStrings.messageWhenSearchRequestFailed(
            response.message,
          );
        }
      });
    } catch (_) {
      setState(() => _error = SearchUxStrings.errorSearchFailed);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CommonTokens.bgPrimary,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: CommonTokens.bgPrimary,
        foregroundColor: CommonTokens.textPrimary,
        surfaceTintColor: Colors.transparent,
        title: const Text('搜索群聊'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ImSearchBar(
            controller: _controller,
            hintText: '搜索',
            showClear: _controller.text.isNotEmpty,
            onChanged: (_) => setState(() {}),
            onClear: () {
              _controller.clear();
              setState(() {
                _group = null;
                _error = null;
              });
            },
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: UiTokens.filledPrimary(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _loading ? null : _search,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('查找'),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(
                color: CommonTokens.danger,
                fontSize: 13,
              ),
            ),
          ],
          if (_group != null) ...[
            const SizedBox(height: 16),
            Material(
              color: CommonTokens.surfacePrimary,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  final g = _group!;
                  Navigator.pushNamed(
                    context,
                    '/group-detail',
                    arguments: {
                      'groupId': g.id,
                      'group': g,
                    },
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ProfileCircleAvatar(
                        title: _groupDisplayName(_group!),
                        avatarRaw: _group!.avatar,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _groupDisplayName(_group!),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                if ((_group!.groupId ?? '').trim().isNotEmpty)
                                  '群号：${_group!.groupId}',
                                if ((_group!.description ?? '')
                                    .trim()
                                    .isNotEmpty)
                                  _group!.description!,
                              ]
                                  .where((s) => s.trim().isNotEmpty)
                                  .join(' · '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: CommonTokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          color: CommonTokens.textTertiary),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
