import 'user_dto.dart';

class FriendRequestDTO {
  final int? id;
  final int? fromUserId;
  final int? toUserId;
  final String? remark;
  final String? message;
  final int? status;
  final String? handledAt;
  final String? createdAt;
  final UserDTO? fromUserInfo;
  final UserDTO? toUserInfo;

  FriendRequestDTO({
    this.id,
    this.fromUserId,
    this.toUserId,
    this.remark,
    this.message,
    this.status,
    this.handledAt,
    this.createdAt,
    this.fromUserInfo,
    this.toUserInfo,
  });

  factory FriendRequestDTO.fromJson(Map<String, dynamic> json) {
    return FriendRequestDTO(
      id: (json['id'] as num?)?.toInt(),
      fromUserId: (json['fromUserId'] as num?)?.toInt(),
      toUserId: (json['toUserId'] as num?)?.toInt(),
      remark: json['remark'] as String?,
      message: json['message'] as String?,
      status: (json['status'] as num?)?.toInt(),
      handledAt: json['handledAt'] as String?,
      createdAt: json['createdAt'] as String?,
      fromUserInfo: json['fromUserInfo'] is Map<String, dynamic>
          ? UserDTO.fromJson(json['fromUserInfo'] as Map<String, dynamic>)
          : null,
      toUserInfo: json['toUserInfo'] is Map<String, dynamic>
          ? UserDTO.fromJson(json['toUserInfo'] as Map<String, dynamic>)
          : null,
    );
  }
}
