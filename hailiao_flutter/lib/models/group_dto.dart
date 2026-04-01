import 'package:json_annotation/json_annotation.dart';

part 'group_dto.g.dart';

@JsonSerializable()
class GroupDTO {
  @JsonKey(name: 'id')
  final int? id;

  @JsonKey(name: 'groupId')
  final String? groupId;

  @JsonKey(name: 'groupName')
  final String? groupName;

  @JsonKey(name: 'description')
  final String? description;

  @JsonKey(name: 'notice')
  final String? notice;

  @JsonKey(name: 'avatar')
  final String? avatar;

  @JsonKey(name: 'ownerId')
  final int? ownerId;

  @JsonKey(name: 'groupType')
  final int? groupType;

  @JsonKey(name: 'memberCount')
  final int? memberCount;

  @JsonKey(name: 'maxMembers')
  final int? maxMembers;

  @JsonKey(name: 'needVerify')
  final bool? needVerify;

  @JsonKey(name: 'allowMemberInvite')
  final bool? allowMemberInvite;

  @JsonKey(name: 'joinType')
  final int? joinType;

  @JsonKey(name: 'isMute')
  final bool? isMute;

  @JsonKey(name: 'status')
  final int? status;

  @JsonKey(name: 'createdAt')
  final String? createdAt;

  @JsonKey(name: 'updatedAt')
  final String? updatedAt;

  GroupDTO({
    this.id,
    this.groupId,
    this.groupName,
    this.description,
    this.notice,
    this.avatar,
    this.ownerId,
    this.groupType,
    this.memberCount,
    this.maxMembers,
    this.needVerify,
    this.allowMemberInvite,
    this.joinType,
    this.isMute,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory GroupDTO.fromJson(Map<String, dynamic> json) => _$GroupDTOFromJson(json);

  Map<String, dynamic> toJson() => _$GroupDTOToJson(this);
}
