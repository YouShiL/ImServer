import 'package:json_annotation/json_annotation.dart';

part 'user_dto.g.dart';

@JsonSerializable()
class UserDTO {
  @JsonKey(name: 'id')
  final int? id;

  @JsonKey(name: 'userId')
  final String? userId;

  @JsonKey(name: 'phone')
  final String? phone;

  @JsonKey(name: 'nickname')
  final String? nickname;

  @JsonKey(name: 'avatar')
  final String? avatar;

  @JsonKey(name: 'gender')
  final int? gender;

  @JsonKey(name: 'region')
  final String? region;

  @JsonKey(name: 'signature')
  final String? signature;

  /// 生日，约定 `yyyy-MM-dd`（与后端对齐；暂未返回时可为 null）。
  @JsonKey(name: 'birthday')
  final String? birthday;

  @JsonKey(name: 'background')
  final String? background;

  @JsonKey(name: 'onlineStatus')
  final int? onlineStatus;

  @JsonKey(name: 'isVip')
  final bool? isVip;

  @JsonKey(name: 'isPrettyNumber')
  final bool? isPrettyNumber;

  @JsonKey(name: 'prettyNumber')
  final String? prettyNumber;

  @JsonKey(name: 'friendLimit')
  final int? friendLimit;

  @JsonKey(name: 'groupLimit')
  final int? groupLimit;

  @JsonKey(name: 'groupMemberLimit')
  final int? groupMemberLimit;

  @JsonKey(name: 'deviceLock')
  final bool? deviceLock;

  @JsonKey(name: 'showOnlineStatus')
  final bool? showOnlineStatus;

  @JsonKey(name: 'showLastOnline')
  final bool? showLastOnline;

  @JsonKey(name: 'allowSearchByPhone')
  final bool? allowSearchByPhone;

  @JsonKey(name: 'needFriendVerification')
  final bool? needFriendVerification;

  @JsonKey(name: 'status')
  final int? status;

  @JsonKey(name: 'createdAt')
  final String? createdAt;

  @JsonKey(name: 'updatedAt')
  final String? updatedAt;

  @JsonKey(name: 'lastLoginAt')
  final String? lastLoginAt;

  @JsonKey(name: 'lastLoginIp')
  final String? lastLoginIp;

  UserDTO({
    this.id,
    this.userId,
    this.phone,
    this.nickname,
    this.avatar,
    this.gender,
    this.region,
    this.signature,
    this.birthday,
    this.background,
    this.onlineStatus,
    this.isVip,
    this.isPrettyNumber,
    this.prettyNumber,
    this.friendLimit,
    this.groupLimit,
    this.groupMemberLimit,
    this.deviceLock,
    this.showOnlineStatus,
    this.showLastOnline,
    this.allowSearchByPhone,
    this.needFriendVerification,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.lastLoginIp,
  });

  factory UserDTO.fromJson(Map<String, dynamic> json) => _$UserDTOFromJson(json);

  Map<String, dynamic> toJson() => _$UserDTOToJson(this);
}
