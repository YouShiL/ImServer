// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthResponseDTO _$AuthResponseDTOFromJson(Map<String, dynamic> json) =>
    AuthResponseDTO(
      user: UserDTO.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
      sessionId: json['sessionId'] as String?,
      loginNotice: json['loginNotice'] as String?,
      deviceLock: json['deviceLock'] as bool?,
    );

Map<String, dynamic> _$AuthResponseDTOToJson(AuthResponseDTO instance) =>
    <String, dynamic>{
      'user': instance.user,
      'token': instance.token,
      'sessionId': instance.sessionId,
      'loginNotice': instance.loginNotice,
      'deviceLock': instance.deviceLock,
    };
