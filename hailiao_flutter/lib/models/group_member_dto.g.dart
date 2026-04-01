// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_member_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupMemberDTO _$GroupMemberDTOFromJson(Map<String, dynamic> json) =>
    GroupMemberDTO(
      id: (json['id'] as num?)?.toInt(),
      groupId: (json['groupId'] as num?)?.toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      nickname: json['nickname'] as String?,
      role: (json['role'] as num?)?.toInt(),
      isMute: json['isMute'] as bool?,
      joinedAt: json['joinedAt'] as String?,
      userInfo: json['userInfo'] == null
          ? null
          : UserDTO.fromJson(json['userInfo'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GroupMemberDTOToJson(GroupMemberDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'groupId': instance.groupId,
      'userId': instance.userId,
      'nickname': instance.nickname,
      'role': instance.role,
      'isMute': instance.isMute,
      'joinedAt': instance.joinedAt,
      'userInfo': instance.userInfo,
    };
