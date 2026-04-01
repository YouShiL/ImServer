import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hailiao_flutter/models/conversation_dto.dart';
import 'package:hailiao_flutter/models/emoji.dart';
import 'package:hailiao_flutter/models/message_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/providers/auth_provider.dart';
import 'package:hailiao_flutter/providers/blacklist_provider.dart';
import 'package:hailiao_flutter/providers/message_provider.dart';
import 'package:hailiao_flutter/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

abstract class ChatScreenApi {
  Future<ResponseDTO<Map<String, dynamic>>> getUserOnlineInfo(int userId);
  Future<ResponseDTO<List<MessageDTO>>> searchMessages(
    String keyword, {
    int page,
    int size,
  });
  Future<ResponseDTO<List<MessageDTO>>> searchGroupMessages(
    int groupId,
    String keyword, {
    int page,
    int size,
  });
}

class ApiChatScreenApi implements ChatScreenApi {
  const ApiChatScreenApi();

  @override
  Future<ResponseDTO<Map<String, dynamic>>> getUserOnlineInfo(int userId) {
    return ApiService.getUserOnlineInfo(userId);
  }

  @override
  Future<ResponseDTO<List<MessageDTO>>> searchMessages(
    String keyword, {
    int page = 1,
    int size = 50,
  }) {
    return ApiService.searchMessages(keyword, page: page, size: size);
  }

  @override
  Future<ResponseDTO<List<MessageDTO>>> searchGroupMessages(
    int groupId,
    String keyword, {
    int page = 1,
    int size = 50,
  }) {
    return ApiService.searchGroupMessages(
      groupId,
      keyword,
      page: page,
      size: size,
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, ChatScreenApi? api})
    : api = api ?? const ApiChatScreenApi();

  final ChatScreenApi api;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();

  bool _initialized = false;
  bool _isTyping = false;
  bool _showEmojiPicker = false;
  bool _loadingHistory = false;
  bool _hasMoreHistory = true;
  bool _selectionHintShown = false;
  int? _targetId;
  int? _type;
  int _currentPage = 1;
  String _title = '聊天';
  String? _statusText;
  int? _highlightedMessageId;
  final Set<int> _selectedMessageIds = <int>{};
  MessageDTO? _replyingTo;
  MessageDTO? _editingMessage;

  static const int _pageSize = 20;
  static const List<String> _searchFilters = <String>[
    '全部',
    '文本',
    '图片',
    '视频',
    '音频',
  ];
  static const List<String> _searchSenderFilters = <String>[
    '全部来源',
    '我发的',
    '对方发送',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    _scrollController.addListener(_handleScroll);
    _initializeChat();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    context.read<BlacklistProvider>().loadBlacklist();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _targetId = args?['targetId'] as int? ?? 1;
    _type = args?['type'] as int? ?? 1;
    _title = args?['title'] as String? ?? '聊天';
    _currentPage = 1;
    _hasMoreHistory = true;
    _loadingHistory = false;

    final provider = context.read<MessageProvider>();
    provider.clearMessages();
    await provider.loadConversations();
    _restoreDraft(provider.conversations);

    await _loadHistoryPage(page: 1, reset: true);
    if (_type == 1 && _targetId != null) {
      await provider.markAsRead(_targetId!);
      await _loadPresence(_targetId!);
    }
    _scrollToLatest();
  }

  void _cacheDraft(String value) {
    context.read<MessageProvider>().setDraft(_targetId, _type, value);
  }

  void _restoreDraft(List<ConversationDTO> conversations) {
    final cachedDraft = context.read<MessageProvider>().getDraft(_targetId, _type);
    String? conversationDraft;
    for (final item in conversations) {
      if (item.targetId == _targetId &&
          item.type == _type &&
          item.draft != null &&
          item.draft!.trim().isNotEmpty) {
        conversationDraft = item.draft;
        break;
      }
    }
    final draft = cachedDraft ?? conversationDraft;
    if (draft == null || draft.isEmpty) {
      return;
    }
    _messageController.text = draft;
    _messageController.selection = TextSelection.collapsed(
      offset: draft.length,
    );
    _isTyping = draft.isNotEmpty;
  }

  Future<void> _loadHistoryPage({
    required int page,
    bool reset = false,
  }) async {
    if (_targetId == null || _type == null) {
      return;
    }
    if (_loadingHistory) {
      return;
    }

    setState(() {
      _loadingHistory = true;
    });

    final provider = context.read<MessageProvider>();
    final beforeCount = provider.messages.length;

    if (_type == 1) {
      await provider.loadPrivateMessages(_targetId!, page, _pageSize);
    } else {
      await provider.loadGroupMessages(_targetId!, page, _pageSize);
    }

    if (!mounted) {
      return;
    }

    final afterCount = provider.messages.length;
    final loadedCount = reset ? afterCount : (afterCount - beforeCount);

    setState(() {
      _currentPage = page;
      _hasMoreHistory = loadedCount >= _pageSize;
      _loadingHistory = false;
    });
  }

  Future<void> _loadPresence(int userId) async {
    try {
      final response = await widget.api.getUserOnlineInfo(userId);
      if (!mounted || !response.isSuccess || response.data == null) {
        return;
      }
      final data = response.data!;
      final isOnline = data['isOnline'] == true;
      final lastOnline = (data['lastOnline'] ?? '').toString();
      setState(() {
        _statusText = isOnline
            ? '在线'
            : (lastOnline.isNotEmpty ? '最后在线 $lastOnline' : '离线');
      });
    } catch (_) {}
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || _loadingHistory || !_hasMoreHistory) {
      return;
    }
    if (_scrollController.position.pixels <= 80) {
      _loadHistoryPage(page: _currentPage + 1);
    }
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  bool get _selectionMode => _selectedMessageIds.isNotEmpty;

  void _toggleMessageSelection(MessageDTO message) {
    final messageId = message.id;
    if (messageId == null) {
      return;
    }
    final enteringSelectionMode = _selectedMessageIds.isEmpty;
    setState(() {
      _replyingTo = null;
      _editingMessage = null;
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
      } else {
        _selectedMessageIds.add(messageId);
      }
    });
    if (enteringSelectionMode && !_selectionHintShown && mounted) {
      _selectionHintShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '已进入多选模式，可在顶部筛选、转发、复制或移除所选消息。',
          ),
        ),
      );
    }
  }

  void _clearSelection() {
    if (_selectedMessageIds.isEmpty) {
      return;
    }
    setState(() {
      _selectedMessageIds.clear();
    });
  }

  Future<void> _requestClearSelection() async {
    if (_selectedMessageIds.isEmpty) {
      return;
    }
    if (_selectedMessageIds.length < 5) {
      _clearSelection();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('清空选择'),
        content: Text(
          '当前已选择 ${_selectedMessageIds.length} 条消息，确定清空选择吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('保留'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _clearSelection();
    }
  }

  List<MessageDTO> get _selectedMessages {
    final ids = _selectedMessageIds;
    return context
        .read<MessageProvider>()
        .messages
        .where((message) => message.id != null && ids.contains(message.id))
        .toList();
  }

  bool _isMessageSelected(MessageDTO message) {
    return message.id != null && _selectedMessageIds.contains(message.id);
  }

  void _selectAllMessages() {
    final messages = context.read<MessageProvider>().messages;
    setState(() {
      _replyingTo = null;
      _editingMessage = null;
      _selectedMessageIds
        ..clear()
        ..addAll(
          messages
              .where((message) => message.id != null)
              .map((message) => message.id!),
        );
    });
  }

  void _invertSelectedMessages() {
    final messages = context.read<MessageProvider>().messages;
    final currentIds = messages
        .where((message) => message.id != null)
        .map((message) => message.id!)
        .toList();
    setState(() {
      _replyingTo = null;
      _editingMessage = null;
      final next = <int>{};
      for (final id in currentIds) {
        if (!_selectedMessageIds.contains(id)) {
          next.add(id);
        }
      }
      _selectedMessageIds
        ..clear()
        ..addAll(next);
    });
  }

  void _selectMessagesForDate(String bucket) {
    final messages = context.read<MessageProvider>().messages;
    final dayIds = messages
        .where((message) => message.id != null && _dateBucket(message) == bucket)
        .map((message) => message.id!)
        .toList();
    if (dayIds.isEmpty) {
      return;
    }
    setState(() {
      _replyingTo = null;
      _editingMessage = null;
      _selectedMessageIds.addAll(dayIds);
    });
  }

  void _selectMessagesByType(int msgType) {
    final messages = context.read<MessageProvider>().messages;
    final typeIds = messages
        .where((message) => message.id != null && (message.msgType ?? 1) == msgType)
        .map((message) => message.id!)
        .toList();
    if (typeIds.isEmpty) {
      return;
    }
    setState(() {
      _replyingTo = null;
      _editingMessage = null;
      _selectedMessageIds.addAll(typeIds);
    });
  }

  void _selectMessagesBySender(bool selectMine) {
    final currentUserId = context.read<AuthProvider>().user?.id;
    final messages = context.read<MessageProvider>().messages;
    final senderIds = messages
        .where(
          (message) =>
              message.id != null &&
              (selectMine
                  ? message.fromUserId == currentUserId
                  : message.fromUserId != currentUserId),
        )
        .map((message) => message.id!)
        .toList();
    if (senderIds.isEmpty) {
      return;
    }
    setState(() {
      _replyingTo = null;
      _editingMessage = null;
      _selectedMessageIds.addAll(senderIds);
    });
  }

  String _messageTypeLabel(MessageDTO message) {
    switch (message.msgType ?? 1) {
      case 2:
        return '图片';
      case 3:
        return '音频';
      case 4:
        return '视频';
      default:
        return '文本';
    }
  }

  String _messagePathLabel(MessageDTO message) {
    return (message.content ?? '').isEmpty ? '-' : message.content!;
  }

  String _selectionSummaryText() {
    final messages = _selectedMessages;
    if (messages.isEmpty) {
      return '当前未选择消息';
    }

    final textCount = messages.where((item) => (item.msgType ?? 1) == 1).length;
    final imageCount =
        messages.where((item) => (item.msgType ?? 1) == 2).length;
    final audioCount =
        messages.where((item) => (item.msgType ?? 1) == 3).length;
    final videoCount =
        messages.where((item) => (item.msgType ?? 1) == 4).length;
    final mineCount = messages
        .where((item) => item.fromUserId == context.read<AuthProvider>().user?.id)
        .length;
    final othersCount = messages.length - mineCount;

    final parts = <String>[
      if (textCount > 0) '$textCount 条文本',
      if (imageCount > 0) '$imageCount 条图片',
      if (audioCount > 0) '$audioCount 条音频',
      if (videoCount > 0) '$videoCount 条视频',
      '$mineCount 条我发的',
      '$othersCount 条对方发送',
    ];
    return parts.join(' · ');
  }

  String _mediaSummaryText(MessageDTO message) {
    return [
      '类型：${_messageTypeLabel(message)}',
      '时间：${message.createdAt ?? '-'}',
      '路径：${_messagePathLabel(message)}',
    ].join('\n');
  }

  String _searchResultContext(MessageDTO message, String senderLabel) {
    final tags = <String>[
      _messageTypeLabel(message),
      senderLabel,
      if (message.forwardFromMsgId != null) '转发',
      if (message.replyToMsgId != null) '回复',
      if (message.isEdited == true) '已编辑',
    ];
    return [
      message.createdAt ?? '',
      tags.join(' · '),
    ].where((part) => part.isNotEmpty).join(' · ');
  }

  Future<void> _showSelectionOverview() async {
    final messages = _selectedMessages;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '选择概览',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                '已选择 ${messages.length} 条',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _selectionSummaryText(),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '可用操作',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                '全选 / 反选 / 按类型选择 / 按发送方选择',
                style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
              ),
              const SizedBox(height: 6),
              const Text(
                '转发 / 复制摘要 / 移出当前视图',
                style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openMediaDetails(MessageDTO message) async {
    final path = message.content ?? '';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${_messageTypeLabel(message)}详情'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('类型：${_messageTypeLabel(message)}'),
            const SizedBox(height: 8),
            Text('时间：${message.createdAt ?? '-'}'),
            const SizedBox(height: 8),
            Text('路径：${_messagePathLabel(message)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('关闭'),
          ),
          if ((message.msgType ?? 1) != 1)
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
                ClipboardData(text: _mediaSummaryText(message)),
              );
              if (!mounted) {
                return;
              }
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_messageTypeLabel(message)}摘要已复制'),
                ),
              );
            },
            child: const Text('复制摘要'),
          ),
          FilledButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: path));
              if (!mounted) {
                return;
              }
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_messageTypeLabel(message)}路径已复制'),
                ),
              );
            },
            child: const Text('复制路径'),
          ),
        ],
      ),
    );
  }

  Future<void> _copySelectedMessagesSummary() async {
    final messages = _selectedMessages;
    if (messages.isEmpty) {
      return;
    }
    final summary = messages.length > 1
        ? '已复制 ${messages.length} 条消息摘要到剪贴板。'
        : '消息摘要已复制到剪贴板。';
    await _copyMessagesSummary(
      messages,
      title: '复制结果',
      successMessage: summary,
      trailingNote:
          '当前选择已保留，你可以继续转发或移除这一组消息。',
    );
  }

  String _messagesSummaryText(List<MessageDTO> messages) {
    final buffer = StringBuffer();
    for (final message in messages) {
      buffer.writeln([
        message.createdAt ?? '',
        _summary(message),
      ].where((item) => item.isNotEmpty).join(' '));
    }
    return buffer.toString().trim();
  }

  Future<void> _copyMessagesSummary(
    List<MessageDTO> messages, {
    required String title,
    required String successMessage,
    String? trailingNote,
  }) async {
    if (messages.isEmpty) {
      return;
    }
    final text = _messagesSummaryText(messages);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage)),
    );
    await _showBatchOperationSummary(
      title: title,
      summary: trailingNote == null ? text : '$text\n\n$trailingNote',
    );
  }

  void _addMessagesToSelection(Iterable<MessageDTO> messages) {
    final ids = messages
        .where((message) => message.id != null)
        .map((message) => message.id!)
        .toSet();
    if (ids.isEmpty) {
      return;
    }
    setState(() {
      _replyingTo = null;
      _editingMessage = null;
      _selectedMessageIds.addAll(ids);
    });
  }

  void _removeMessagesFromSelection(Iterable<MessageDTO> messages) {
    final ids = messages
        .where((message) => message.id != null)
        .map((message) => message.id!)
        .toSet();
    if (ids.isEmpty) {
      return;
    }
    setState(() {
      _selectedMessageIds.removeAll(ids);
    });
  }

  List<MessageDTO> _selectedMessagesFrom(Iterable<MessageDTO> messages) {
    return messages.where(_isMessageSelected).toList();
  }

  String _filteredSelectionSummary(List<MessageDTO> messages) {
    if (messages.isEmpty) {
      return '当前还没有选中的搜索结果。';
    }
    final textCount = messages.where((item) => (item.msgType ?? 1) == 1).length;
    final imageCount =
        messages.where((item) => (item.msgType ?? 1) == 2).length;
    final audioCount =
        messages.where((item) => (item.msgType ?? 1) == 3).length;
    final videoCount =
        messages.where((item) => (item.msgType ?? 1) == 4).length;
    final mineCount = messages
        .where((item) => item.fromUserId == context.read<AuthProvider>().user?.id)
        .length;
    final othersCount = messages.length - mineCount;
    final parts = <String>[
      if (textCount > 0) '文本 $textCount',
      if (imageCount > 0) '图片 $imageCount',
      if (audioCount > 0) '音频 $audioCount',
      if (videoCount > 0) '视频 $videoCount',
      '我发的 $mineCount',
      '对方发送 $othersCount',
    ];
    return parts.join(' · ');
  }

  Map<String, int> _messageTypeStats(List<MessageDTO> messages) {
    return <String, int>{
      '文本': messages.where((item) => (item.msgType ?? 1) == 1).length,
      '图片': messages.where((item) => (item.msgType ?? 1) == 2).length,
      '音频': messages.where((item) => (item.msgType ?? 1) == 3).length,
      '视频': messages.where((item) => (item.msgType ?? 1) == 4).length,
    };
  }

  Future<void> _focusFirstSelectedMessage() async {
    final message = _selectedMessages.isNotEmpty ? _selectedMessages.first : null;
    if (message?.id == null) {
      return;
    }
    await _focusMessage(message!.id);
  }

  Future<void> _removeMessagesFromCurrentView(
    List<MessageDTO> messages, {
    required String title,
    required String successMessage,
    String? trailingNote,
    bool clearSelectionAfter = false,
  }) async {
    final messageIds = messages.map((item) => item.id).whereType<int>().toList();
    if (messageIds.isEmpty) {
      return;
    }
    context.read<MessageProvider>().removeMessagesLocal(messageIds);
    if (clearSelectionAfter) {
      _clearSelection();
    } else {
      _removeMessagesFromSelection(messages);
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage)),
    );
    await _showBatchOperationSummary(
      title: title,
      summary: trailingNote == null
          ? successMessage
          : '$successMessage\n\n$trailingNote',
    );
  }

  Future<void> _showBatchOperationSummary({
    required String title,
    required String summary,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                summary,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4B5563),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty ||
        _targetId == null ||
        _type == null) {
      return;
    }
    final provider = context.read<MessageProvider>();
    final content = EmojiList.replaceEmojisWithPlaceholders(
      _messageController.text.trim(),
    );
    bool success;

    if (_editingMessage?.id != null) {
      success = await provider.editMessage(_editingMessage!.id!, content);
    } else if (_replyingTo?.id != null) {
      success = await provider.replyMessage(
        replyToMsgId: _replyingTo!.id!,
        toUserId: _type == 1 ? _targetId : null,
        groupId: _type == 1 ? null : _targetId,
        content: content,
      );
    } else {
      success = _type == 1
          ? await provider.sendPrivateMessage(_targetId!, content, 1)
          : await provider.sendGroupMessage(_targetId!, content, 1);
    }

    if (!mounted || !success) {
      if (mounted && !success) {
        _showRetrySnackBar(
          message: context.read<MessageProvider>().error ?? '发送失败。',
          onRetry: _sendMessage,
        );
      }
      return;
    }

    _messageController.clear();
    context.read<MessageProvider>().clearDraft(_targetId, _type);
    setState(() {
      _isTyping = false;
      _replyingTo = null;
      _editingMessage = null;
      _showEmojiPicker = false;
    });
    _scrollToLatest();
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    final file = await _imagePicker.pickImage(source: source);
    if (file == null || _targetId == null || _type == null) {
      return;
    }
    await _sendImageFromPath(file.path);
  }

  Future<void> _pickAndSendVideo() async {
    final file = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (file == null || _targetId == null || _type == null) {
      return;
    }
    await _sendVideoFromPath(file.path);
  }

  Future<void> _sendImageFromPath(String path) async {
    if (_targetId == null || _type == null) {
      return;
    }
    final success = await context.read<MessageProvider>().sendImageMessage(
          _targetId!,
          path,
          isGroup: _type != 1,
        );
    if (!mounted) {
      return;
    }
    if (success) {
      _scrollToLatest();
      return;
    }
    final error = context.read<MessageProvider>().error ?? '图片发送失败。';
    final message = error.toLowerCase().contains('upload')
        ? '图片上传失败。'
        : '图片发送失败。';
    _showRetrySnackBar(
      message: message,
      onRetry: () async {
        _sendImageFromPath(path);
      },
    );
  }

  Future<void> _sendVideoFromPath(String path) async {
    if (_targetId == null || _type == null) {
      return;
    }
    final success = await context.read<MessageProvider>().sendVideoMessage(
          _targetId!,
          path,
          isGroup: _type != 1,
        );
    if (!mounted) {
      return;
    }
    if (success) {
      _scrollToLatest();
      return;
    }
    final error = context.read<MessageProvider>().error ?? '视频发送失败。';
    final message = error.toLowerCase().contains('upload')
        ? '视频上传失败。'
        : '视频发送失败。';
    _showRetrySnackBar(
      message: message,
      onRetry: () async {
        _sendVideoFromPath(path);
      },
    );
  }

  Future<void> _sendAudioFromPath(
    String path, {
    int duration = 0,
  }) async {
    if (_targetId == null || _type == null) {
      return;
    }
    final file = File(path);
    if (!file.existsSync()) {
      _showRetrySnackBar(
        message: '未找到音频文件，请检查本地路径。',
        onRetry: () async {
          _promptAudioPathAndSend(initialPath: path, initialDuration: duration);
        },
      );
      return;
    }

    final success = await context.read<MessageProvider>().sendAudioMessage(
          _targetId!,
          path,
          duration,
          isGroup: _type != 1,
        );
    if (!mounted) {
      return;
    }
    if (success) {
      _scrollToLatest();
      return;
    }

    final error = context.read<MessageProvider>().error ?? '音频发送失败。';
    final message = error.toLowerCase().contains('upload')
        ? '音频上传失败。'
        : '音频发送失败。';
    _showRetrySnackBar(
      message: message,
      onRetry: () async {
        _sendAudioFromPath(path, duration: duration);
      },
    );
  }

  Future<void> _promptAudioPathAndSend({
    String initialPath = '',
    int initialDuration = 0,
  }) async {
    final pathController = TextEditingController(text: initialPath);
    final durationController = TextEditingController(
      text: initialDuration > 0 ? initialDuration.toString() : '',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('发送音频'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pathController,
                decoration: const InputDecoration(
                  labelText: '本地文件路径',
                  hintText: 'E:\\Music\\voice.mp3',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '时长（秒）',
                  hintText: '可选',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final path = pathController.text.trim();
              final duration = int.tryParse(durationController.text.trim()) ?? 0;
              Navigator.pop(dialogContext);
              if (path.isEmpty) {
                _showRetrySnackBar(
                  message: '请输入音频文件路径。',
                  onRetry: () async {
                    await _promptAudioPathAndSend(
                      initialPath: path,
                      initialDuration: duration,
                    );
                  },
                );
                return;
              }
              _sendAudioFromPath(path, duration: duration);
            },
            child: const Text('发送'),
          ),
        ],
      ),
    );
  }

  void _showMediaOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('选择图片'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('拍照发送'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('选择视频'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendVideo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.audiotrack_outlined),
              title: const Text('从路径发送音频'),
              onTap: () {
                Navigator.pop(context);
                _promptAudioPathAndSend();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recallMessage(MessageDTO message) async {
    if (message.id == null) {
      return;
    }
    final success = await context.read<MessageProvider>().recallMessage(
          message.id!,
        );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? '消息已撤回' : '撤回失败')),
    );
  }

  void _showRetrySnackBar({
    required String message,
    required Future<void> Function() onRetry,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: '重试',
          onPressed: () {
            onRetry();
          },
        ),
      ),
    );
  }

  Future<void> _openUserDetail() async {
    if (_selectionMode) {
      return;
    }
    if (_type != 1 || _targetId == null) {
      return;
    }
    await Navigator.pushNamed(
      context,
      '/user-detail',
      arguments: {'userId': _targetId},
    );
  }

  String _summary(MessageDTO? message) {
    if (message == null) {
      return '';
    }
    switch (message.msgType ?? 1) {
      case 2:
        return '[图片]';
      case 3:
        return '[音频]';
      case 4:
        return '[视频]';
      default:
        return EmojiList.replacePlaceholders(message.content ?? '');
    }
  }

  IconData _messageTypeIcon(MessageDTO message) {
    switch (message.msgType ?? 1) {
      case 2:
        return Icons.image_outlined;
      case 3:
        return Icons.mic_none_outlined;
      case 4:
        return Icons.videocam_outlined;
      default:
        return Icons.chat_bubble_outline;
    }
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
                  child: (message.msgType ?? 1) == 2
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
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.play_circle_fill,
                              size: 72,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '暂未内嵌视频预览。',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              path,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () async {
                                Navigator.pop(dialogContext);
                                await _openMediaDetails(message);
                              },
                              icon: const Icon(Icons.info_outline),
                              label: const Text('查看详情'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white54),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await _openMediaDetails(message);
                },
                icon: const Icon(Icons.info_outline, color: Colors.white),
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

  bool _matchesSearchFilter(MessageDTO message, String filter) {
    switch (filter) {
      case '文本':
        return (message.msgType ?? 1) == 1;
      case '图片':
        return (message.msgType ?? 1) == 2;
      case '音频':
        return (message.msgType ?? 1) == 3;
      case '视频':
        return (message.msgType ?? 1) == 4;
      default:
        return true;
    }
  }

  bool _matchesSenderFilter(MessageDTO message, String filter) {
    final currentUserId = context.read<AuthProvider>().user?.id;
    switch (filter) {
      case '我发的':
        return message.fromUserId == currentUserId;
      case '对方发送':
        return message.fromUserId != currentUserId;
      default:
        return true;
    }
  }

  int _countMessagesForFilter(List<MessageDTO> messages, String filter) {
    if (filter == '全部') {
      return messages.length;
    }
    return messages.where((item) => _matchesSearchFilter(item, filter)).length;
  }

  TextSpan _highlightedSummarySpan(MessageDTO message, String keyword) {
    final summary = _summary(message);
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) {
      return TextSpan(text: summary);
    }

    final lowerSummary = summary.toLowerCase();
    final lowerKeyword = trimmed.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;

    while (true) {
      final index = lowerSummary.indexOf(lowerKeyword, start);
      if (index == -1) {
        spans.add(TextSpan(text: summary.substring(start)));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: summary.substring(start, index)));
      }
      spans.add(
        TextSpan(
          text: summary.substring(index, index + trimmed.length),
          style: const TextStyle(
            backgroundColor: Color(0xFFFDE68A),
            color: Color(0xFF92400E),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      start = index + trimmed.length;
    }

    return TextSpan(children: spans);
  }

  String _dateBucket(MessageDTO message) {
    final createdAt = message.createdAt ?? '';
    if (createdAt.length >= 10) {
      return createdAt.substring(0, 10);
    }
    return createdAt;
  }

  String _dateLabel(MessageDTO message) {
    final bucket = _dateBucket(message);
    if (bucket.isEmpty) {
      return '未知日期';
    }
    final now = DateTime.now();
    final today = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final yesterdayDate = now.subtract(const Duration(days: 1));
    final yesterday = '${yesterdayDate.year.toString().padLeft(4, '0')}-'
        '${yesterdayDate.month.toString().padLeft(2, '0')}-'
        '${yesterdayDate.day.toString().padLeft(2, '0')}';
    if (bucket == today) {
      return '今天';
    }
    if (bucket == yesterday) {
      return '昨天';
    }
    return bucket;
  }

  Widget _buildDateDivider(String label, {String? bucket}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const Expanded(
            child: Divider(
              thickness: 0.8,
              color: Color(0xFFE5E7EB),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_selectionMode && bucket != null) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _selectMessagesForDate(bucket),
                    child: const Icon(
                      Icons.checklist_rtl_outlined,
                      size: 16,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Expanded(
            child: Divider(
              thickness: 0.8,
              color: Color(0xFFE5E7EB),
            ),
          ),
        ],
      ),
    );
  }

  MessageDTO? _findReplyTarget(int? id, List<MessageDTO> messages) {
    if (id == null) {
      return null;
    }
    for (final message in messages) {
      if (message.id == id) {
        return message;
      }
    }
    return null;
  }

  Future<void> _focusMessage(int? messageId) async {
    if (messageId == null) {
      return;
    }
    var messages = context.read<MessageProvider>().messages;
    var index = messages.indexWhere((message) => message.id == messageId);
    while (index == -1 && _hasMoreHistory) {
      await _loadHistoryPage(page: _currentPage + 1);
      messages = context.read<MessageProvider>().messages;
      index = messages.indexWhere((message) => message.id == messageId);
    }
    if (index == -1) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已找到该消息，但它还没有加载到当前页面。'),
        ),
      );
      return;
    }

    setState(() {
      _highlightedMessageId = messageId;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      final targetOffset = (index * 120).toDouble();
      final maxScroll = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        targetOffset.clamp(0, maxScroll),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted || _highlightedMessageId != messageId) {
      return;
    }
    setState(() {
      _highlightedMessageId = null;
    });
  }

  Future<List<MessageDTO>> _searchMessages(String keyword) async {
    if (keyword.trim().isEmpty || _targetId == null || _type == null) {
      return [];
    }
    final response = _type == 1
        ? await widget.api.searchMessages(keyword.trim(), page: 1, size: 50)
        : await widget.api.searchGroupMessages(
            _targetId!,
            keyword.trim(),
            page: 1,
            size: 50,
          );
    if (!response.isSuccess || response.data == null) {
      return [];
    }
    if (_type != 1) {
      return response.data!;
    }
    return response.data!
        .where((message) {
          final relatedUser = message.fromUserId == _targetId ||
              message.toUserId == _targetId;
          return relatedUser;
        })
        .toList();
  }

  Future<void> _showSearchDialog() async {
    final keywordController = TextEditingController();
    final results = <MessageDTO>[];
    var loading = false;
    String? errorText;
    String? searchWorkbenchNote;
    var selectedFilter = '全部';
    var selectedSenderFilter = '全部来源';
    var selectedSort = '最新优先';
    var selectedFirst = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('搜索消息'),
          content: SizedBox(
            width: 420,
            height: 360,
            child: Column(
              children: [
                TextField(
                  controller: keywordController,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: '输入关键词',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (_) async {
                    setDialogState(() {
                      searchWorkbenchNote = null;
                    });
                    await _runSearch(
                      keywordController.text,
                      setDialogState,
                      results,
                      (value) => loading = value,
                      (value) => errorText = value,
                    );
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _searchFilters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filter = _searchFilters[index];
                      final selected = filter == selectedFilter;
                      return ChoiceChip(
                        label: Text(filter),
                        selected: selected,
                        onSelected: (_) {
                          setDialogState(() {
                            selectedFilter = filter;
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _searchSenderFilters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filter = _searchSenderFilters[index];
                      final selected = filter == selectedSenderFilter;
                      return ChoiceChip(
                        label: Text(filter),
                        selected: selected,
                        onSelected: (_) {
                          setDialogState(() {
                            selectedSenderFilter = filter;
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                if (results.isNotEmpty)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '结果：${results.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: '排序结果',
                        onSelected: (value) {
                          setDialogState(() {
                            selectedSort = value;
                          });
                        },
                        itemBuilder: (context) => [
                          CheckedPopupMenuItem(
                            value: '最新优先',
                            checked: selectedSort == '最新优先',
                            child: const Text('最新优先'),
                          ),
                          CheckedPopupMenuItem(
                            value: '最早优先',
                            checked: selectedSort == '最早优先',
                            child: const Text('最早优先'),
                          ),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.sort, size: 18),
                              const SizedBox(width: 4),
                              Text(selectedSort, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                if (results.isNotEmpty) const SizedBox(height: 8),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(),
                  )
                else if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      errorText!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  )
                else if (results.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('请输入关键词开始搜索'),
                  )
                else
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final filteredResults = results
                            .where(
                              (item) =>
                                  _matchesSearchFilter(item, selectedFilter) &&
                                  _matchesSenderFilter(item, selectedSenderFilter),
                            )
                            .toList();
                        filteredResults.sort((a, b) {
                          final timeCompare = (b.createdAt ?? '').compareTo(a.createdAt ?? '');
                          return selectedSort == '最早优先' ? -timeCompare : timeCompare;
                        });
                        if (selectedFirst) {
                          filteredResults.sort((a, b) {
                            final aSelected = _isMessageSelected(a) ? 1 : 0;
                            final bSelected = _isMessageSelected(b) ? 1 : 0;
                            return bSelected.compareTo(aSelected);
                          });
                        }
                        if (filteredResults.isEmpty) {
                          return const Center(child: Text('没有符合当前筛选条件的消息。'));
                        }
                        final selectedResults = _selectedMessagesFrom(filteredResults);
                        final selectedInResults = selectedResults.length;
                        final filteredTypeStats = _messageTypeStats(filteredResults);
                        final mineResults = filteredResults.where((item) => item.fromUserId == context.read<AuthProvider>().user?.id).length;
                        final otherResults = filteredResults.length - mineResults;
                        return Column(
                          children: [
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  _buildSearchStatChip('筛选后', '', const Color(0xFF111827)),
                                  _buildSearchStatChip('已选中', '', const Color(0xFF2563EB)),
                                  _buildSearchStatChip('我发的', '', const Color(0xFF0F766E)),
                                  _buildSearchStatChip('对方发送', '', const Color(0xFF7C3AED)),
                                  for (final entry in filteredTypeStats.entries)
                                    if (entry.value > 0)
                                      _buildSearchStatChip(entry.key, '', const Color(0xFF6B7280)),
                                ],
                              ),
                            ),
                            if (searchWorkbenchNote != null)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFBBF7D0)),
                                ),
                                child: Text(
                                  searchWorkbenchNote!,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF166534), fontWeight: FontWeight.w600),
                                ),
                              ),
                            Wrap(
                              alignment: WrapAlignment.end,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                FilterChip(
                                  label: const Text('已选优先'),
                                  selected: selectedFirst,
                                  onSelected: (value) {
                                    setDialogState(() {
                                      selectedFirst = value;
                                    });
                                  },
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    setDialogState(() {
                                      results.clear();
                                      errorText = null;
                                      searchWorkbenchNote = '搜索结果已清空，请重新输入关键词继续搜索。';
                                    });
                                  },
                                  icon: const Icon(Icons.clear_all_outlined),
                                  label: const Text('清空结果'),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                    _scrollToLatest();
                                  },
                                  icon: const Icon(Icons.vertical_align_bottom),
                                  label: const Text('回到最新'),
                                ),
                              ],
                            ),
                            Expanded(
                              child: ListView.separated(
                                itemCount: filteredResults.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final item = filteredResults[index];
                                  final isSelected = _isMessageSelected(item);
                                  final senderLabel = selectedSenderFilter == '全部来源'
                                      ? (item.fromUserId == context.read<AuthProvider>().user?.id ? '我发的' : '对方发送')
                                      : selectedSenderFilter;
                                  return ListTile(
                                    selected: isSelected,
                                    selectedTileColor: const Color(0xFFEFF6FF),
                                    leading: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(_messageTypeIcon(item), size: 18),
                                        const SizedBox(width: 8),
                                        Icon(
                                          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                          size: 18,
                                          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF),
                                        ),
                                      ],
                                    ),
                                    title: RichText(
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      text: TextSpan(
                                        style: const TextStyle(color: Color(0xFF111827), fontSize: 14),
                                        children: [_highlightedSummarySpan(item, keywordController.text)],
                                      ),
                                    ),
                                    subtitle: Text(_searchResultContext(item, senderLabel)),
                                    trailing: PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_horiz),
                                      onSelected: (value) async {
                                        if (value == 'select') {
                                          final wasEmpty = _selectedMessageIds.isEmpty;
                                          _toggleMessageSelection(item);
                                          setDialogState(() {});
                                          if (!mounted) return;
                                          final nowSelected = _isMessageSelected(item);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                nowSelected
                                                    ? (wasEmpty ? '已加入选择集，可在顶部继续进行批量操作。' : '消息已加入选择集')
                                                    : '消息已从选择集中移除',
                                              ),
                                            ),
                                          );
                                        } else if (value == 'copy') {
                                          await Clipboard.setData(ClipboardData(text: _summary(item)));
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('搜索结果已复制')),
                                          );
                                        } else if (value == 'details') {
                                          if ((item.msgType ?? 1) == 1) {
                                            await Clipboard.setData(ClipboardData(text: _mediaSummaryText(item)));
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('消息详情已复制')),
                                            );
                                          } else {
                                            await _openMediaDetails(item);
                                          }
                                        } else if (value == 'preview') {
                                          if ((item.msgType ?? 1) != 1) {
                                            await _openMediaPreview(item);
                                          }
                                        } else if (value == 'forward') {
                                          Navigator.pop(dialogContext);
                                          await _showForwardTargets(item);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem(value: 'select', child: Text(isSelected ? '移出选择' : '加入选择')),
                                        const PopupMenuItem(value: 'copy', child: Text('复制摘要')),
                                        const PopupMenuItem(value: 'forward', child: Text('转发')),
                                        if ((item.msgType ?? 1) != 1)
                                          const PopupMenuItem(value: 'preview', child: Text('预览')),
                                        const PopupMenuItem(value: 'details', child: Text('打开详情')),
                                      ],
                                    ),
                                    onLongPress: () {
                                      _toggleMessageSelection(item);
                                      setDialogState(() {});
                                    },
                                    onTap: () {
                                      Navigator.pop(dialogContext);
                                      _focusMessage(item.id);
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('关闭')),
            FilledButton(
              onPressed: () async {
                setDialogState(() {
                  searchWorkbenchNote = null;
                });
                await _runSearch(
                  keywordController.text,
                  setDialogState,
                  results,
                  (value) => loading = value,
                  (value) => errorText = value,
                );
              },
              child: const Text('搜索'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runSearch(
    String keyword,
    void Function(void Function()) setDialogState,
    List<MessageDTO> results,
    void Function(bool value) setLoading,
    void Function(String? value) setErrorText,
  ) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) {
      setDialogState(() {
        results.clear();
        setErrorText('请输入关键词。');
      });
      return;
    }

    setDialogState(() {
      setLoading(true);
      setErrorText(null);
      results.clear();
    });

    try {
      final data = await _searchMessages(trimmed);
      setDialogState(() {
        results.addAll(data);
        setLoading(false);
        if (data.isEmpty) {
          setErrorText('没有找到匹配的消息。');
        }
      });
    } catch (_) {
      setDialogState(() {
        setLoading(false);
        setErrorText('搜索失败，请稍后重试。');
      });
    }
  }

  Future<void> _showForwardTargets(
    MessageDTO message, {
    List<MessageDTO>? messages,
  }) async {
    final provider = context.read<MessageProvider>();
    if (provider.conversations.isEmpty) {
      await provider.loadConversations();
    }
    if (!mounted) {
      return;
    }

    final candidates = provider.conversations.where((conversation) {
      final sameTarget = conversation.targetId == _targetId;
      final sameType = conversation.type == _type;
      return !(sameTarget && sameType);
    }).toList()
      ..sort((a, b) {
        final aTop = a.isTop == true ? 1 : 0;
        final bTop = b.isTop == true ? 1 : 0;
        final topCompare = bTop.compareTo(aTop);
        if (topCompare != 0) {
          return topCompare;
        }
        return (b.lastMessageTime ?? '').compareTo(a.lastMessageTime ?? '');
      });

    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前没有可转发到的会话。')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final searchController = TextEditingController();
        var keyword = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filteredCandidates = candidates.where((conversation) {
              final text = [
                conversation.name ?? '',
                conversation.lastMessage ?? '',
              ].join(' ').toLowerCase();
              return keyword.trim().isEmpty ||
                  text.contains(keyword.trim().toLowerCase());
            }).toList();

            return SafeArea(
              child: SizedBox(
                height: 420,
                child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '选择转发目标',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: '搜索会话',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setSheetState(() {
                          keyword = value;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: filteredCandidates.isEmpty
                        ? const Center(
                            child: Text('没有匹配的会话。'),
                          )
                        : ListView.separated(
                            itemCount: filteredCandidates.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final conversation = filteredCandidates[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text(
                                    (conversation.name?.isNotEmpty == true
                                            ? conversation.name![0]
                                            : '#')
                                        .toUpperCase(),
                                  ),
                                ),
                                title: Text(
                                  conversation.name ?? '未命名会话',
                                ),
                                subtitle: Text(
                                  conversation.type == 1 ? '单聊' : '群聊',
                                ),
                                trailing: index < 5
                                    ? const Icon(
                                        Icons.history,
                                        size: 18,
                                        color: Color(0xFF2563EB),
                                      )
                                    : null,
                                onTap: () async {
                                  Navigator.pop(context);
                                  await _forwardMessagesToConversation(
                                    messages ?? <MessageDTO>[message],
                                    conversation,
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _forwardMessagesToConversation(
    List<MessageDTO> messages,
    ConversationDTO conversation,
  ) async {
    if (messages.isEmpty || conversation.targetId == null) {
      return;
    }
    var successCount = 0;
    final failedIds = <int>{};
    for (final message in messages) {
      if (message.id == null) {
        continue;
      }
      final success = await context.read<MessageProvider>().forwardMessage(
            originalMsgId: message.id!,
            toUserId: conversation.type == 1 ? conversation.targetId : null,
            groupId: conversation.type == 1 ? null : conversation.targetId,
          );
      if (success) {
        successCount++;
      } else {
        failedIds.add(message.id!);
      }
    }
    if (!mounted) {
      return;
    }
    if (_selectionMode) {
      setState(() {
        if (successCount == messages.length) {
          _selectedMessageIds.clear();
        } else if (failedIds.isNotEmpty) {
          _selectedMessageIds
            ..clear()
            ..addAll(failedIds);
        }
      });
    }
    final summary = successCount == messages.length
        ? (messages.length > 1
            ? '已成功转发 ${messages.length} 条消息。'
            : '消息已成功转发。')
        : successCount > 0
            ? '共转发成功 $successCount / ${messages.length} 条，失败的消息已保留，方便继续处理。'
            : '没有消息转发成功。';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(summary)),
    );
    await _showBatchOperationSummary(
      title: '转发结果',
      summary: summary,
    );
  }

  Future<void> _removeSelectedMessagesLocal() async {
    if (_selectedMessageIds.isEmpty) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('移除已选消息'),
        content: const Text(
          '这只会把已选消息从当前页面移除，不会删除服务器上的历史消息。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('移除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    final removedCount = _selectedMessageIds.length;
    await _removeMessagesFromCurrentView(
      _selectedMessages,
      title: '移除结果',
      successMessage:
          '已从当前视图移除 $removedCount 条消息。',
      trailingNote:
          '这只清理了当前页面视图，不会删除服务器上的历史消息。',
      clearSelectionAfter: true,
    );
  }

  void _showMessageActions(MessageDTO message, bool isCurrentUser) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply_outlined),
              title: const Text('回复'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _replyingTo = message;
                  _editingMessage = null;
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.forward_outlined),
              title: const Text('转发'),
              onTap: () {
                Navigator.pop(context);
                _showForwardTargets(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.checklist_outlined),
              title: const Text('多选'),
              onTap: () {
                Navigator.pop(context);
                _toggleMessageSelection(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_copy_outlined),
              title: const Text('复制'),
              onTap: () {
                Navigator.pop(context);
                if ((message.content ?? '').isNotEmpty) {
                  Clipboard.setData(ClipboardData(text: message.content!));
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('消息已复制')),
                  );
                }
              },
            ),
            if (isCurrentUser &&
                (message.msgType ?? 1) == 1 &&
                message.isRecalled != true)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('编辑'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _editingMessage = message;
                    _replyingTo = null;
                    _messageController.text =
                        EmojiList.replacePlaceholders(message.content ?? '');
                    _messageController.selection = TextSelection.collapsed(
                      offset: _messageController.text.length,
                    );
                    _isTyping = _messageController.text.isNotEmpty;
                  });
                },
              ),
            if (isCurrentUser && message.isRecalled != true)
              ListTile(
                leading: const Icon(Icons.undo_outlined),
                title: const Text('撤回'),
                onTap: () {
                  Navigator.pop(context);
                  _recallMessage(message);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposerBanner() {
    final target = _editingMessage ?? _replyingTo;
    if (target == null) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFF8FAFC),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _editingMessage != null ? '编辑消息' : '回复消息',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _summary(target),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
              setState(() {
                _replyingTo = null;
                _editingMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(
    MessageDTO message,
    bool isCurrentUser, {
    bool isHighlighted = false,
  }) {
    final textColor = isHighlighted
        ? const Color(0xFF333333)
        : (isCurrentUser ? Colors.white : const Color(0xFF333333));

    if (message.isRecalled == true) {
      return Text(
        '消息已撤回',
        style: TextStyle(
          color: isHighlighted
              ? const Color(0xFF666666)
              : (isCurrentUser ? Colors.white70 : const Color(0xFF666666)),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    switch (message.msgType ?? 1) {
      case 2:
        final path = message.content ?? '';
        final file = File(path);
        return GestureDetector(
          onTap: () => _openMediaPreview(message),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: path.startsWith('http')
                ? Image.network(
                    path,
                    width: 180,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _buildMediaPlaceholder(180, 180),
                  )
                : file.existsSync()
                    ? Image.file(
                        file,
                        width: 180,
                        height: 180,
                        fit: BoxFit.cover,
                      )
                    : _buildMediaPlaceholder(180, 180),
          ),
        );
      case 4:
        return GestureDetector(
          onTap: () => _openMediaPreview(message),
          child:
              _buildMediaPlaceholder(180, 140, icon: Icons.play_circle_fill),
        );
      case 3:
        return GestureDetector(
          onTap: () => _openMediaDetails(message),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? const Color(0xFFFFFBEB)
                  : isCurrentUser
                      ? Colors.white24
                      : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.graphic_eq_outlined,
                  color: textColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '音频消息',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      default:
        return Text(
          EmojiList.replacePlaceholders(message.content ?? ''),
          style: TextStyle(
            color: textColor,
            fontSize: 16,
          ),
        );
    }
  }

  Widget _buildMediaPlaceholder(double width, double height, {IconData? icon}) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFE5E7EB),
      child: Icon(
        icon ?? Icons.image_outlined,
        color: const Color(0xFF9CA3AF),
        size: 36,
      ),
    );
  }

  Widget _buildSearchStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF374151),
          ),
          children: [
            TextSpan(text: '$label '),
            TextSpan(
              text: value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    MessageDTO message,
    bool isCurrentUser,
    List<MessageDTO> allMessages,
  ) {
    final replyTarget = _findReplyTarget(message.replyToMsgId, allMessages);
    final isHighlighted = _highlightedMessageId == message.id;
    final isSelected =
        message.id != null && _selectedMessageIds.contains(message.id);
    final secondaryTextColor = isHighlighted
        ? const Color(0xFF666666)
        : (isCurrentUser ? Colors.white70 : const Color(0xFF666666));
    final statusText = message.isRecalled == true
        ? ''
        : isCurrentUser
            ? ((message.isRead == true)
                ? '已读'
                : ((message.status ?? 1) == 0 ? '发送中' : '已发送'))
            : '';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (_selectionMode)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleMessageSelection(message),
              ),
            ),
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageActions(message, isCurrentUser),
              onTap: _selectionMode ? () => _toggleMessageSelection(message) : null,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? const Color(0xFFFFF3C4)
                      : isSelected
                          ? const Color(0xFFDBEAFE)
                      : (isCurrentUser
                          ? Theme.of(context).primaryColor
                          : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  border: isHighlighted
                      ? Border.all(color: const Color(0xFFF59E0B), width: 1.5)
                      : (isSelected
                          ? Border.all(color: const Color(0xFF2563EB), width: 1.5)
                          : null),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.forwardFromMsgId != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isHighlighted
                              ? const Color(0xFFFFFBEB)
                              : isCurrentUser
                                  ? Colors.white24
                                  : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '转发消息',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (replyTarget != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isHighlighted
                              ? const Color(0xFFFFFBEB)
                              : isCurrentUser
                              ? Colors.white24
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _summary(replyTarget),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    _buildMessageContent(
                      message,
                      isCurrentUser,
                      isHighlighted: isHighlighted,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        message.createdAt ?? '',
                        if (message.isEdited == true) '已编辑',
                        if (statusText.isNotEmpty) statusText,
                      ].where((item) => item.isNotEmpty).join(' · '),
                      style: TextStyle(
                        color: isHighlighted
                            ? const Color(0xFF666666)
                            : (isCurrentUser
                                ? Colors.white70
                                : const Color(0xFF9E9E9E)),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(
    List<MessageDTO> messages,
    int index,
    int? currentUserId,
  ) {
    final message = messages[index];
    final previous = index > 0 ? messages[index - 1] : null;
    final showDateDivider =
        previous == null || _dateBucket(previous) != _dateBucket(message);

    return Column(
      children: [
        if (showDateDivider)
          _buildDateDivider(
            _dateLabel(message),
            bucket: _dateBucket(message),
          ),
        _buildMessageBubble(
          message,
          message.fromUserId == currentUserId,
          messages,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final messageProvider = context.watch<MessageProvider>();
    final authProvider = context.watch<AuthProvider>();
    final blacklistProvider = context.watch<BlacklistProvider>();
    final currentUserId = authProvider.user?.id;
    final isBlocked =
        _type == 1 && _targetId != null && blacklistProvider.isBlocked(_targetId!);

    return Scaffold(
      appBar: AppBar(
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _requestClearSelection,
              )
            : null,
        title: _selectionMode
            ? Text('已选择 ${_selectedMessageIds.length} 条')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_title),
                  if (_type == 1)
                    Text(
                      _statusText ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9E9E9E),
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                ],
              ),
        actions: [
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _selectedMessages.isEmpty ? null : _showSelectionOverview,
            ),
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.select_all_outlined),
              onPressed: _selectAllMessages,
            ),
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.flip_outlined),
              onPressed: _invertSelectedMessages,
            ),
          if (_selectionMode)
            PopupMenuButton<int>(
              tooltip: '按类型选择',
              icon: const Icon(Icons.filter_list_outlined),
              onSelected: _selectMessagesByType,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 1,
                  child: Text('选择文本'),
                ),
                PopupMenuItem(
                  value: 2,
                  child: Text('选择图片'),
                ),
                PopupMenuItem(
                  value: 3,
                  child: Text('选择音频'),
                ),
                PopupMenuItem(
                  value: 4,
                  child: Text('选择视频'),
                ),
              ],
            ),
          if (_selectionMode)
            PopupMenuButton<bool>(
              tooltip: '按发送方选择',
              icon: const Icon(Icons.person_search_outlined),
              onSelected: _selectMessagesBySender,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: true,
                  child: Text('选择我发的'),
                ),
                PopupMenuItem(
                  value: false,
                  child: Text('选择对方发送'),
                ),
              ],
            ),
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.forward_outlined),
              onPressed: _selectedMessages.isEmpty
                  ? null
                  : () => _showForwardTargets(
                        _selectedMessages.first,
                        messages: _selectedMessages,
                      ),
            ),
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.my_location_outlined),
              onPressed:
                  _selectedMessages.isEmpty ? null : _focusFirstSelectedMessage,
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _showSearchDialog,
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _type == 1 ? _openUserDetail : null,
            ),
          ],
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _selectedMessageIds.isEmpty
                  ? null
                  : _removeSelectedMessagesLocal,
            ),
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.content_copy_outlined),
              onPressed: _selectedMessages.isEmpty
                  ? null
                  : _copySelectedMessagesSummary,
            ),
        ],
      ),
      body: Column(
        children: [
          if (_selectionMode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFEFF6FF),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '已选择 ${_selectedMessageIds.length} 条',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectionSummaryText(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: messageProvider.isLoading && messageProvider.messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : messageProvider.messages.isEmpty
                    ? const Center(child: Text('暂无消息'))
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: Align(
                              alignment: Alignment.center,
                              child: _loadingHistory
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                  : (_hasMoreHistory
                                      ? TextButton.icon(
                                          onPressed: () => _loadHistoryPage(
                                            page: _currentPage + 1,
                                          ),
                                          icon: const Icon(Icons.history),
                                          label: const Text('加载更早消息'),
                                        )
                                      : const Text(
                                          '历史消息已全部加载',
                                          style: TextStyle(
                                            color: Color(0xFF9E9E9E),
                                            fontSize: 12,
                                          ),
                                        )),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: messageProvider.messages.length,
                              itemBuilder: (context, index) {
                                return _buildMessageItem(
                                  messageProvider.messages,
                                  index,
                                  currentUserId,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
          ),
          if (_showEmojiPicker && !_selectionMode)
            SizedBox(
              height: 180,
              child: GridView.count(
                crossAxisCount: 8,
                children: EmojiList.emojis
                    .map(
                      (emoji) => InkWell(
                        onTap: () {
                          _messageController.text += emoji.code;
                          setState(() {
                            _isTyping = _messageController.text.isNotEmpty;
                          });
                        },
                        child: Center(child: Text(emoji.display)),
                      ),
                    )
                    .toList(),
              ),
            ),
          if (isBlocked && !_selectionMode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: const Color(0xFFFFF3E0),
              child: const Text('由于你已拉黑该用户，当前无法发送消息。'),
            ),
          if (!_selectionMode) _buildComposerBanner(),
          if (!_selectionMode)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: isBlocked ? null : _showMediaOptions,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !isBlocked,
                      decoration: InputDecoration(
                        hintText: _editingMessage != null ? '编辑消息' : '输入消息',
                      ),
                      onChanged: (value) {
                        _cacheDraft(value);
                        setState(() {
                          _isTyping = value.isNotEmpty;
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.sentiment_satisfied_alt),
                    onPressed: isBlocked
                        ? null
                        : () {
                            setState(() {
                              _showEmojiPicker = !_showEmojiPicker;
                            });
                          },
                  ),
                  IconButton(
                    icon: Icon(_editingMessage != null ? Icons.check : Icons.send),
                    onPressed: !isBlocked && _isTyping ? _sendMessage : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}







