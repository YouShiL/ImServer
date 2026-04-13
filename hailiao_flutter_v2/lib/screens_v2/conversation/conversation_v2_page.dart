import 'package:flutter/material.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/providers/group_provider.dart';
import 'package:hailiao_flutter_v2/adapters/chat_v2_view_models.dart';
import 'package:hailiao_flutter_v2/domain_v2/coordinators/conversation_coordinator.dart';
import 'package:hailiao_flutter_v2/domain_v2/repositories/conversation_repository.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/identity_resolver.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/im_message_mapper.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/wukong_im_service.dart';
import 'package:hailiao_flutter_v2/domain_v2/use_cases/load_conversations_use_case.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/im_chat_entry_log.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/im_conv_source_log.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/im_conv_title_log.dart';
import 'package:hailiao_flutter_v2/screens_v2/chat/chat_v2_page.dart';
import 'package:hailiao_flutter_v2/widgets_v2/conversation/conversation_list_v2.dart';
import 'package:hailiao_flutter_v2/widgets_v2/main/primary_page_scaffold_v2.dart';
import 'package:provider/provider.dart';

class ConversationV2Page extends StatefulWidget {
  const ConversationV2Page({super.key});

  @override
  State<ConversationV2Page> createState() => _ConversationV2PageState();
}

class _ConversationV2PageState extends State<ConversationV2Page> {
  ConversationCoordinator? _coordinator;
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) {
      return;
    }
    _didLoad = true;

    final auth = context.read<AuthProvider>();
    final IdentityResolver identity = IdentityResolver(
      getFriends: () => context.read<FriendProvider>().friends,
      getGroups: () => context.read<GroupProvider>().groups,
    );
    final ImMessageMapper mapper = ImMessageMapper(identityResolver: identity);
    final ConversationRepository repository = ApiConversationRepository(
      mapper: mapper,
    );
    final imService = WukongImService(mapper: mapper);
    _coordinator = ConversationCoordinator(
      loadConversationsUseCase: LoadConversationsUseCase(repository),
      repository: repository,
      imService: imService,
      currentUserId: auth.messagingUserId ?? auth.user?.id,
      currentUserToken: auth.token,
      identityResolver: identity,
    )..addListener(_onCoordinatorChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>(() async {
        await _coordinator?.attachPreviewUpdates();
        await _coordinator?.loadConversations();
      });
    });
  }

  void _onCoordinatorChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _coordinator
      ?..removeListener(_onCoordinatorChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FriendProvider>();
    context.watch<GroupProvider>();
    final IdentityResolver identity = IdentityResolver(
      getFriends: () => context.read<FriendProvider>().friends,
      getGroups: () => context.read<GroupProvider>().groups,
    );
    final coordinator = _coordinator;
    final List<ConversationV2ViewModel> conversations =
        mapConversationSummariesToViewModels(
          coordinator?.conversations ?? const [],
          identity: identity,
        );

    return PrimaryPageScaffoldV2(
      child: (coordinator?.isLoading ?? false) && conversations.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ConversationListV2(
              items: conversations,
              onTapItem: (ConversationV2ViewModel item) {
                imConvSourceLog('ui_tap_conversation_list', <String, Object?>{
                  'sourceModel': 'ConversationV2ViewModel',
                  'sourceFlow': 'ConversationCoordinator+ConversationSummary',
                  'conversationId': item.conversationId?.toString() ?? 'null',
                  'targetId': item.targetId.toString(),
                  'type': item.type.toString(),
                  'title': item.title,
                });
                imChatEntryLog(
                  'conversation_list',
                  targetId: item.targetId,
                  type: item.type,
                  title: item.title,
                );
                imConvTitleLog('ui_tap_chat_v2_entry', <String, Object?>{
                  'conversationId': item.conversationId?.toString() ?? 'null',
                  'targetId': item.targetId.toString(),
                  'type': item.type.toString(),
                  'list_title': item.title,
                  'chatV2Page_targetId': item.targetId.toString(),
                  'chatV2Page_type': item.type.toString(),
                  'chatV2Page_title': item.title,
                  'friendMap': 'N/A (list VM only)',
                });
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ChatV2Page(
                      targetId: item.targetId,
                      type: item.type,
                      serverConversationName: item.serverConversationName,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
