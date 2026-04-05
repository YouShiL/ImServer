import 'dart:convert';

import 'package:hailiao_flutter/providers/call_provider.dart';
import 'package:wukongimfluttersdk/entity/msg.dart';
import 'package:wukongimfluttersdk/model/wk_text_content.dart';

/// Front-end recommended minimal call signaling protocol:
/// {
///   "type": "call_signal",
///   "action": "invite|ringing|accept|decline|end",
///   "mediaType": "audio|video",
///   "callId": "optional-call-id",
///   "callerId": "optional-user-id",
///   "calleeId": "optional-user-id",
///   "callerName": "optional-display-name",
///   "avatarUrl": "optional-avatar",
///   "subtitle": "optional-helper-text",
///   "timestamp": 1710000000
/// }
///
/// Compatibility aliases currently accepted:
/// - top-level type: `bizType = "call"`
/// - action aliases: `callAction`, `cmd`, `event`
/// - media aliases: `callType`
/// - identity aliases: `name`, `title`, `avatar`
/// - action aliases:
///   - invite / call_invite / incoming_call
///   - ringing / outgoing_ringing / call_ringing
///   - accept / call_accept / remote_accepted / accepted / answer
///   - decline / call_decline / remote_declined / declined / rejected / reject
///   - end / call_end / remote_ended / ended / hangup
class CallSignalProtocol {
  CallSignalProtocol._();

  static const String typeField = 'type';
  static const String bizTypeField = 'bizType';
  static const String payloadField = 'payload';
  static const String actionField = 'action';
  static const String mediaTypeField = 'mediaType';
  static const String callIdField = 'callId';
  static const String callerIdField = 'callerId';
  static const String calleeIdField = 'calleeId';
  static const String callerNameField = 'callerName';
  static const String calleeNameField = 'calleeName';
  static const String avatarUrlField = 'avatarUrl';
  static const String subtitleField = 'subtitle';
  static const String timestampField = 'timestamp';

  static const List<String> actionAliases = <String>[
    actionField,
    'callAction',
    'cmd',
    'event',
  ];

  static const List<String> mediaAliases = <String>[
    mediaTypeField,
    'callType',
  ];

  static const List<String> nameAliases = <String>[
    callerNameField,
    'name',
    'title',
  ];

  static const List<String> avatarAliases = <String>[
    avatarUrlField,
    'avatar',
  ];

  static const List<String> subtitleAliases = <String>[
    subtitleField,
    'statusText',
  ];

  static CallSignalEnvelope? parse(Object? rawEvent) {
    final Map<String, dynamic>? signal = _extractSignalMap(rawEvent);
    if (signal == null) {
      return null;
    }

    final Map<String, dynamic> payload = _extractPayload(signal);
    final String? action = _readFirstString(signal, actionAliases) ??
        _readFirstString(payload, actionAliases);
    if (action == null || action.isEmpty) {
      return null;
    }

    final CallSignalAction? normalizedAction = _parseAction(action);
    if (normalizedAction == null) {
      return null;
    }

    final CallMediaType? mediaType =
        _parseCallType(_readFirstString(payload, mediaAliases) ??
            _readFirstString(signal, mediaAliases));

    return CallSignalEnvelope(
      action: normalizedAction,
      mediaType: mediaType,
      callId: _readFirstString(payload, <String>[callIdField]) ??
          _readFirstString(signal, <String>[callIdField]),
      callerName: _readFirstString(payload, nameAliases) ??
          _readFirstString(signal, nameAliases),
      avatarUrl: _readFirstString(payload, avatarAliases) ??
          _readFirstString(signal, avatarAliases),
      subtitle: _readFirstString(payload, subtitleAliases) ??
          _readFirstString(signal, subtitleAliases),
      rawPayload: signal,
    );
  }

  static Map<String, dynamic>? _extractSignalMap(Object? rawEvent) {
    if (rawEvent is Map<String, dynamic>) {
      return _looksLikeCallSignal(rawEvent) ? rawEvent : null;
    }
    if (rawEvent is WKMsg) {
      final String? rawText = _extractMessageText(rawEvent);
      if (rawText == null || rawText.trim().isEmpty) {
        return null;
      }
      final Object? decoded = _tryDecodeJson(rawText);
      if (decoded is Map<String, dynamic> && _looksLikeCallSignal(decoded)) {
        return decoded;
      }
      return null;
    }
    if (rawEvent is String) {
      final Object? decoded = _tryDecodeJson(rawEvent);
      if (decoded is Map<String, dynamic> && _looksLikeCallSignal(decoded)) {
        return decoded;
      }
    }
    return null;
  }

  static Map<String, dynamic> _extractPayload(Map<String, dynamic> data) {
    final Object? payload = data[payloadField];
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    return data;
  }

  static bool _looksLikeCallSignal(Map<String, dynamic> data) {
    final String? type = _readFirstString(data, <String>[typeField, bizTypeField]);
    if (type == 'call_signal' || type == 'call') {
      return true;
    }

    final Object? payload = data[payloadField];
    final bool hasAction = _readFirstString(data, actionAliases) != null ||
        (payload is Map<String, dynamic> &&
            _readFirstString(payload, actionAliases) != null);
    final bool hasMedia = _readFirstString(data, mediaAliases) != null ||
        (payload is Map<String, dynamic> &&
            _readFirstString(payload, mediaAliases) != null);
    return hasAction || hasMedia;
  }

  static String? _extractMessageText(WKMsg msg) {
    final messageContent = msg.messageContent;
    if (messageContent is WKTextContent && messageContent.content.isNotEmpty) {
      return messageContent.content;
    }
    final String? displayText = messageContent?.displayText();
    if (displayText != null && displayText.isNotEmpty) {
      return displayText;
    }
    final Object raw = msg.content;
    final String text = raw.toString();
    return text.isEmpty ? null : text;
  }

  static Object? _tryDecodeJson(String source) {
    final String trimmed = source.trim();
    if (!trimmed.startsWith('{') || !trimmed.endsWith('}')) {
      return null;
    }
    try {
      return jsonDecode(trimmed);
    } catch (_) {
      return null;
    }
  }

  static String? _readFirstString(
    Map<String, dynamic> data,
    List<String> fields,
  ) {
    for (final String field in fields) {
      final String value = data[field]?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  static CallSignalAction? _parseAction(String raw) {
    final String action = raw.trim().toLowerCase();
    switch (action) {
      case 'invite':
      case 'call_invite':
      case 'incoming_call':
        return CallSignalAction.invite;
      case 'ringing':
      case 'outgoing_ringing':
      case 'call_ringing':
        return CallSignalAction.ringing;
      case 'accept':
      case 'call_accept':
      case 'remote_accepted':
      case 'accepted':
      case 'answer':
        return CallSignalAction.accept;
      case 'decline':
      case 'call_decline':
      case 'remote_declined':
      case 'declined':
      case 'rejected':
      case 'reject':
        return CallSignalAction.decline;
      case 'end':
      case 'call_end':
      case 'remote_ended':
      case 'ended':
      case 'hangup':
        return CallSignalAction.end;
      case 'outgoing_started':
      case 'call_start':
      case 'call_started':
        return CallSignalAction.outgoingStarted;
      case 'local_end':
      case 'cancel':
      case 'cancelled':
        return CallSignalAction.localEnd;
      default:
        return null;
    }
  }

  static CallMediaType? _parseCallType(String? raw) {
    final String text = raw?.trim().toLowerCase() ?? '';
    switch (text) {
      case 'audio':
      case 'voice':
        return CallMediaType.audio;
      case 'video':
        return CallMediaType.video;
      default:
        return null;
    }
  }
}

enum CallSignalAction {
  outgoingStarted,
  invite,
  ringing,
  accept,
  decline,
  end,
  localEnd,
}

class CallSignalEnvelope {
  const CallSignalEnvelope({
    required this.action,
    this.mediaType,
    this.callId,
    this.callerName,
    this.avatarUrl,
    this.subtitle,
    this.rawPayload,
  });

  final CallSignalAction action;
  final CallMediaType? mediaType;
  final String? callId;
  final String? callerName;
  final String? avatarUrl;
  final String? subtitle;
  final Map<String, dynamic>? rawPayload;
}
