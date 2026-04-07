import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/user_dto.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/services/api_service.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/theme/feedback_ux_strings.dart';
import 'package:hailiao_flutter/theme/search_ux_strings.dart';
import 'package:hailiao_flutter/theme/ui_tokens.dart';
import 'package:hailiao_flutter/utils/network_avatar_url.dart';
import 'package:hailiao_flutter/widgets/common/im_search_bar.dart';
import 'package:hailiao_flutter/widgets/profile/profile_circle_avatar.dart';
import 'package:hailiao_flutter/widgets/profile/profile_display_utils.dart';
import 'package:hailiao_flutter/widgets/shell/im_template_shell.dart';
import 'package:provider/provider.dart';

/// 微信式「添加好友」独立页（非弹窗）。
class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final _keywordController = TextEditingController();
  final _remarkController = TextEditingController();
  final _messageController = TextEditingController(
    text: '你好，我想加你为好友。',
  );

  String _searchType = 'userId';
  UserDTO? _searchedUser;
  String? _error;
  bool _isSearching = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _keywordController.dispose();
    _remarkController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Color _statusColor(bool isOnline) {
    return isOnline ? const Color(0xFF22C55E) : const Color(0xFF9E9E9E);
  }

  String _statusText(UserDTO? user) {
    if (user == null) {
      return '状态未知';
    }
    if (user.showOnlineStatus == false) {
      return '在线状态已隐藏';
    }
    return (user.onlineStatus ?? 0) == 1 ? '在线' : '离线';
  }

  Future<void> _searchUser() async {
    final keyword = _keywordController.text.trim();
    if (keyword.isEmpty) {
      setState(() => _error = SearchUxStrings.errorUserKeywordRequired);
      return;
    }
    setState(() {
      _isSearching = true;
      _error = null;
      _searchedUser = null;
    });
    try {
      final response =
          await ApiService.searchUser(keyword, type: _searchType);
      setState(() {
        if (response.isSuccess) {
          _searchedUser = response.data;
          if (_searchedUser == null) {
            _error = SearchUxStrings.emptyNoResults;
          } else if (_remarkController.text.trim().isEmpty) {
            _remarkController.text =
                _searchedUser!.nickname ?? _searchedUser!.userId ?? '';
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
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _submit() async {
    if (_searchedUser?.id == null) {
      setState(() => _error = SearchUxStrings.errorUserSearchFirst);
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    final friendProvider = context.read<FriendProvider>();
    final success = await friendProvider.addFriend(
      _searchedUser!.id!,
      _remarkController.text.trim(),
      message: _messageController.text.trim(),
    );
    if (!mounted) {
      return;
    }
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(FeedbackUxStrings.snackFriendRequestSent),
        ),
      );
      Navigator.pop(context);
    } else {
      setState(() {
        _error = FeedbackUxStrings.messageOrFallback(
          friendProvider.error,
          FeedbackUxStrings.fallbackSendFriendRequestFailed,
        );
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = (_searchedUser?.onlineStatus ?? 0) == 1;
    final displayName = _searchedUser == null
        ? ''
        : ProfileDisplayTexts.displayName(_searchedUser!);

    return Scaffold(
      backgroundColor: CommonTokens.bgPrimary,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: CommonTokens.bgPrimary,
        foregroundColor: CommonTokens.textPrimary,
        surfaceTintColor: Colors.transparent,
        title: const Text('添加好友'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: CommonTokens.surfacePrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'userId', label: Text('用户号')),
                      ButtonSegment(value: 'phone', label: Text('手机号')),
                    ],
                    selected: {_searchType},
                    onSelectionChanged: _isSearching
                        ? null
                        : (s) {
                            setState(() {
                              _searchType = s.first;
                            });
                          },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ImSearchBar(
            controller: _keywordController,
            hintText: '搜索',
            showClear: _keywordController.text.isNotEmpty,
            onChanged: (_) => setState(() {}),
            onClear: () {
              _keywordController.clear();
              setState(() {});
            },
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: UiTokens.filledPrimary(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _isSearching ? null : _searchUser,
              child: _isSearching
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('查找'),
            ),
          ),
          if (_searchedUser != null) ...[
            const SizedBox(height: 16),
            Text(
              '搜索结果',
              style: CommonTokens.caption.copyWith(
                color: CommonTokens.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Material(
              color: CommonTokens.surfacePrimary,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _searchedUser!.id == null
                    ? null
                    : () {
                        final UserDTO u = _searchedUser!;
                        Navigator.pushNamed(
                          context,
                          '/user-detail',
                          arguments: <String, dynamic>{
                            'userId': u.id,
                            'user': u,
                          },
                        );
                      },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProfileCircleAvatar(
                        title: displayName,
                        avatarRaw: _searchedUser!.avatar,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: CommonTokens.subtitle,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '用户号：${ProfileDisplayTexts.accountIdLine(_searchedUser!.userId)}',
                              style: CommonTokens.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _statusColor(isOnline),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(_statusText(_searchedUser)),
                              ],
                            ),
                            if ((_searchedUser!.signature ?? '')
                                .trim()
                                .isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                '个性签名：${ProfileDisplayTexts.fieldValue(_searchedUser!.signature)}',
                                style: CommonTokens.bodySmall.copyWith(
                                  color: CommonTokens.textSecondary,
                                ),
                              ),
                            ],
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
            const SizedBox(height: 12),
            _fieldTile(
              label: '备注',
              child: TextField(
                controller: _remarkController,
                decoration: ImTemplateShell.dialogFieldDecoration(label: '备注'),
              ),
            ),
            const SizedBox(height: 8),
            _fieldTile(
              label: '验证消息',
              child: TextField(
                controller: _messageController,
                maxLines: 2,
                decoration: ImTemplateShell.dialogFieldDecoration(
                  label: '验证消息',
                  alignLabelWithHint: true,
                ),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: CommonTokens.danger, fontSize: 13),
            ),
          ],
          if (_searchedUser != null) ...[
            const SizedBox(height: 20),
            FilledButton(
              style: UiTokens.filledPrimary(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _isSubmitting ? null : _submit,
              child: Text(
                _isSubmitting
                    ? FeedbackUxStrings.buttonSendingInProgress
                    : FeedbackUxStrings.buttonSendRequest,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fieldTile({required String label, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CommonTokens.surfacePrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CommonTokens.lineSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: CommonTokens.caption.copyWith(
              color: CommonTokens.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
