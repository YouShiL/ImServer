// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConversationDTO _$ConversationDTOFromJson(Map<String, dynamic> json) =>
    ConversationDTO(
      id: (json['id'] as num?)?.toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      targetId: (json['targetId'] as num?)?.toInt(),
      type: (json['type'] as num?)?.toInt(),
      name: json['name'] as String?,
      avatar: json['avatar'] as String?,
      lastMessage: json['lastMessage'] as String?,
      lastMessageTime: json['lastMessageTime'] as String?,
      unreadCount: (json['unreadCount'] as num?)?.toInt(),
      isTop: json['isTop'] as bool?,
      isMute: json['isMute'] as bool?,
      draft: json['draft'] as String?,
      isDeleted: json['isDeleted'] as bool?,
    );

Map<String, dynamic> _$ConversationDTOToJson(ConversationDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'targetId': instance.targetId,
      'type': instance.type,
      'name': instance.name,
      'avatar': instance.avatar,
      'lastMessage': instance.lastMessage,
      'lastMessageTime': instance.lastMessageTime,
      'unreadCount': instance.unreadCount,
      'isTop': instance.isTop,
      'isMute': instance.isMute,
      'draft': instance.draft,
      'isDeleted': instance.isDeleted,
    };
