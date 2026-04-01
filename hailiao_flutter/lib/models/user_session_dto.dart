import 'package:json_annotation/json_annotation.dart';

part 'user_session_dto.g.dart';

@JsonSerializable()
class UserSessionDTO {
  @JsonKey(name: 'sessionId')
  final String? sessionId;

  @JsonKey(name: 'deviceId')
  final String? deviceId;

  @JsonKey(name: 'deviceName')
  final String? deviceName;

  @JsonKey(name: 'deviceType')
  final String? deviceType;

  @JsonKey(name: 'loginIp')
  final String? loginIp;

  @JsonKey(name: 'active')
  final bool? active;

  @JsonKey(name: 'currentSession')
  final bool? currentSession;

  @JsonKey(name: 'createdAt')
  final String? createdAt;

  @JsonKey(name: 'lastActiveAt')
  final String? lastActiveAt;

  @JsonKey(name: 'revokedAt')
  final String? revokedAt;

  UserSessionDTO({
    this.sessionId,
    this.deviceId,
    this.deviceName,
    this.deviceType,
    this.loginIp,
    this.active,
    this.currentSession,
    this.createdAt,
    this.lastActiveAt,
    this.revokedAt,
  });

  factory UserSessionDTO.fromJson(Map<String, dynamic> json) =>
      _$UserSessionDTOFromJson(json);

  Map<String, dynamic> toJson() => _$UserSessionDTOToJson(this);
}
