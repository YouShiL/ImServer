import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hailiao_flutter/models/friend_dto.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/providers/group_provider.dart';
import 'package:hailiao_flutter_v2/adapters/chat_v2_view_models.dart';
import 'package:hailiao_flutter_v2/domain_v2/repositories/conversation_repository.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/identity_resolver.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/im_chat_entry_log.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/im_conv_source_log.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/im_message_mapper.dart';
import 'package:hailiao_flutter_v2/domain_v2/use_cases/load_conversations_use_case.dart';
import 'package:hailiao_flutter_v2/screens_v2/chat/chat_v2_page.dart';
import 'package:hailiao_flutter_v2/screens_v2/contacts/user_detail_v2_page.dart';
import 'package:hailiao_flutter_v2/widgets_v2/conversation/conversation_item_v2.dart';
import 'package:hailiao_flutter_v2/widgets_v2/main/secondary_page_scaffold_v2.dart';
import 'package:provider/provider.dart';

class SearchV2Page extends StatefulWidget {
  const SearchV2Page({super.key});

  @override
  State<SearchV2Page> createState() => _SearchV2PageState();
}

class _SearchV2PageState extends State<SearchV2Page> {
  late final TextEditingController _controller;
  String _query = '';
  bool _didInitRepository = false;
  ConversationRepository? _repository;
  StreamSubscription<dynamic>? _conversationUpdates;
  bool _loadingInitial = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitRepository) {
      return;
    }
    _didInitRepository = true;

    final IdentityResolver identity = IdentityResolver(
      getFriends: () => context.read<FriendProvider>().friends,
      getGroups: () => context.read<GroupProvider>().groups,
    );
    final ImMessageMapper mapper = ImMessageMapper(identityResolver: identity);
    final ConversationRepository repository = ApiConversationRepository(
      mapper: mapper,
    );
    _repository = repository;

    _conversationUpdates = repository.watchConversationSummaries().listen((_) {
      if (mounted) {
        setState(() {});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      final ConversationRepository r = repository;
      if (r.getCachedConversations().isNotEmpty) {
        return;
      }
      setState(() {
        _loadingInitial = true;
      });
      try {
        await LoadConversationsUseCase(r).call();
      } finally {
        if (mounted) {
          setState(() {
            _loadingInitial = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _conversationUpdates?.cancel();
    _controller.dispose();
    super.dispose();
  }

  FriendDTO? _friendForTargetId(FriendProvider fp, int targetId) {
    for (final FriendDTO f in fp.friends) {
      if (f.friendUserId == targetId) {
        return f;
      }
    }
    return null;
  }

  void _openSearchResult(BuildContext context, ConversationV2ViewModel item) {
    imConvSourceLog('ui_tap_search_result', <String, Object?>{
      'sourceModel': 'ConversationV2ViewModel',
      'sourceFlow': 'ApiConversationRepository+mapConversationSummariesToViewModels',
      'conversationId': item.conversationId?.toString() ?? 'null',
      'targetId': item.targetId.toString(),
      'type': item.type.toString(),
      'title': item.title,
    });
    imChatEntryLog(
      'search_result',
      targetId: item.targetId,
      type: item.type,
      title: item.title,
    );
    if (item.type == 1) {
      final FriendProvider fp = context.read<FriendProvider>();
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => UserDetailV2Page(
            userId: item.targetId,
            initialFriend: _friendForTargetId(fp, item.targetId),
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatV2Page(
            targetId: item.targetId,
            type: item.type,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FriendProvider>();
    context.watch<GroupProvider>();
    final IdentityResolver identity = IdentityResolver(
      getFriends: () => context.read<FriendProvider>().friends,
      getGroups: () => context.read<GroupProvider>().groups,
    );
    final ConversationRepository? repository = _repository;
    final String keyword = _query.trim().toLowerCase();
    final List<ConversationV2ViewModel> allConversations =
        mapConversationSummariesToViewModels(
      repository?.getCachedConversations() ?? const [],
      identity: identity,
    );

    final List<ConversationV2ViewModel> results = keyword.isEmpty
        ? <ConversationV2ViewModel>[]
        : allConversations.where((ConversationV2ViewModel item) {
            return item.title.toLowerCase().contains(keyword) ||
                item.lastMessage.toLowerCase().contains(keyword);
          }).toList(growable: false);

    return SecondaryPageScaffoldV2(
      title: '搜索',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: <Widget>[
          TextField(
            controller: _controller,
            onChanged: (String value) {
              setState(() {
                _query = value;
              });
            },
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: '搜索会话标题或消息摘要',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (keyword.isEmpty)
            _buildInfoCard('输入关键词后，将在当前已加载的会话列表中进行本地过滤。')
          else if (_loadingInitial && allConversations.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (results.isEmpty)
            _buildInfoCard('没有匹配的会话结果')
          else
            ...results.map(
              (ConversationV2ViewModel item) => ConversationItemV2(
                viewModel: item,
                onTap: () => _openSearchResult(context, item),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String text) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: Colors.black54),
      ),
    );
  }
}
