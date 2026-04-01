// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterRequestDTO _$RegisterRequestDTOFromJson(Map<String, dynamic> json) =>
    RegisterRequestDTO(
      phone: json['phone'] as String,
      password: json['password'] as String,
      nickname: json['nickname'] as String?,
    );

Map<String, dynamic> _$RegisterRequestDTOToJson(RegisterRequestDTO instance) =>
    <String, dynamic>{
      'phone': instance.phone,
      'password': instance.password,
      'nickname': instance.nickname,
    };
