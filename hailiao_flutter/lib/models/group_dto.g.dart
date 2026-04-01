// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupDTO _$GroupDTOFromJson(Map<String, dynamic> json) => GroupDTO(
  id: (json['id'] as num?)?.toInt(),
  groupId: json['groupId'] as String?,
  groupName: json['groupName'] as String?,
  description: json['description'] as String?,
  notice: json['notice'] as String?,
  avatar: json['avatar'] as String?,
  ownerId: (json['ownerId'] as num?)?.toInt(),
  groupType: (json['groupType'] as num?)?.toInt(),
  memberCount: (json['memberCount'] as num?)?.toInt(),
  maxMembers: (json['maxMembers'] as num?)?.toInt(),
  needVerify: json['needVerify'] as bool?,
  allowMemberInvite: json['allowMemberInvite'] as bool?,
  joinType: (json['joinType'] as num?)?.toInt(),
  isMute: json['isMute'] as bool?,
  status: (json['status'] as num?)?.toInt(),
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
);

Map<String, dynamic> _$GroupDTOToJson(GroupDTO instance) => <String, dynamic>{
  'id': instance.id,
  'groupId': instance.groupId,
  'groupName': instance.groupName,
  'description': instance.description,
  'notice': instance.notice,
  'avatar': instance.avatar,
  'ownerId': instance.ownerId,
  'groupType': instance.groupType,
  'memberCount': instance.memberCount,
  'maxMembers': instance.maxMembers,
  'needVerify': instance.needVerify,
  'allowMemberInvite': instance.allowMemberInvite,
  'joinType': instance.joinType,
  'isMute': instance.isMute,
  'status': instance.status,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};
