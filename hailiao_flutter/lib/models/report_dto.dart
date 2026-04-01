class ReportDTO {
  final int? id;
  final int? reporterId;
  final int? targetId;
  final int? targetType;
  final String? targetTypeLabel;
  final String? reason;
  final String? evidence;
  final int? status;
  final String? statusLabel;
  final int? handlerId;
  final String? handleResult;
  final String? createdAt;
  final String? handledAt;

  ReportDTO({
    this.id,
    this.reporterId,
    this.targetId,
    this.targetType,
    this.targetTypeLabel,
    this.reason,
    this.evidence,
    this.status,
    this.statusLabel,
    this.handlerId,
    this.handleResult,
    this.createdAt,
    this.handledAt,
  });

  factory ReportDTO.fromJson(Map<String, dynamic> json) {
    return ReportDTO(
      id: (json['id'] as num?)?.toInt(),
      reporterId: (json['reporterId'] as num?)?.toInt(),
      targetId: (json['targetId'] as num?)?.toInt(),
      targetType: (json['targetType'] as num?)?.toInt(),
      targetTypeLabel: json['targetTypeLabel'] as String?,
      reason: json['reason'] as String?,
      evidence: json['evidence'] as String?,
      status: (json['status'] as num?)?.toInt(),
      statusLabel: json['statusLabel'] as String?,
      handlerId: (json['handlerId'] as num?)?.toInt(),
      handleResult: json['handleResult'] as String?,
      createdAt: json['createdAt'] as String?,
      handledAt: json['handledAt'] as String?,
    );
  }
}
