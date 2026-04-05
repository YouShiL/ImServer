import 'package:flutter/foundation.dart';
import 'package:hailiao_flutter/providers/call_provider.dart';
import 'package:hailiao_flutter/services/call_signal_protocol.dart';

enum CallSignalEventType {
  outgoingStarted,
  outgoingRinging,
  remoteAccepted,
  remoteDeclined,
  remoteEnded,
  localEnded,
  incomingCall,
}

class CallSignalPayload {
  const CallSignalPayload({
    this.callType,
    this.name,
    this.avatarUrl,
    this.subtitle,
  });

  final CallMediaType? callType;
  final String? name;
  final String? avatarUrl;
  final String? subtitle;
}

class CallSignalBridge extends ChangeNotifier {
  CallSignalBridge._();

  static final CallSignalBridge instance = CallSignalBridge._();

  CallProvider? _activeProvider;
  CallSignalPayload? _pendingIncoming;

  CallSignalPayload? get pendingIncoming => _pendingIncoming;
  bool get hasActiveProvider => _activeProvider != null;

  void attachProvider(CallProvider provider) {
    _activeProvider = provider;
  }

  void detachProvider(CallProvider provider) {
    if (identical(_activeProvider, provider)) {
      _activeProvider = null;
    }
  }

  CallSignalPayload? takePendingIncoming() {
    final CallSignalPayload? pending = _pendingIncoming;
    _pendingIncoming = null;
    if (pending != null) {
      notifyListeners();
    }
    return pending;
  }

  bool consumeRawImEvent(Object? rawEvent) {
    final CallSignalEnvelope? envelope = CallSignalProtocol.parse(rawEvent);
    if (envelope == null) {
      return false;
    }
    emit(
      _mapAction(envelope.action),
      payload: CallSignalPayload(
        callType: envelope.mediaType,
        name: envelope.callerName,
        avatarUrl: envelope.avatarUrl,
        subtitle: envelope.subtitle,
      ),
    );
    return true;
  }

  bool emit(
    CallSignalEventType event, {
    CallSignalPayload? payload,
  }) {
    final CallProvider? provider = _activeProvider;
    if (provider == null) {
      if (event == CallSignalEventType.incomingCall && payload != null) {
        _pendingIncoming = payload;
        notifyListeners();
      }
      return false;
    }

    dispatch(provider, event, payload: payload);
    return true;
  }

  void dispatch(
    CallProvider provider,
    CallSignalEventType event, {
    CallSignalPayload? payload,
  }) {
    switch (event) {
      case CallSignalEventType.outgoingStarted:
        onOutgoingStarted(provider);
      case CallSignalEventType.outgoingRinging:
        onOutgoingRinging(provider);
      case CallSignalEventType.remoteAccepted:
        onRemoteAccepted(provider);
      case CallSignalEventType.remoteDeclined:
        onRemoteDeclined(provider);
      case CallSignalEventType.remoteEnded:
        onRemoteEnded(provider);
      case CallSignalEventType.localEnded:
        onLocalEnded(provider);
      case CallSignalEventType.incomingCall:
        onIncomingCall(
          provider,
          callType: payload?.callType ?? provider.callType,
          name: payload?.name ?? provider.name,
          avatarUrl: payload?.avatarUrl ?? provider.avatarUrl,
          subtitle: payload?.subtitle ?? provider.subtitle,
        );
    }
  }

  void onOutgoingStarted(CallProvider provider) {
    provider.startOutgoingCall();
  }

  void onOutgoingRinging(CallProvider provider) {
    provider.markWaiting();
  }

  void onRemoteAccepted(CallProvider provider) {
    provider.acceptCall();
  }

  void onRemoteDeclined(CallProvider provider) {
    provider.declineCall();
  }

  void onRemoteEnded(CallProvider provider) {
    provider.remoteEnded();
  }

  Future<void> onLocalEnded(CallProvider provider) {
    return provider.endCall();
  }

  void onIncomingCall(
    CallProvider provider, {
    required CallMediaType callType,
    required String name,
    String? avatarUrl,
    String? subtitle,
  }) {
    provider.startIncomingCall(
      callType: callType,
      name: name,
      avatarUrl: avatarUrl,
      subtitle: subtitle,
    );
  }

  CallSignalEventType _mapAction(CallSignalAction action) {
    switch (action) {
      case CallSignalAction.outgoingStarted:
        return CallSignalEventType.outgoingStarted;
      case CallSignalAction.ringing:
        return CallSignalEventType.outgoingRinging;
      case CallSignalAction.accept:
        return CallSignalEventType.remoteAccepted;
      case CallSignalAction.decline:
        return CallSignalEventType.remoteDeclined;
      case CallSignalAction.end:
        return CallSignalEventType.remoteEnded;
      case CallSignalAction.localEnd:
        return CallSignalEventType.localEnded;
      case CallSignalAction.invite:
        return CallSignalEventType.incomingCall;
    }
  }
}
