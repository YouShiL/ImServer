import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/providers/friend_provider.dart';
import 'package:hailiao_flutter/providers/group_provider.dart';
import 'package:hailiao_flutter_v2/adapters/chat_v2_view_models.dart';
import 'package:hailiao_flutter_v2/domain_v2/coordinators/chat_coordinator.dart';
import 'package:hailiao_flutter_v2/domain_v2/repositories/chat_repository.dart';
import 'package:hailiao_flutter_v2/domain_v2/repositories/conversation_repository.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/identity_resolver.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/im_message_mapper.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/wukong_im_service.dart';
import 'package:hailiao_flutter_v2/domain_v2/use_cases/load_chat_messages_use_case.dart';
import 'package:hailiao_flutter_v2/domain_v2/use_cases/send_text_message_use_case.dart';
import 'package:hailiao_flutter_v2/widgets_v2/chat/chat_bottom_v2.dart';
import 'package:hailiao_flutter_v2/widgets_v2/chat/chat_message_list_v2.dart';
import 'package:hailiao_flutter_v2/widgets_v2/main/secondary_page_scaffold_v2.dart';
import 'package:provider/provider.dart';

class ChatV2Page extends StatefulWidget {
  const ChatV2Page({
    super.key,
    required this.targetId,
    required this.type,
    this.title = '聊天',
    this.serverConversationName,
  });

  final int targetId;
  final int type;
  final String title;

  /// 会话列表带入的会话名，私聊在好友未加载时仍可作展示回退。
  final String? serverConversationName;

  @override
  State<ChatV2Page> createState() => _ChatV2PageState();
}

class _ChatV2PageState extends State<ChatV2Page> {
  ChatV2BottomMode _bottomMode = ChatV2BottomMode.idle;
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  ChatCoordinator? _coordinator;
  bool _didInitCoordinator = false;

  /// 首屏极薄快照：首帧稳定后切回可滚动 live 列表，避免与远端 merge 叠加跳动。
  bool _firstPaintSnapshotActive = false;
  bool _snapshotHandoffCompleted = false;

  double _lastViewportKeyboardInsetLogged = -1;
  double _lastListVisibleHeightLogged = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitCoordinator) {
      return;
    }
    _didInitCoordinator = true;

    final AuthProvider auth = context.read<AuthProvider>();
    final FriendProvider fp = context.read<FriendProvider>();
    final GroupProvider groupProvider = context.read<GroupProvider>();
    final int? currentUserId = auth.messagingUserId ?? auth.user?.id;
    final String? currentUserToken = auth.token;
    final String? currentUserName =
        auth.user?.nickname ?? auth.user?.userCode;
    final IdentityResolver identity = IdentityResolver(
      getFriends: () => fp.friends,
      getGroups: () => groupProvider.groups,
      getGroupMemberDisplayName: groupProvider.memberDisplayNameFor,
    );
    final ImMessageMapper mapper = ImMessageMapper(identityResolver: identity);
    final WukongImService imService = WukongImService(mapper: mapper);
    final ChatRepository repository = ApiChatRepository(
      mapper: mapper,
      imService: imService,
    );
    final ConversationRepository conversationRepository =
        ApiConversationRepository(mapper: mapper);

    _coordinator = ChatCoordinator(
      targetId: widget.targetId,
      type: widget.type,
      currentUserId: currentUserId,
      currentUserToken: currentUserToken,
      currentUserName: currentUserName,
      loadChatMessagesUseCase: LoadChatMessagesUseCase(repository),
      sendTextMessageUseCase: SendTextMessageUseCase(repository),
      repository: repository,
      conversationRepository: conversationRepository,
      mapper: mapper,
    )..addListener(_onCoordinatorChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapCoordinator(groupProvider));
    });
  }

  Future<void> _bootstrapCoordinator(GroupProvider groupProvider) async {
    await _coordinator?.hydrateFromCache();
    if (!mounted) {
      return;
    }
    if (widget.type == 2) {
      await groupProvider.loadGroupMembers(widget.targetId);
    }
    if (!mounted) {
      return;
    }
    await _coordinator?.attachImStream();
    if (!mounted) {
      return;
    }
    await _coordinator?.refreshRemoteFirstPage();
  }

  void _onCoordinatorChanged() {
    final ChatCoordinator? coordinator = _coordinator;
    if (!mounted || coordinator == null) {
      return;
    }
    if (_inputController.text != coordinator.draftText) {
      _inputController.value = TextEditingValue(
        text: coordinator.draftText,
        selection: TextSelection.collapsed(offset: coordinator.draftText.length),
      );
    }
    _maybeBeginFirstPaintSnapshot(coordinator);
    setState(() {});
  }

  void _maybeBeginFirstPaintSnapshot(ChatCoordinator coordinator) {
    if (_snapshotHandoffCompleted || coordinator.messages.isEmpty) {
      return;
    }
    _snapshotHandoffCompleted = true;
    _firstPaintSnapshotActive = true;
    if (kDebugMode) {
      debugPrint(
        '[chat.snapshot] start firstPaintSnapshot count=${coordinator.messages.length}',
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _firstPaintSnapshotActive = false;
        });
        if (kDebugMode) {
          debugPrint('[chat.snapshot] finish firstPaintSnapshot');
          debugPrint('[chat.snapshot] switchToLive preserveBottom=true');
        }
      });
    });
  }

  /// 单一入口：keyboard（idle + 焦点）与 emoji 面板互斥；串行先关 IME 再出面板。
  void _toggleEmojiPanel() {
    if (_bottomMode == ChatV2BottomMode.emoji) {
      setState(() {
        _bottomMode = ChatV2BottomMode.idle;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _inputFocusNode.requestFocus();
        }
      });
      return;
    }

    final double imeBottom = MediaQuery.viewInsetsOf(context).bottom;
    if (imeBottom > 0.5) {
      _inputFocusNode.unfocus();
      _scheduleEmojiAfterKeyboardFullyDismissed();
    } else {
      setState(() {
        _bottomMode = ChatV2BottomMode.emoji;
      });
    }
  }

  /// 等 `viewInsets.bottom` 归零后再展示表情面板，避免 IME 与面板同屏造成「二段跳」。
  void _scheduleEmojiAfterKeyboardFullyDismissed() {
    void waitFrame() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        if (MediaQuery.viewInsetsOf(context).bottom > 0.5) {
          waitFrame();
          return;
        }
        if (_bottomMode == ChatV2BottomMode.emoji) {
          return;
        }
        setState(() {
          _bottomMode = ChatV2BottomMode.emoji;
        });
      });
    }

    waitFrame();
  }

  void _openKeyboardFromEmojiMode() {
    if (_bottomMode != ChatV2BottomMode.emoji) {
      return;
    }
    setState(() {
      _bottomMode = ChatV2BottomMode.idle;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _inputFocusNode.requestFocus();
      }
    });
  }

  void _onEmojiPicked(String emoji) {
    final String t = _inputController.text;
    final TextSelection sel = _inputController.selection;
    final int start = sel.isValid ? sel.start : t.length;
    final int end = sel.isValid ? sel.end : t.length;
    final String newText = t.replaceRange(start, end, emoji);
    _inputController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
    _coordinator?.updateDraft(newText);
  }

  void _onEmojiBackspace() {
    final String t = _inputController.text;
    if (t.isEmpty) {
      return;
    }
    final Characters chars = t.characters;
    if (chars.isEmpty) {
      return;
    }
    final String newText = chars.skipLast(1).toString();
    _inputController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
    _coordinator?.updateDraft(newText);
  }

  Future<void> _sendText() async {
    await _coordinator?.sendText(_inputController.text);
  }

  @override
  void dispose() {
    _inputFocusNode.dispose();
    _inputController.dispose();
    _coordinator
      ?..removeListener(_onCoordinatorChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FriendProvider friends = context.watch<FriendProvider>();
    final GroupProvider groups = context.watch<GroupProvider>();
    final IdentityResolver identity = IdentityResolver(
      getFriends: () => friends.friends,
      getGroups: () => groups.groups,
      getGroupMemberDisplayName: groups.memberDisplayNameFor,
    );
    final String resolvedAppBarTitle = identity.resolveTitle(
      widget.targetId,
      widget.type,
      serverConversationName: widget.serverConversationName,
    );

    final ChatCoordinator? coordinator = _coordinator;
    final List<ChatV2MessageViewModel> vmList = coordinator == null
        ? const <ChatV2MessageViewModel>[]
        : mapChatMessagesToViewModels(
            coordinator.messages,
            identity: identity,
            chatType: widget.type,
            chatTargetId: widget.targetId,
          );

    final ChatV2ComposerViewModel composer = ChatV2ComposerViewModel(
      hintText: '发送消息',
      inputText: coordinator?.draftText ?? '',
      bottomMode: _bottomMode,
    );

    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    if (kDebugMode && keyboardInset != _lastViewportKeyboardInsetLogged) {
      debugPrint(
        '[chat.viewport] keyboardInset old=${_lastViewportKeyboardInsetLogged < 0 ? '-' : _lastViewportKeyboardInsetLogged} new=$keyboardInset',
      );
      debugPrint('[chat.viewport] viewportChanged reason=keyboard');
      _lastViewportKeyboardInsetLogged = keyboardInset;
    }

    return SecondaryPageScaffoldV2(
      title: resolvedAppBarTitle,
      resizeToAvoidBottomInset: true,
      /// 与 Scaffold 键盘避让一致，由 body 参与 inset；底部安全区交给 [ChatBottomV2] 内 SafeArea。
      safeAreaBottom: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                if (kDebugMode &&
                    constraints.maxHeight != _lastListVisibleHeightLogged) {
                  debugPrint(
                    '[chat.viewport] listVisibleHeight old=${_lastListVisibleHeightLogged < 0 ? '-' : _lastListVisibleHeightLogged} new=${constraints.maxHeight}',
                  );
                  _lastListVisibleHeightLogged = constraints.maxHeight;
                }
                if (coordinator != null &&
                    coordinator.shouldShowInitialLoading &&
                    vmList.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ChatMessageListV2(
                  messages: vmList,
                  firstPaintSnapshotHandoff:
                      _firstPaintSnapshotActive && vmList.isNotEmpty,
                  onLoadOlder: coordinator?.loadOlderMessages,
                  hasMoreOlder: coordinator?.hasMoreHistory ?? false,
                  isLoadingOlder: coordinator?.isLoadingHistory ?? false,
                );
              },
            ),
          ),
          ChatBottomV2(
            viewModel: composer,
            controller: _inputController,
            focusNode: _inputFocusNode,
            onInputChanged: (String value) => _coordinator?.updateDraft(value),
            onSend: _sendText,
            onEmojiTap: _toggleEmojiPanel,
            onRequestKeyboardFromEmoji: _openKeyboardFromEmojiMode,
            onEmojiSelected: _onEmojiPicked,
            onEmojiBackspace: _onEmojiBackspace,
          ),
        ],
      ),
    );
  }
}
