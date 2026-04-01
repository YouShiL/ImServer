import 'package:json_annotation/json_annotation.dart';

part 'response_dto.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class ResponseDTO<T> {
  @JsonKey(name: 'code')
  final int code;

  @JsonKey(name: 'message')
  final String message;

  @JsonKey(name: 'data')
  final T? data;

  ResponseDTO({
    required this.code,
    required this.message,
    this.data,
  });

  factory ResponseDTO.fromJson(Map<String, dynamic> json, T Function(Object?) fromJsonT) =>
      _$ResponseDTOFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T?) toJsonT) =>
      _$ResponseDTOToJson(this, toJsonT);

  bool get isSuccess => code == 200;
}
