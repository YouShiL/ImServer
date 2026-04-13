import 'package:hailiao_flutter_v2/domain_v2/repositories/chat_repository.dart';
import 'package:hailiao_flutter_v2/domain_v2/services/im_send_args_log.dart';

class SendTextMessageUseCase {
  const SendTextMessageUseCase(this._repository);

  final ChatRepository _repository;

  Future<void> call({
    required int targetId,
    required int type,
    required int senderId,
    required String text,
    String? clientId,
  }) {
    imSendArgsLog('use_case_sendText', <String, Object?>{
      'inputTargetId': targetId.toString(),
      'inputType': type.toString(),
      'resolvedChannelId': targetId.toString(),
      'resolvedChannelType': type == 2 ? '2' : '1',
      'selfUserId': senderId.toString(),
      'clientId': clientId ?? '-',
      'clientMsgNO': '-',
      'textPreview': imSendTextPreview(text),
    });
    return _repository.sendText(
      targetId: targetId,
      type: type,
      senderId: senderId,
      text: text,
      clientId: clientId,
    );
  }

  Future<void> sendImage({
    required int targetId,
    required int type,
    required int senderId,
    required String imageUrl,
    String? clientId,
    int? imageWidth,
    int? imageHeight,
  }) {
    imSendArgsLog('use_case_sendImage', <String, Object?>{
      'inputTargetId': targetId.toString(),
      'inputType': type.toString(),
      'resolvedChannelId': targetId.toString(),
      'resolvedChannelType': type == 2 ? '2' : '1',
      'selfUserId': senderId.toString(),
      'clientId': clientId ?? '-',
      'clientMsgNO': '-',
      'textPreview': imageUrl.length > 80 ? '${imageUrl.substring(0, 80)}…' : imageUrl,
    });
    return _repository.sendImage(
      targetId: targetId,
      type: type,
      senderId: senderId,
      imageUrl: imageUrl,
      clientId: clientId,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
  }
}
