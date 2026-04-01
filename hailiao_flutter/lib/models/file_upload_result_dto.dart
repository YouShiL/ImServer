import 'package:json_annotation/json_annotation.dart';

part 'file_upload_result_dto.g.dart';

@JsonSerializable()
class FileUploadResultDTO {
  @JsonKey(name: 'filename')
  final String? filename;

  @JsonKey(name: 'originalFilename')
  final String? originalFilename;

  @JsonKey(name: 'fileUrl')
  final String? fileUrl;

  @JsonKey(name: 'filePath')
  final String? filePath;

  @JsonKey(name: 'fileSize')
  final int? fileSize;

  @JsonKey(name: 'mimeType')
  final String? mimeType;

  @JsonKey(name: 'extension')
  final String? extension;

  @JsonKey(name: 'uploadTime')
  final String? uploadTime;

  FileUploadResultDTO({
    this.filename,
    this.originalFilename,
    this.fileUrl,
    this.filePath,
    this.fileSize,
    this.mimeType,
    this.extension,
    this.uploadTime,
  });

  factory FileUploadResultDTO.fromJson(Map<String, dynamic> json) =>
      _$FileUploadResultDTOFromJson(json);

  Map<String, dynamic> toJson() => _$FileUploadResultDTOToJson(this);
}
