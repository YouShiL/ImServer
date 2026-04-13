import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hailiao_flutter_v2/domain_v2/entities/conversation_summary.dart';
import 'package:hailiao_flutter_v2/domain_v2/repositories/conversation_repository.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/wukong_im_service.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/wukong_im_event.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/identity_resolver.dart';
import 'package:hailiao_flutter_v2/domain_v2/use_cases/load_conversations_use_case.dart';

class ConversationCoordinator extends ChangeNotifier {
  ConversationCoordinator({
    required LoadConversationsUseCase loadConversationsUseCase,
    required ConversationRepository repository,
    required WukongImService imService,
    required int? currentUserId,
    String? currentUserToken,
    IdentityResolver? identityResolver,
  }) : _loadConversationsUseCase = loadConversationsUseCase,
       _repository = repository,
       _imService = imService,
       _currentUserId = currentUserId,
       _currentUserToken = currentUserToken,
       _identityResolver = identityResolver;

  final LoadConversationsUseCase _loadConversationsUseCase;
  final ConversationRepository _repository;
  final WukongImService _imService;
  final int? _currentUserId;
  final String? _currentUserToken;
  final IdentityResolver? _identityResolver;

  List<ConversationSummary> _allConversations = <ConversationSummary>[];
  StreamSubscription<ConversationSummary>? _previewSubscription;
  StreamSubscription<WukongImEvent>? _realtimeSubscription;
  String _query = '';
  bool _isLoading = false;
  String? _error;

  List<ConversationSummary> get conversations {
    final String keyword = _query.trim().toLowerCase();
    if (keyword.isEmpty) {
      return _allConversations;
    }
    return _allConversations.where((ConversationSummary item) {
      final String resolvedTitle = _identityResolver?.resolveTitle(
            item.targetId,
            item.type,
            serverConversationName: item.serverConversationName,
          ) ??
          item.title;
      return resolvedTitle.toLowerCase().contains(keyword) ||
          item.lastMessage.toLowerCase().contains(keyword);
    }).toList(growable: false);
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get query => _query;

  Future<void> attachPreviewUpdates() async {
    _previewSubscription ??=
        _repository.watchConversationSummaries().listen(_mergeConversation);
    if (_realtimeSubscription == null) {
      _realtimeSubscription =
          _imService.events.listen(_handleRealtimeConversationEvent);
      await _imService.bind(
        currentUserId: _currentUserId,
        authToken: _currentUserToken,
      );
    }
  }

  Future<void> loadConversations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allConversations = await _loadConversationsUseCase();
      _sortConversations();
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _query = query;
    notifyListeners();
  }

  Future<bool> toggleTop(ConversationSummary summary) async {
    return _updateConversation(
      summary,
      isTop: !summary.isTop,
    );
  }

  Future<bool> toggleMute(ConversationSummary summary) async {
    return _updateConversation(
      summary,
      isMuted: !summary.isMuted,
    );
  }

  Future<bool> deleteConversation(ConversationSummary summary) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.deleteConversation(summary.targetId, type: summary.type);
      _allConversations = _allConversations
          .where((item) => item.targetId != summary.targetId || item.type != summary.type)
          .toList(growable: false);
      return true;
    } catch (error) {
      _error = error.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _updateConversation(
    ConversationSummary summary, {
    bool? isTop,
    bool? isMuted,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final ConversationSummary updated = await _repository.updateConversationSetting(
        summary.targetId,
        type: summary.type,
        isTop: isTop,
        isMuted: isMuted,
      );
      _mergeConversation(updated);
      return true;
    } catch (error) {
      _error = error.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleRealtimeConversationEvent(WukongImEvent event) {
    final message = event.message;
    if (message == null) {
      return;
    }
    if (event.type == WukongImEventType.incoming) {
      _repository.upsertPreviewFromMessage(message);
    }
  }

  void _mergeConversation(ConversationSummary updated) {
    final int index = _allConversations.indexWhere(
      (item) => item.targetId == updated.targetId && item.type == updated.type,
    );
    if (index == -1) {
      _allConversations = <ConversationSummary>[..._allConversations, updated];
    } else {
      _allConversations[index] = updated;
    }
    _sortConversations();
    notifyListeners();
  }

  void _sortConversations() {
    _allConversations.sort((a, b) {
      final int topCompare = (b.isTop ? 1 : 0).compareTo(a.isTop ? 1 : 0);
      if (topCompare != 0) {
        return topCompare;
      }
      final int aTime =
          DateTime.tryParse(a.lastMessageTime ?? '')?.millisecondsSinceEpoch ?? 0;
      final int bTime =
          DateTime.tryParse(b.lastMessageTime ?? '')?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });
  }

  @override
  void dispose() {
    _previewSubscription?.cancel();
    _realtimeSubscription?.cancel();
    _imService.unbind();
    super.dispose();
  }
}
