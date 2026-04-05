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
                return ResponseEntity.badRequest().body(ResponseDTO.badRequest("不能举报自己"));
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
            return "未知对象";
        }
        switch (targetType) {
            case 1:
                return "用户";
            case 2:
                return "群组";
            case 3:
                return "消息";
            default:
                return "未知对象";
        }
    }

    private String getStatusLabel(Integer status) {
        if (status == null) {
            return "待处理";
        }
        switch (status) {
            case 1:
                return "已处理";
            case 2:
                return "已驳回";
            default:
                return "待处理";
        }
    }
}
