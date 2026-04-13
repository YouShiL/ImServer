import 'package:hailiao_flutter_v2/domain_v2/entities/conversation_summary.dart';
import 'package:hailiao_flutter_v2/domain_v2/repositories/conversation_repository.dart';

class LoadConversationsUseCase {
  const LoadConversationsUseCase(this._repository);

  final ConversationRepository _repository;

  Future<List<ConversationSummary>> call() {
    return _repository.loadConversations();
  }
}
