import 'package:json_annotation/json_annotation.dart';
import 'user_dto.dart';

part 'friend_dto.g.dart';

@JsonSerializable()
class FriendDTO {
  @JsonKey(name: 'id')
  final int? id;

  @JsonKey(name: 'userId')
  final int? userId;

  @JsonKey(name: 'friendId')
  final int? friendId;

  @JsonKey(name: 'remark')
  final String? remark;

  @JsonKey(name: 'groupName')
  final String? groupName;

  @JsonKey(name: 'status')
  final int? status;

  @JsonKey(name: 'createdAt')
  final String? createdAt;

  @JsonKey(name: 'updatedAt')
  final String? updatedAt;

  @JsonKey(name: 'friendUserInfo')
  final UserDTO? friendUserInfo;

  FriendDTO({
    this.id,
    this.userId,
    this.friendId,
    this.remark,
    this.groupName,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.friendUserInfo,
  });

  factory FriendDTO.fromJson(Map<String, dynamic> json) =>
      _$FriendDTOFromJson(json);

  Map<String, dynamic> toJson() => _$FriendDTOToJson(this);
}
