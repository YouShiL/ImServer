import 'package:json_annotation/json_annotation.dart';
import 'user_dto.dart';

part 'blacklist_dto.g.dart';

@JsonSerializable()
class BlacklistDTO {
  @JsonKey(name: 'id')
  final int? id;

  @JsonKey(name: 'userId')
  final int? userId;

  @JsonKey(name: 'blockedUserId')
  final int? blockedUserId;

  @JsonKey(name: 'createdAt')
  final String? createdAt;

  @JsonKey(name: 'blockedUserInfo')
  final UserDTO? blockedUserInfo;

  BlacklistDTO({
    this.id,
    this.userId,
    this.blockedUserId,
    this.createdAt,
    this.blockedUserInfo,
  });

  factory BlacklistDTO.fromJson(Map<String, dynamic> json) =>
      _$BlacklistDTOFromJson(json);

  Map<String, dynamic> toJson() => _$BlacklistDTOToJson(this);
}
