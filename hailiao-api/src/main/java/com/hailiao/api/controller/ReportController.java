package com.hailiao.api.controller;

import com.hailiao.api.dto.ReportDTO;
import com.hailiao.api.dto.ResponseDTO;
import com.hailiao.common.entity.Report;
import com.hailiao.common.service.ReportService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/report")
public class ReportController {

    @Autowired
    private ReportService reportService;

    @PostMapping
    public ResponseEntity<ResponseDTO<ReportDTO>> createReport(
            @RequestAttribute("userId") Long userId,
            @RequestBody Map<String, Object> request) {
        try {
            Long targetId = Long.valueOf(request.get("targetId").toString());
            Integer targetType = Integer.valueOf(request.get("targetType").toString());
            String reason = request.get("reason") != null ? request.get("reason").toString() : null;
            String evidence = request.get("evidence") != null ? request.get("evidence").toString() : null;

            if (userId.equals(targetId) && targetType == 1) {
                return ResponseEntity.badRequest().body(ResponseDTO.badRequest("\u4e0d\u80fd\u4e3e\u62a5\u81ea\u5df1"));
            }

            Report report = new Report();
            report.setReporterId(userId);
            report.setTargetId(targetId);
            report.setTargetType(targetType);
            report.setReason(reason);
            report.setEvidence(evidence);

            Report saved = reportService.createReport(report);
            return ResponseEntity.ok(ResponseDTO.success(toDTO(saved)));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @GetMapping("/mine")
    public ResponseEntity<ResponseDTO<List<ReportDTO>>> getMyReports(
            @RequestAttribute("userId") Long userId) {
        try {
            List<Report> reports = reportService.getReporterReports(userId);
            List<ReportDTO> dtos = new ArrayList<>();
            for (Report report : reports) {
                dtos.add(toDTO(report));
            }
            return ResponseEntity.ok(ResponseDTO.success(dtos));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    private ReportDTO toDTO(Report report) {
        ReportDTO dto = new ReportDTO();
        dto.setId(report.getId());
        dto.setReporterId(report.getReporterId());
        dto.setTargetId(report.getTargetId());
        dto.setTargetType(report.getTargetType());
        dto.setTargetTypeLabel(getTargetTypeLabel(report.getTargetType()));
        dto.setReason(report.getReason());
        dto.setEvidence(report.getEvidence());
        dto.setStatus(report.getStatus());
        dto.setStatusLabel(getStatusLabel(report.getStatus()));
        dto.setHandlerId(report.getHandlerId());
        dto.setHandleResult(report.getHandleResult());
        dto.setCreatedAt(report.getCreatedAt());
        dto.setHandledAt(report.getHandledAt());
        return dto;
    }

    private String getTargetTypeLabel(Integer targetType) {
        if (targetType == null) {
            return "\u672a\u77e5\u5bf9\u8c61";
        }
        switch (targetType) {
            case 1:
                return "\u7528\u6237";
            case 2:
                return "\u7fa4\u7ec4";
            case 3:
                return "\u6d88\u606f";
            default:
                return "\u672a\u77e5\u5bf9\u8c61";
        }
    }

    private String getStatusLabel(Integer status) {
        if (status == null) {
            return "\u5f85\u5904\u7406";
        }
        switch (status) {
            case 1:
                return "\u5df2\u5904\u7406";
            case 2:
                return "\u5df2\u9a73\u56de";
            default:
                return "\u5f85\u5904\u7406";
        }
    }
}
