// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_session_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserSessionDTO _$UserSessionDTOFromJson(Map<String, dynamic> json) =>
    UserSessionDTO(
      sessionId: json['sessionId'] as String?,
      deviceId: json['deviceId'] as String?,
      deviceName: json['deviceName'] as String?,
      deviceType: json['deviceType'] as String?,
      loginIp: json['loginIp'] as String?,
      active: json['active'] as bool?,
      currentSession: json['currentSession'] as bool?,
      createdAt: json['createdAt'] as String?,
      lastActiveAt: json['lastActiveAt'] as String?,
      revokedAt: json['revokedAt'] as String?,
    );

Map<String, dynamic> _$UserSessionDTOToJson(UserSessionDTO instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'deviceId': instance.deviceId,
      'deviceName': instance.deviceName,
      'deviceType': instance.deviceType,
      'loginIp': instance.loginIp,
      'active': instance.active,
      'currentSession': instance.currentSession,
      'createdAt': instance.createdAt,
      'lastActiveAt': instance.lastActiveAt,
      'revokedAt': instance.revokedAt,
    };
