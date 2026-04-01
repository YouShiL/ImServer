// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blacklist_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BlacklistDTO _$BlacklistDTOFromJson(Map<String, dynamic> json) => BlacklistDTO(
  id: (json['id'] as num?)?.toInt(),
  userId: (json['userId'] as num?)?.toInt(),
  blockedUserId: (json['blockedUserId'] as num?)?.toInt(),
  createdAt: json['createdAt'] as String?,
  blockedUserInfo: json['blockedUserInfo'] == null
      ? null
      : UserDTO.fromJson(json['blockedUserInfo'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BlacklistDTOToJson(BlacklistDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'blockedUserId': instance.blockedUserId,
      'createdAt': instance.createdAt,
      'blockedUserInfo': instance.blockedUserInfo,
    };
