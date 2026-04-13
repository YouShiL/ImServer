import 'package:hailiao_flutter_v2/domain_v2/entities/chat_message.dart';
import 'package:hailiao_flutter_v2/domain_v2/repositories/chat_repository.dart';

class LoadChatMessagesUseCase {
  const LoadChatMessagesUseCase(this._repository);

  final ChatRepository _repository;

  Future<List<ChatMessage>> call({
    required int targetId,
    required int type,
    required int? currentUserId,
    int page = 1,
    int size = 20,
  }) {
    return _repository.loadMessages(
      targetId: targetId,
      type: type,
      currentUserId: currentUserId,
      page: page,
      size: size,
    );
  }
}
