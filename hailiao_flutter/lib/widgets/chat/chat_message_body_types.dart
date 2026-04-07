/// 与后端 [MessageDTO.msgType] 对齐的**展示层**类型常量。
///
/// 只放 int 常量：不写 UI、不写 [MessageDTO] 派生逻辑。消息类型判断请用 [MessageDTOChatDisplay.safeBodyType] 配合此处常量。
abstract final class ChatMessageBodyTypes {
  ChatMessageBodyTypes._();

  static const int text = 1;
  static const int image = 2;
  static const int audio = 3;
  static const int video = 4;
  static const int file = 5;
}
