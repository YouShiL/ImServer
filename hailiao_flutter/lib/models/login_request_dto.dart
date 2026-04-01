import 'package:json_annotation/json_annotation.dart';

part 'login_request_dto.g.dart';

@JsonSerializable()
class LoginRequestDTO {
  @JsonKey(name: 'phone')
  final String phone;

  @JsonKey(name: 'password')
  final String password;

  @JsonKey(name: 'deviceId')
  final String? deviceId;

  @JsonKey(name: 'deviceName')
  final String? deviceName;

  @JsonKey(name: 'deviceType')
  final String? deviceType;

  @JsonKey(name: 'replaceExistingSession')
  final bool? replaceExistingSession;

  LoginRequestDTO({
    required this.phone,
    required this.password,
    this.deviceId,
    this.deviceName,
    this.deviceType,
    this.replaceExistingSession,
  });

  factory LoginRequestDTO.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestDTOFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestDTOToJson(this);
}
