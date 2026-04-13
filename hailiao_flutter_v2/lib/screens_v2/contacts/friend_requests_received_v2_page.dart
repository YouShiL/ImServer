import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/friend_request_dto.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';
import 'package:hailiao_flutter_v2/widgets_v2/main/secondary_page_scaffold_v2.dart';
import 'package:provider/provider.dart';

/// 收到的待处理好友申请（receiver 视角），与 [FriendProvider.receivedRequests] 对齐。
class FriendRequestsReceivedV2Page extends StatefulWidget {
  const FriendRequestsReceivedV2Page({super.key});

  @override
  State<FriendRequestsReceivedV2Page> createState() =>
      _FriendRequestsReceivedV2PageState();
}

class _FriendRequestsReceivedV2PageState
    extends State<FriendRequestsReceivedV2Page> {
  bool _didInitialLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialLoad) {
      return;
    }
    _didInitialLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      await context.read<FriendProvider>().loadFriendRequests();
    });
  }

  String _nameOf(FriendRequestDTO r) {
    final u = r.fromUserInfo;
    if (u != null) {
      final String n = u.nickname?.trim() ?? '';
      if (n.isNotEmpty) {
        return n;
      }
      final String id = u.userCode?.trim() ?? '';
      if (id.isNotEmpty) {
        return id;
      }
    }
    return '用户 ${r.fromUserId ?? ''}';
  }

  Future<void> _onRefresh() async {
    await context.read<FriendProvider>().loadFriendRequests();
  }

  Future<void> _handle(
    FriendProvider fp,
    FriendRequestDTO r,
    bool accept,
  ) async {
    final int? id = r.id;
    if (id == null) {
      return;
    }
    final bool ok = accept
        ? await fp.acceptFriendRequest(id)
        : await fp.rejectFriendRequest(id);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (accept ? '已同意' : '已拒绝')
              : (fp.error ?? '操作失败'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final FriendProvider fp = context.watch<FriendProvider>();
    final List<FriendRequestDTO> pending = fp.receivedRequests
        .where((FriendRequestDTO r) => (r.status ?? 0) == 0)
        .toList();

    return SecondaryPageScaffoldV2(
      title: '好友申请',
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: fp.isLoading && pending.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const <Widget>[
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : pending.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: const <Widget>[
                      SizedBox(height: 48),
                      Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: ChatV2Tokens.textSecondary,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '暂无待处理的好友申请',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: ChatV2Tokens.textSecondary,
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: pending.length,
                    separatorBuilder:
                        (BuildContext context, int index) =>
                            const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) {
                      final FriendRequestDTO r = pending[index];
                      final String msg = r.message?.trim().isNotEmpty == true
                          ? r.message!.trim()
                          : '请求添加你为好友';
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD6DCE3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _nameOf(r).isEmpty
                                        ? '?'
                                        : _nameOf(r).substring(0, 1),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        _nameOf(r),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        msg,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: ChatV2Tokens.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: fp.isLoading
                                        ? null
                                        : () => _handle(fp, r, false),
                                    child: const Text('拒绝'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: fp.isLoading
                                        ? null
                                        : () => _handle(fp, r, true),
                                    child: const Text('同意'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
