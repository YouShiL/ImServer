import 'package:flutter/foundation.dart';
import 'package:hailiao_flutter/models/content_audit_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/services/api_service.dart';

abstract class ContentAuditApi {
  Future<ResponseDTO<List<ContentAuditDTO>>> getMyContentAudits();
}

class ApiContentAuditApi implements ContentAuditApi {
  @override
  Future<ResponseDTO<List<ContentAuditDTO>>> getMyContentAudits() {
    return ApiService.getMyContentAudits();
  }
}

class ContentAuditProvider extends ChangeNotifier {
  ContentAuditProvider({ContentAuditApi? api})
    : _api = api ?? ApiContentAuditApi();

  final ContentAuditApi _api;
  List<ContentAuditDTO> _audits = [];
  bool _isLoading = false;
  String? _error;

  List<ContentAuditDTO> get audits => _audits;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAudits() async {
    _startLoading();
    try {
      final response = await _api.getMyContentAudits();
      if (response.isSuccess && response.data != null) {
        _audits = response.data!;
      } else {
        _error = response.message;
      }
    } catch (_) {
      _error =
          '加载内容审核记录失败，请稍后重试。';
    } finally {
      _finishLoading();
    }
  }

  void _startLoading() {
    _isLoading = true;
    _error = null;
    notifyListeners();
  }

  void _finishLoading() {
    _isLoading = false;
    notifyListeners();
  }
}
