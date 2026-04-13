import 'package:flutter/foundation.dart';
import 'package:hailiao_flutter/models/user_notification_dto.dart';
import 'package:hailiao_flutter/services/api_service.dart';
import 'package:hailiao_flutter_v2/domain_v2/social/social_notification_copy.dart';

/// 仅负责 **social 域** 通知列表与待处理数，不替代 [FriendProvider]/[GroupProvider] 业务状态。
class SocialNotificationProvider extends ChangeNotifier {
  List<UserNotificationDTO> _items = <UserNotificationDTO>[];
  bool _loading = false;
  String? _error;

  /// 预留：与 [pendingCount] 对齐的本地增量（当前未参与计算）。
  // ignore: unused_field, prefer_final_fields
  int _pendingCount = 0;

  /// 最近一次成功拉取的 **服务端** 待处理数；`null` 表示尚未成功或上次失败，[pendingCount] 走 [_localPendingFallback]。
  int? _pendingCountFromServer;

  List<UserNotificationDTO> get items => _items;
  bool get isLoading => _loading;
  String? get error => _error;

  int _localPendingFallback() => _items.where((UserNotificationDTO x) {
        final String? s = x.status;
        return (s == 'unread' || s == 'read') &&
            SocialNotificationCopy.pendingEntryTypes.contains(x.type);
      }).length;

  /// 「新的朋友」角标：优先 **GET /notifications/pending-count**；仅当请求失败时退回首屏列表推算（不与服务端值混加）。
  int get pendingCount => _pendingCountFromServer ?? _localPendingFallback();

  /// 拉取服务端待处理数（与列表独立，不受分页限制）。
  Future<void> loadPendingCount() async {
    try {
      final response = await ApiService.getNotificationPendingCount(domain: 'social');
      if (response.isSuccess && response.data != null) {
        _pendingCountFromServer = response.data;
      } else {
        _pendingCountFromServer = null;
      }
      notifyListeners();
    } catch (_) {
      _pendingCountFromServer = null;
      notifyListeners();
    }
  }

  Future<void> loadFirstPage() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await ApiService.getNotifications(domain: 'social', page: 0, size: 50);
      if (response.isSuccess && response.data != null) {
        _items = response.data!.content;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = '加载失败';
    } finally {
      _loading = false;
      notifyListeners();
    }
    await loadPendingCount();
  }

  /// 标记已读：以服务端列表为准；结果类若仍落在 `read`（旧接口/缓存），本地补为 `handled`，避免长期卡在 read。
  Future<void> markRead(int id) async {
    final int idx = _items.indexWhere((UserNotificationDTO e) => e.id == id);
    if (idx < 0) {
      return;
    }
    final String? typeBefore = _items[idx].type;
    final response = await ApiService.markNotificationRead(id);
    if (!response.isSuccess) {
      return;
    }
    await loadFirstPage();
    if (_patchOutcomeReadToHandledIfNeeded(id, typeBefore)) {
      await loadPendingCount();
    }
  }

  /// 若将结果类从 `read` 补成 `handled` 返回 `true`。
  bool _patchOutcomeReadToHandledIfNeeded(int id, String? type) {
    if (type == null || !SocialNotificationCopy.outcomeTypes.contains(type)) {
      return false;
    }
    final int i = _items.indexWhere((UserNotificationDTO e) => e.id == id);
    if (i < 0) {
      return false;
    }
    final UserNotificationDTO n = _items[i];
    if (n.status != 'read') {
      return false;
    }
    _items[i] = UserNotificationDTO(
      id: n.id,
      domain: n.domain,
      type: n.type,
      title: n.title,
      body: n.body,
      bizType: n.bizType,
      bizId: n.bizId,
      payload: n.payload,
      status: 'handled',
      createdAt: n.createdAt,
      updatedAt: n.updatedAt,
    );
    notifyListeners();
    return true;
  }

  Future<void> markAllRead() async {
    final response = await ApiService.markAllNotificationsRead(domain: 'social');
    if (response.isSuccess) {
      await loadFirstPage();
    }
  }

  Future<void> refreshAfterBusinessAction() async {
    await loadFirstPage();
  }
}
