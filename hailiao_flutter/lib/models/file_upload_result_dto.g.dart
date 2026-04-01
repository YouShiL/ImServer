// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_upload_result_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FileUploadResultDTO _$FileUploadResultDTOFromJson(Map<String, dynamic> json) =>
    FileUploadResultDTO(
      filename: json['filename'] as String?,
      originalFilename: json['originalFilename'] as String?,
      fileUrl: json['fileUrl'] as String?,
      filePath: json['filePath'] as String?,
      fileSize: (json['fileSize'] as num?)?.toInt(),
      mimeType: json['mimeType'] as String?,
      extension: json['extension'] as String?,
      uploadTime: json['uploadTime'] as String?,
    );

Map<String, dynamic> _$FileUploadResultDTOToJson(
  FileUploadResultDTO instance,
) => <String, dynamic>{
  'filename': instance.filename,
  'originalFilename': instance.originalFilename,
  'fileUrl': instance.fileUrl,
  'filePath': instance.filePath,
  'fileSize': instance.fileSize,
  'mimeType': instance.mimeType,
  'extension': instance.extension,
  'uploadTime': instance.uploadTime,
};
