class ContentAuditDTO {
  final int? id;
  final int? contentType;
  final String? contentTypeLabel;
  final int? targetId;
  final String? content;
  final int? userId;
  final int? aiResult;
  final String? aiResultLabel;
  final int? aiScore;
  final int? manualResult;
  final String? manualResultLabel;
  final int? handlerId;
  final String? handleNote;
  final int? status;
  final String? statusLabel;
  final String? finalResultLabel;
  final String? createdAt;
  final String? handledAt;

  ContentAuditDTO({
    this.id,
    this.contentType,
    this.contentTypeLabel,
    this.targetId,
    this.content,
    this.userId,
    this.aiResult,
    this.aiResultLabel,
    this.aiScore,
    this.manualResult,
    this.manualResultLabel,
    this.handlerId,
    this.handleNote,
    this.status,
    this.statusLabel,
    this.finalResultLabel,
    this.createdAt,
    this.handledAt,
  });

  factory ContentAuditDTO.fromJson(Map<String, dynamic> json) {
    return ContentAuditDTO(
      id: (json['id'] as num?)?.toInt(),
      contentType: (json['contentType'] as num?)?.toInt(),
      contentTypeLabel: json['contentTypeLabel'] as String?,
      targetId: (json['targetId'] as num?)?.toInt(),
      content: json['content'] as String?,
      userId: (json['userId'] as num?)?.toInt(),
      aiResult: (json['aiResult'] as num?)?.toInt(),
      aiResultLabel: json['aiResultLabel'] as String?,
      aiScore: (json['aiScore'] as num?)?.toInt(),
      manualResult: (json['manualResult'] as num?)?.toInt(),
      manualResultLabel: json['manualResultLabel'] as String?,
      handlerId: (json['handlerId'] as num?)?.toInt(),
      handleNote: json['handleNote'] as String?,
      status: (json['status'] as num?)?.toInt(),
      statusLabel: json['statusLabel'] as String?,
      finalResultLabel: json['finalResultLabel'] as String?,
      createdAt: json['createdAt'] as String?,
      handledAt: json['handledAt'] as String?,
    );
  }
}
