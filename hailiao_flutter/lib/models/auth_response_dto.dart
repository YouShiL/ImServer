import 'package:json_annotation/json_annotation.dart';
import 'user_dto.dart';

part 'auth_response_dto.g.dart';

@JsonSerializable()
class AuthResponseDTO {
  @JsonKey(name: 'user')
  final UserDTO user;

  @JsonKey(name: 'token')
  final String token;

  @JsonKey(name: 'sessionId')
  final String? sessionId;

  @JsonKey(name: 'loginNotice')
  final String? loginNotice;

  @JsonKey(name: 'deviceLock')
  final bool? deviceLock;

  AuthResponseDTO({
    required this.user,
    required this.token,
    this.sessionId,
    this.loginNotice,
    this.deviceLock,
  });

  factory AuthResponseDTO.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseDTOFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseDTOToJson(this);
}
