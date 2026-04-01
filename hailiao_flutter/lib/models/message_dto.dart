import 'package:json_annotation/json_annotation.dart';
import 'user_dto.dart';

part 'message_dto.g.dart';

@JsonSerializable()
class MessageDTO {
  @JsonKey(name: 'id')
  final int? id;

  @JsonKey(name: 'msgId')
  final String? msgId;

  @JsonKey(name: 'fromUserId')
  final int? fromUserId;

  @JsonKey(name: 'toUserId')
  final int? toUserId;

  @JsonKey(name: 'groupId')
  final int? groupId;

  @JsonKey(name: 'content')
  String? content;

  @JsonKey(name: 'msgType')
  final int? msgType;

  @JsonKey(name: 'subType')
  final int? subType;

  @JsonKey(name: 'extra')
  final String? extra;

  @JsonKey(name: 'isRead')
  final bool? isRead;

  @JsonKey(name: 'isRecalled')
  bool? isRecalled;

  @JsonKey(name: 'isDeleted')
  final bool? isDeleted;

  @JsonKey(name: 'replyToMsgId')
  final int? replyToMsgId;

  @JsonKey(name: 'forwardFromMsgId')
  final int? forwardFromMsgId;

  @JsonKey(name: 'forwardFromUserId')
  final int? forwardFromUserId;

  @JsonKey(name: 'isEdited')
  bool? isEdited;

  @JsonKey(name: 'status')
  final int? status;

  @JsonKey(name: 'createdAt')
  final String? createdAt;

  @JsonKey(name: 'fromUserInfo')
  final UserDTO? fromUserInfo;

  MessageDTO({
    this.id,
    this.msgId,
    this.fromUserId,
    this.toUserId,
    this.groupId,
    this.content,
    this.msgType,
    this.subType,
    this.extra,
    this.isRead,
    this.isRecalled,
    this.isDeleted,
    this.replyToMsgId,
    this.forwardFromMsgId,
    this.forwardFromUserId,
    this.isEdited,
    this.status,
    this.createdAt,
    this.fromUserInfo,
  });

  MessageDTO copyWith({
    String? content,
    bool? isRecalled,
    bool? isEdited,
  }) {
    return MessageDTO(
      id: id,
      msgId: msgId,
      fromUserId: fromUserId,
      toUserId: toUserId,
      groupId: groupId,
      content: content ?? this.content,
      msgType: msgType,
      subType: subType,
      extra: extra,
      isRead: isRead,
      isRecalled: isRecalled ?? this.isRecalled,
      isDeleted: isDeleted,
      replyToMsgId: replyToMsgId,
      forwardFromMsgId: forwardFromMsgId,
      forwardFromUserId: forwardFromUserId,
      isEdited: isEdited ?? this.isEdited,
      status: status,
      createdAt: createdAt,
      fromUserInfo: fromUserInfo,
    );
  }

  factory MessageDTO.fromJson(Map<String, dynamic> json) =>
      _$MessageDTOFromJson(json);

  Map<String, dynamic> toJson() => _$MessageDTOToJson(this);
}
