import 'user_dto.dart';
import 'group_dto.dart';

class GroupJoinRequestDTO {
  final int? id;
  final int? groupId;
  final int? userId;
  final String? message;
  final int? status;
  final int? handledBy;
  final String? handledAt;
  final String? createdAt;
  final UserDTO? userInfo;
  final GroupDTO? groupInfo;

  GroupJoinRequestDTO({
    this.id,
    this.groupId,
    this.userId,
    this.message,
    this.status,
    this.handledBy,
    this.handledAt,
    this.createdAt,
    this.userInfo,
    this.groupInfo,
  });

  factory GroupJoinRequestDTO.fromJson(Map<String, dynamic> json) {
    return GroupJoinRequestDTO(
      id: (json['id'] as num?)?.toInt(),
      groupId: (json['groupId'] as num?)?.toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      message: json['message'] as String?,
      status: (json['status'] as num?)?.toInt(),
      handledBy: (json['handledBy'] as num?)?.toInt(),
      handledAt: json['handledAt'] as String?,
      createdAt: json['createdAt'] as String?,
      userInfo: json['userInfo'] is Map<String, dynamic>
          ? UserDTO.fromJson(json['userInfo'] as Map<String, dynamic>)
          : null,
      groupInfo: json['groupInfo'] is Map<String, dynamic>
          ? GroupDTO.fromJson(json['groupInfo'] as Map<String, dynamic>)
          : null,
    );
  }
}
