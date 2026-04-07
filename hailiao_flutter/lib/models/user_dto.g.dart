// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserDTO _$UserDTOFromJson(Map<String, dynamic> json) => UserDTO(
  id: (json['id'] as num?)?.toInt(),
  userId: json['userId'] as String?,
  phone: json['phone'] as String?,
  nickname: json['nickname'] as String?,
  avatar: json['avatar'] as String?,
  gender: (json['gender'] as num?)?.toInt(),
  region: json['region'] as String?,
  signature: json['signature'] as String?,
  birthday: json['birthday'] as String?,
  background: json['background'] as String?,
  onlineStatus: (json['onlineStatus'] as num?)?.toInt(),
  isVip: json['isVip'] as bool?,
  isPrettyNumber: json['isPrettyNumber'] as bool?,
  prettyNumber: json['prettyNumber'] as String?,
  friendLimit: (json['friendLimit'] as num?)?.toInt(),
  groupLimit: (json['groupLimit'] as num?)?.toInt(),
  groupMemberLimit: (json['groupMemberLimit'] as num?)?.toInt(),
  deviceLock: json['deviceLock'] as bool?,
  showOnlineStatus: json['showOnlineStatus'] as bool?,
  showLastOnline: json['showLastOnline'] as bool?,
  allowSearchByPhone: json['allowSearchByPhone'] as bool?,
  needFriendVerification: json['needFriendVerification'] as bool?,
  status: (json['status'] as num?)?.toInt(),
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
  lastLoginAt: json['lastLoginAt'] as String?,
  lastLoginIp: json['lastLoginIp'] as String?,
);

Map<String, dynamic> _$UserDTOToJson(UserDTO instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'phone': instance.phone,
  'nickname': instance.nickname,
  'avatar': instance.avatar,
  'gender': instance.gender,
  'region': instance.region,
  'signature': instance.signature,
  'birthday': instance.birthday,
  'background': instance.background,
  'onlineStatus': instance.onlineStatus,
  'isVip': instance.isVip,
  'isPrettyNumber': instance.isPrettyNumber,
  'prettyNumber': instance.prettyNumber,
  'friendLimit': instance.friendLimit,
  'groupLimit': instance.groupLimit,
  'groupMemberLimit': instance.groupMemberLimit,
  'deviceLock': instance.deviceLock,
  'showOnlineStatus': instance.showOnlineStatus,
  'showLastOnline': instance.showLastOnline,
  'allowSearchByPhone': instance.allowSearchByPhone,
  'needFriendVerification': instance.needFriendVerification,
  'status': instance.status,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
  'lastLoginAt': instance.lastLoginAt,
  'lastLoginIp': instance.lastLoginIp,
};
