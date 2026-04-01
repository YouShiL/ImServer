import 'package:json_annotation/json_annotation.dart';

part 'conversation_dto.g.dart';

@JsonSerializable()
class ConversationDTO {
  @JsonKey(name: 'id')
  final int? id;

  @JsonKey(name: 'userId')
  final int? userId;

  @JsonKey(name: 'targetId')
  final int? targetId;

  @JsonKey(name: 'type')
  final int? type;

  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'avatar')
  final String? avatar;

  @JsonKey(name: 'lastMessage')
  final String? lastMessage;

  @JsonKey(name: 'lastMessageTime')
  final String? lastMessageTime;

  @JsonKey(name: 'unreadCount')
  final int? unreadCount;

  @JsonKey(name: 'isTop')
  final bool? isTop;

  @JsonKey(name: 'isMute')
  final bool? isMute;

  @JsonKey(name: 'draft')
  final String? draft;

  @JsonKey(name: 'isDeleted')
  final bool? isDeleted;

  ConversationDTO({
    this.id,
    this.userId,
    this.targetId,
    this.type,
    this.name,
    this.avatar,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount,
    this.isTop,
    this.isMute,
    this.draft,
    this.isDeleted,
  });

  factory ConversationDTO.fromJson(Map<String, dynamic> json) =>
      _$ConversationDTOFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationDTOToJson(this);
}
