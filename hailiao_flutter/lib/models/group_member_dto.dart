import 'package:json_annotation/json_annotation.dart';
import 'user_dto.dart';

part 'group_member_dto.g.dart';

@JsonSerializable()
class GroupMemberDTO {
  @JsonKey(name: 'id')
  final int? id;

  @JsonKey(name: 'groupId')
  final int? groupId;

  @JsonKey(name: 'userId')
  final int? userId;

  @JsonKey(name: 'nickname')
  final String? nickname;

  @JsonKey(name: 'role')
  final int? role;

  @JsonKey(name: 'isMute')
  final bool? isMute;

  @JsonKey(name: 'joinedAt')
  final String? joinedAt;

  @JsonKey(name: 'userInfo')
  final UserDTO? userInfo;

  GroupMemberDTO({
    this.id,
    this.groupId,
    this.userId,
    this.nickname,
    this.role,
    this.isMute,
    this.joinedAt,
    this.userInfo,
  });

  factory GroupMemberDTO.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberDTOFromJson(json);

  Map<String, dynamic> toJson() => _$GroupMemberDTOToJson(this);
}
