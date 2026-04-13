import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:hailiao_flutter_v2/adapters/chat_v2_view_models.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';
import 'package:hailiao_flutter_v2/widgets_v2/chat/chat_message_item_v2.dart';

/// 时间正序 [messages]（旧→新），`reverse: false`。
///
/// 滚动策略分流：首屏滚底 / 历史 prepend 锚点锁 / 新消息 nearBottom 才滚底 / 同 id 状态更新不滚。
class ChatMessageListV2 extends StatefulWidget {
  const ChatMessageListV2({
    super.key,
    required this.messages,
    this.onLoadOlder,
    this.hasMoreOlder = true,
    this.isLoadingOlder = false,
    this.firstPaintSnapshotHandoff = false,
  });

  final List<ChatV2MessageViewModel> messages;
  final Future<void> Function()? onLoadOlder;
  final bool hasMoreOlder;
  final bool isLoadingOlder;

  /// 首屏极薄快照：禁止用户滚动，避免首帧与远端 merge 叠加的手感冲突；切换后恢复默认 physics。
  final bool firstPaintSnapshotHandoff;

  @override
  State<ChatMessageListV2> createState() => _ChatMessageListV2State();
}

class _ChatMessageListV2State extends State<ChatMessageListV2> {
  final ScrollController _scrollController = ScrollController();

  static const double _enterTopPx = 80;
  static const double _leaveTopPx = 120;
  static const double _nearBottomThresholdPx = 100;
  static const double _nearBottomRelaxedMultiplier = 2;
  static const double _scrollEpsilonPx = 1.5;

  static const int _anchorLockWindowMs = 300;
  static const int _anchorLockMaxCompensations = 2;
  static const double _anchorLockMinDeltaPx = 2;
  static const double _anchorAccumulatedJumpThresholdPx = 10;

  static const double _viewingHistoryDistanceHighPx = 150;
  static const double _viewingHistoryDistanceLowPx = 80;

  /// 首屏锁：extent 连续若干帧变化小于该值则视为稳定，再释放锁。
  static const double _firstPaintExtentStableEpsilonPx = 0.5;
  static const int _firstPaintStableFramesRequired = 3;

  bool _topIntentArmed = true;
  double _lastPixels = 0;
  bool _olderLoadInFlight = false;
  bool _programmaticScroll = false;

  bool _didInitialScrollToBottom = false;
  bool _isNearBottom = true;
  bool _lastUserScrollDirectionDown = true;
  bool _userViewingHistory = false;

  double _anchorAccumulatedDelta = 0;

  // ignore: unused_field
  String? _lastFirstMessageId;
  // ignore: unused_field
  String? _lastLastMessageId;
  // ignore: unused_field
  double? _lastMaxScrollExtent;
  // ignore: unused_field
  double? _lastKnownOffset;

  double? _anchorOldOffset;
  double? _anchorOldMax;

  bool _anchorLockActive = false;
  DateTime? _anchorLockExpireAt;
  int _anchorLockCompensationsLeft = 0;
  double _anchorLockLastMax = 0;

  bool _initialCompensationDone = false;

  /// 首屏 [initialScrollToBottom] 之后：持续 pin 到最新 max，直到 [maxScrollExtent] 连续稳定再释放。
  bool _lockBottomDuringFirstPaint = false;
  double? _firstPaintLastMaxSample;
  int _firstPaintStableFrameCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onMessagesChanged(null, widget.messages);
    });
  }

  @override
  void didUpdateWidget(ChatMessageListV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isSnapshotHandoffPaintOnly(oldWidget, widget)) {
      if (kDebugMode) {
        debugPrint(
          '[chat.scroll] skipOnMessagesChanged reason=snapshotHandoffPaintOnly',
        );
      }
      return;
    }
    _onMessagesChanged(oldWidget.messages, widget.messages);
  }

  /// snapshot ↔ live 仅切换渲染层（physics / IgnorePointer），消息 id 序列不变。
  /// 若不跳过，会被 [_isStatusOnly] 误判为「仅状态更新」并打出无意义的 statusOnly。
  bool _isSnapshotHandoffPaintOnly(
    ChatMessageListV2 oldWidget,
    ChatMessageListV2 nextWidget,
  ) {
    if (oldWidget.firstPaintSnapshotHandoff ==
        nextWidget.firstPaintSnapshotHandoff) {
      return false;
    }
    if (oldWidget.messages.length != nextWidget.messages.length) {
      return false;
    }
    for (int i = 0; i < oldWidget.messages.length; i++) {
      if (oldWidget.messages[i].id != nextWidget.messages[i].id) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateUserViewingHistory(double distanceToBottom) {
    if (distanceToBottom > _viewingHistoryDistanceHighPx) {
      _userViewingHistory = true;
    } else if (distanceToBottom <= _viewingHistoryDistanceLowPx) {
      _userViewingHistory = false;
    }
  }

  /// 距离底 + 最近滑动方向（缓解键盘/面板导致 extent 跳变误判）。
  bool _computeNearBottom() {
    if (!_scrollController.hasClients) {
      return true;
    }
    if (_userViewingHistory) {
      return false;
    }
    final ScrollPosition pos = _scrollController.position;
    final double distance = pos.maxScrollExtent - pos.pixels;
    if (distance <= _nearBottomThresholdPx) {
      return true;
    }
    final double relaxed = _nearBottomThresholdPx * _nearBottomRelaxedMultiplier;
    if (distance <= relaxed) {
      if (pos.userScrollDirection == ScrollDirection.forward) {
        return true;
      }
      if (_lastUserScrollDirectionDown) {
        return true;
      }
    }
    return false;
  }

  void _updateUserScrollDirection(double p) {
    if (_programmaticScroll) {
      return;
    }
    final double delta = p - _lastPixels;
    if (delta > _scrollEpsilonPx) {
      _lastUserScrollDirectionDown = true;
    } else if (delta < -_scrollEpsilonPx) {
      _lastUserScrollDirectionDown = false;
    }
  }

  void _maybeAnchorLockAsyncCompensation() {
    if (!_didInitialScrollToBottom) {
      return;
    }
    if (!_initialCompensationDone) {
      return;
    }
    if (!_anchorLockActive || _anchorLockExpireAt == null) {
      return;
    }
    if (DateTime.now().isAfter(_anchorLockExpireAt!)) {
      if (kDebugMode) {
        debugPrint('[chat.scroll] anchorLock expired');
      }
      _anchorLockActive = false;
      _anchorAccumulatedDelta = 0;
      return;
    }
    if (_anchorLockCompensationsLeft <= 0) {
      _anchorLockActive = false;
      _anchorAccumulatedDelta = 0;
      return;
    }
    if (!_scrollController.hasClients || _programmaticScroll) {
      return;
    }
    final ScrollPosition pos = _scrollController.position;
    final double newMax = pos.maxScrollExtent;
    final double delta = newMax - _anchorLockLastMax;
    if (delta.isNaN || delta.isInfinite || delta.abs() < _anchorLockMinDeltaPx) {
      return;
    }
    _anchorLockLastMax = newMax;
    _anchorAccumulatedDelta += delta;
    if (_anchorAccumulatedDelta < _anchorAccumulatedJumpThresholdPx) {
      return;
    }
    _anchorLockCompensationsLeft--;
    final double minEx = pos.minScrollExtent;
    final double apply = _anchorAccumulatedDelta;
    _anchorAccumulatedDelta = 0;
    final double target = (pos.pixels + apply).clamp(minEx, newMax);
    debugPrint(
      '[chat.scroll] preserveAnchor asyncCompensation '
      'delta=$apply target=$target left=$_anchorLockCompensationsLeft '
      'until=${_anchorLockExpireAt!.millisecondsSinceEpoch}',
    );
    _runProgrammaticJump(target);
    if (_scrollController.hasClients) {
      _anchorLockLastMax = _scrollController.position.maxScrollExtent;
    }
  }

  /// 首屏专用：extent 未稳定前持续 [jumpTo] 最新底部；连续稳定帧后释放锁（非通用 keepBottom / 非 delta compensate）。
  void _advanceFirstPaintLock(ScrollPosition pos) {
    if (!_lockBottomDuringFirstPaint) {
      return;
    }

    final double newMax = pos.maxScrollExtent;
    final double pixels = pos.pixels;

    if (_firstPaintLastMaxSample != null) {
      final double diff = (newMax - _firstPaintLastMaxSample!).abs();
      if (diff >= _firstPaintExtentStableEpsilonPx) {
        _firstPaintStableFrameCount = 0;
        debugPrint(
          '[chat.scroll] firstPaint extentChanged oldMax=$_firstPaintLastMaxSample newMax=$newMax',
        );
      } else {
        _firstPaintStableFrameCount++;
        debugPrint(
          '[chat.scroll] firstPaint stableFrame count=$_firstPaintStableFrameCount max=$newMax',
        );
      }
    }
    _firstPaintLastMaxSample = newMax;

    final double minEx = pos.minScrollExtent;
    final double target = newMax.clamp(minEx, pos.maxScrollExtent);
    if ((target - pixels).abs() > _firstPaintExtentStableEpsilonPx) {
      debugPrint(
        '[chat.scroll] firstPaint pinToBottom max=$newMax pixels=$pixels',
      );
      _runProgrammaticJump(target);
    }

    if (_firstPaintStableFrameCount >= _firstPaintStableFramesRequired) {
      _lockBottomDuringFirstPaint = false;
      _firstPaintLastMaxSample = null;
      _firstPaintStableFrameCount = 0;
      debugPrint(
        '[chat.scroll] lockBottom released reason=extentStable max=$newMax',
      );
    }
  }

  void _scheduleFirstPaintExtentTick() {
    if (!mounted || !_lockBottomDuringFirstPaint) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      if (!_lockBottomDuringFirstPaint) {
        return;
      }
      _advanceFirstPaintLock(_scrollController.position);
      if (_lockBottomDuringFirstPaint) {
        _scheduleFirstPaintExtentTick();
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final ScrollPosition pos = _scrollController.position;

    if (_lockBottomDuringFirstPaint) {
      // 首屏仅由 [_scheduleFirstPaintExtentTick] 每帧观测 extent / pin，避免与 [_onScroll] 同帧重复推进稳定计数。
      return;
    }

    final double p = pos.pixels;
    final double minEx = pos.minScrollExtent;
    final double maxEx = pos.maxScrollExtent;

    if (kDebugMode) {
      debugPrint(
        '[chat.history.ui] scroll '
        'pixels=${p.toStringAsFixed(1)} min=$minEx max=$maxEx '
        '_topIntentArmed=$_topIntentArmed _olderLoadInFlight=$_olderLoadInFlight '
        'hasMoreOlder=${widget.hasMoreOlder} isLoadingOlder=${widget.isLoadingOlder} '
        'onLoadOlderNull=${widget.onLoadOlder == null} programmatic=$_programmaticScroll '
        'lastPixels=${_lastPixels.toStringAsFixed(1)}',
      );
    }

    if (_programmaticScroll) {
      if (kDebugMode) {
        debugPrint('[chat.history.ui] gate reason=programmaticScroll');
      }
      _lastPixels = p;
      return;
    }

    _updateUserScrollDirection(p);
    _updateUserViewingHistory(maxEx - p);
    _maybeAnchorLockAsyncCompensation();

    _isNearBottom = _computeNearBottom();
    _lastMaxScrollExtent = maxEx;
    _lastKnownOffset = p;

    if (p > _leaveTopPx) {
      _topIntentArmed = true;
    }

    final bool topBandHit = _lastPixels > _enterTopPx && p <= _enterTopPx;

    if (topBandHit) {
      debugPrint(
        '[chat.history.ui] top reached p=$p last=$_lastPixels armed=$_topIntentArmed',
      );
    }

    if (topBandHit) {
      if (widget.onLoadOlder == null) {
        debugPrint('[chat.history.ui] gate reason=noCallback');
      } else if (!widget.hasMoreOlder) {
        debugPrint('[chat.history.ui] gate reason=noMore');
      } else if (widget.isLoadingOlder) {
        debugPrint('[chat.history.ui] gate reason=loading');
      } else if (_olderLoadInFlight) {
        debugPrint('[chat.history.ui] gate reason=inFlight');
      } else if (!_topIntentArmed) {
        debugPrint('[chat.history.ui] gate reason=notArmed');
      }
    }

    if (widget.onLoadOlder != null &&
        widget.hasMoreOlder &&
        _topIntentArmed &&
        !_olderLoadInFlight &&
        !widget.isLoadingOlder &&
        _lastPixels > _enterTopPx &&
        p <= _enterTopPx) {
      _topIntentArmed = false;
      debugPrint('[chat.history.ui] trigger onLoadOlder');
      unawaited(_invokeLoadOlder());
    }

    _lastPixels = p;
  }

  Future<void> _invokeLoadOlder() async {
    final Future<void> Function()? fn = widget.onLoadOlder;
    if (fn == null) {
      return;
    }
    if (_olderLoadInFlight || widget.isLoadingOlder) {
      return;
    }
    _olderLoadInFlight = true;
    try {
      await fn();
    } finally {
      if (mounted) {
        _olderLoadInFlight = false;
      }
    }
  }

  bool _isHistoryPrepend(
    List<ChatV2MessageViewModel> prev,
    List<ChatV2MessageViewModel> next,
  ) {
    if (prev.isEmpty || next.isEmpty) {
      return false;
    }
    if (next.length <= prev.length) {
      return false;
    }
    return prev.first.id != next.first.id && prev.last.id == next.last.id;
  }

  bool _isStatusOnly(
    List<ChatV2MessageViewModel> prev,
    List<ChatV2MessageViewModel> next,
  ) {
    if (prev.length != next.length || prev.isEmpty) {
      return false;
    }
    return prev.first.id == next.first.id && prev.last.id == next.last.id;
  }

  bool _isAppend(
    List<ChatV2MessageViewModel> prev,
    List<ChatV2MessageViewModel> next,
  ) {
    if (prev.isEmpty) {
      return false;
    }
    return prev.last.id != next.last.id;
  }

  void _onMessagesChanged(
    List<ChatV2MessageViewModel>? prev,
    List<ChatV2MessageViewModel> next,
  ) {
    if (next.isEmpty) {
      return;
    }

    if (prev == null || prev.isEmpty) {
      if (!_didInitialScrollToBottom) {
        debugPrint(
          '[chat.scroll] initialScrollToBottom oldCount=${prev?.length ?? 0} newCount=${next.length}',
        );
        _scheduleInitialScrollToBottom();
      }
      _syncLastIds(next);
      return;
    }

    if (_isHistoryPrepend(prev, next)) {
      if (!_initialCompensationDone) {
        if (kDebugMode) {
          debugPrint('[chat.scroll] skipAnchorLock reason=initialPhase');
        }
        _syncLastIds(next);
        if (!_userViewingHistory) {
          _scheduleAppendScrollToBottom();
        }
        return;
      }
      if (_scrollController.hasClients) {
        _anchorOldOffset = _scrollController.position.pixels;
        _anchorOldMax = _scrollController.position.maxScrollExtent;
      } else {
        _anchorOldOffset = null;
        _anchorOldMax = null;
      }
      _schedulePreserveAnchorAfterPrepend();
      _syncLastIds(next);
      return;
    }

    if (_isStatusOnly(prev, next)) {
      debugPrint('[chat.scroll] noAutoScroll reason=statusOnly');
      _syncLastIds(next);
      return;
    }

    if (_isAppend(prev, next)) {
      final bool nearBottom = _computeNearBottom();
      if (nearBottom) {
        debugPrint(
          '[chat.scroll] autoScrollToBottom reason=appendNewMessage '
          'nearBottom=true field_nearBottom=$_isNearBottom scrollDown=$_lastUserScrollDirectionDown',
        );
        _scheduleAppendScrollToBottom();
      } else {
        debugPrint(
          '[chat.scroll] noAutoScroll reason=userAwayFromBottom '
          'field_nearBottom=$_isNearBottom computed=$nearBottom scrollDown=$_lastUserScrollDirectionDown',
        );
      }
      _syncLastIds(next);
      return;
    }

    debugPrint(
      '[chat.scroll] noAutoScroll reason=ambiguousReplace '
      'prevFirst=${prev.first.id} prevLast=${prev.last.id} '
      'nextFirst=${next.first.id} nextLast=${next.last.id}',
    );
    _syncLastIds(next);
  }

  void _syncLastIds(List<ChatV2MessageViewModel> next) {
    if (next.isEmpty) {
      return;
    }
    _lastFirstMessageId = next.first.id;
    _lastLastMessageId = next.last.id;
  }

  void _scheduleInitialScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      if (_didInitialScrollToBottom) {
        return;
      }
      final double max = _scrollController.position.maxScrollExtent;
      _runProgrammaticJump(max, after: () {
        _didInitialScrollToBottom = true;
        _initialCompensationDone = true;
        _lockBottomDuringFirstPaint = true;
        _firstPaintLastMaxSample = null;
        _firstPaintStableFrameCount = 0;
        if (kDebugMode) {
          debugPrint(
            '[chat.scroll] skipInitialCompensation reason=lockFirstPaint',
          );
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_scrollController.hasClients) {
            return;
          }
          _advanceFirstPaintLock(_scrollController.position);
          _scheduleFirstPaintExtentTick();
        });
      });
    });
  }

  void _schedulePreserveAnchorAfterPrepend() {
    if (!_initialCompensationDone) {
      if (kDebugMode) {
        debugPrint('[chat.scroll] skipPreserveAnchor reason=initialPhase');
      }
      return;
    }
    final double? oldOffset = _anchorOldOffset;
    final double? oldMax = _anchorOldMax;
    _anchorOldOffset = null;
    _anchorOldMax = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      if (oldOffset == null || oldMax == null) {
        debugPrint(
          '[chat.scroll] preserveAnchor skipped (no anchor; hasClients=${_scrollController.hasClients})',
        );
        return;
      }
      final double newMax = _scrollController.position.maxScrollExtent;
      double delta = newMax - oldMax;
      if (delta.isNaN || delta.isInfinite || delta < 0) {
        delta = 0;
      }
      final double minEx = _scrollController.position.minScrollExtent;
      final double maxEx = _scrollController.position.maxScrollExtent;
      final double target = (oldOffset + delta).clamp(minEx, maxEx);
      debugPrint(
        '[chat.history.ui] prepend keepAnchor delta=$delta target=$target',
      );
      debugPrint(
        '[chat.scroll] preserveAnchor oldOffset=$oldOffset oldMax=$oldMax newMax=$newMax delta=$delta target=$target',
      );
      _runProgrammaticJump(target);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) {
          return;
        }
        if (!_initialCompensationDone) {
          return;
        }
        _anchorAccumulatedDelta = 0;
        _anchorLockActive = true;
        _anchorLockExpireAt = DateTime.now().add(
          const Duration(milliseconds: _anchorLockWindowMs),
        );
        _anchorLockCompensationsLeft = _anchorLockMaxCompensations;
        _anchorLockLastMax = _scrollController.position.maxScrollExtent;
        debugPrint(
          '[chat.scroll] anchorLock start until=${_anchorLockExpireAt!.millisecondsSinceEpoch} '
          'lastMax=$_anchorLockLastMax',
        );
        _scheduleAnchorLockFollowUpFrames();
      });
    });
  }

  /// 图片/异步布局可能不触发 onScroll，补两帧尝试补偿（仍受次数与窗口限制）。
  void _scheduleAnchorLockFollowUpFrames() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _maybeAnchorLockAsyncCompensation();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _maybeAnchorLockAsyncCompensation();
      });
    });
  }

  void _scheduleAppendScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final double max = _scrollController.position.maxScrollExtent;
      _runProgrammaticJump(max);
    });
  }

  void _runProgrammaticJump(double target, {VoidCallback? after}) {
    _programmaticScroll = true;
    _scrollController.jumpTo(target);
    _lastPixels = target;
    after?.call();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _programmaticScroll = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final int n = widget.messages.length;
    final ScrollPhysics? listPhysics = widget.firstPaintSnapshotHandoff
        ? const NeverScrollableScrollPhysics()
        : null;

    if (n == 0) {
      return ListView(
        controller: _scrollController,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          12,
          12,
          12,
          ChatV2Tokens.listBottomSpacing,
        ),
      );
    }
    return IgnorePointer(
      ignoring: widget.firstPaintSnapshotHandoff,
      child: ListView.separated(
        controller: _scrollController,
        reverse: false,
        physics: listPhysics,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          12,
          12,
          12,
          ChatV2Tokens.listBottomSpacing,
        ),
        itemCount: n,
        separatorBuilder: (_, _) =>
            const SizedBox(height: ChatV2Tokens.messageGap),
        itemBuilder: (BuildContext context, int index) {
          final ChatV2MessageViewModel m = widget.messages[index];
          return ChatMessageItemV2(message: m);
        },
      ),
    );
  }
}
