// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FriendDTO _$FriendDTOFromJson(Map<String, dynamic> json) => FriendDTO(
  id: (json['id'] as num?)?.toInt(),
  userId: (json['userId'] as num?)?.toInt(),
  friendId: (json['friendId'] as num?)?.toInt(),
  remark: json['remark'] as String?,
  groupName: json['groupName'] as String?,
  status: (json['status'] as num?)?.toInt(),
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
  friendUserInfo: json['friendUserInfo'] == null
      ? null
      : UserDTO.fromJson(json['friendUserInfo'] as Map<String, dynamic>),
);

Map<String, dynamic> _$FriendDTOToJson(FriendDTO instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'friendId': instance.friendId,
  'remark': instance.remark,
  'groupName': instance.groupName,
  'status': instance.status,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
  'friendUserInfo': instance.friendUserInfo,
};
