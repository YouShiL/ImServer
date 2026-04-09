// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageDTO _$MessageDTOFromJson(Map<String, dynamic> json) => MessageDTO(
  id: (json['id'] as num?)?.toInt(),
  msgId: json['msgId'] as String?,
  clientMsgNo: json['clientMsgNo'] as String?,
  fromUserId: (json['fromUserId'] as num?)?.toInt(),
  toUserId: (json['toUserId'] as num?)?.toInt(),
  groupId: (json['groupId'] as num?)?.toInt(),
  content: json['content'] as String?,
  msgType: (json['msgType'] as num?)?.toInt(),
  subType: (json['subType'] as num?)?.toInt(),
  extra: json['extra'] as String?,
  isRead: json['isRead'] as bool?,
  isRecalled: json['isRecalled'] as bool?,
  isDeleted: json['isDeleted'] as bool?,
  replyToMsgId: (json['replyToMsgId'] as num?)?.toInt(),
  forwardFromMsgId: (json['forwardFromMsgId'] as num?)?.toInt(),
  forwardFromUserId: (json['forwardFromUserId'] as num?)?.toInt(),
  isEdited: json['isEdited'] as bool?,
  status: (json['status'] as num?)?.toInt(),
  createdAt: json['createdAt'] as String?,
  fromUserInfo: json['fromUserInfo'] == null
      ? null
      : UserDTO.fromJson(json['fromUserInfo'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MessageDTOToJson(MessageDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'msgId': instance.msgId,
      'clientMsgNo': instance.clientMsgNo,
      'fromUserId': instance.fromUserId,
      'toUserId': instance.toUserId,
      'groupId': instance.groupId,
      'content': instance.content,
      'msgType': instance.msgType,
      'subType': instance.subType,
      'extra': instance.extra,
      'isRead': instance.isRead,
      'isRecalled': instance.isRecalled,
      'isDeleted': instance.isDeleted,
      'replyToMsgId': instance.replyToMsgId,
      'forwardFromMsgId': instance.forwardFromMsgId,
      'forwardFromUserId': instance.forwardFromUserId,
      'isEdited': instance.isEdited,
      'status': instance.status,
      'createdAt': instance.createdAt,
      'fromUserInfo': instance.fromUserInfo,
    };
