import 'package:hailiao_flutter_v2/domain_v2/entities/chat_message.dart';
import 'package:hailiao_flutter_v2/domain_v2/entities/message_send_state.dart';

enum WukongImEventType {
  incoming,
  refresh,
  connection,
}

class WukongImEvent {
  const WukongImEvent._({
    required this.type,
    this.message,
    this.sendState,
    this.connectionStatus,
    this.connectionReason,
  });

  const WukongImEvent.incoming(ChatMessage message)
    : this._(
        type: WukongImEventType.incoming,
        message: message,
      );

  const WukongImEvent.refresh({
    required ChatMessage message,
    required MessageSendState sendState,
  }) : this._(
         type: WukongImEventType.refresh,
         message: message,
         sendState: sendState,
       );

  const WukongImEvent.connection({
    required int status,
    int? reason,
  }) : this._(
         type: WukongImEventType.connection,
         connectionStatus: status,
         connectionReason: reason,
       );

  final WukongImEventType type;
  final ChatMessage? message;
  final MessageSendState? sendState;
  final int? connectionStatus;
  final int? connectionReason;
}
