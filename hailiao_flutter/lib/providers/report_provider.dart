import 'package:flutter/foundation.dart';
import 'package:hailiao_flutter/models/report_dto.dart';
import 'package:hailiao_flutter/models/response_dto.dart';
import 'package:hailiao_flutter/services/api_service.dart';

abstract class ReportApi {
  Future<ResponseDTO<ReportDTO>> createReport(
    int targetId,
    int targetType,
    String reason, {
    String? evidence,
  });

  Future<ResponseDTO<List<ReportDTO>>> getMyReports();
}

class ApiReportApi implements ReportApi {
  @override
  Future<ResponseDTO<ReportDTO>> createReport(
    int targetId,
    int targetType,
    String reason, {
    String? evidence,
  }) {
    return ApiService.createReport(
      targetId,
      targetType,
      reason,
      evidence: evidence,
    );
  }

  @override
  Future<ResponseDTO<List<ReportDTO>>> getMyReports() {
    return ApiService.getMyReports();
  }
}

class ReportProvider extends ChangeNotifier {
  ReportProvider({ReportApi? api}) : _api = api ?? ApiReportApi();

  final ReportApi _api;
  List<ReportDTO> _reports = [];
  bool _isLoading = false;
  String? _error;

  List<ReportDTO> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadReports() async {
    _startLoading();
    try {
      final response = await _api.getMyReports();
      if (response.isSuccess && response.data != null) {
        _reports = response.data!;
      } else {
        _error = response.message;
      }
    } catch (_) {
      _error = '加载举报记录失败，请稍后重试。';
    } finally {
      _finishLoading();
    }
  }

  Future<bool> createReport(
    int targetId,
    int targetType,
    String reason, {
    String? evidence,
  }) async {
    _startLoading();
    try {
      final response = await _api.createReport(
        targetId,
        targetType,
        reason,
        evidence: evidence,
      );
      if (response.isSuccess && response.data != null) {
        _reports = [response.data!, ..._reports];
        return true;
      }
      _error = response.message;
      return false;
    } catch (_) {
      _error = '提交举报失败，请稍后重试。';
      return false;
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
