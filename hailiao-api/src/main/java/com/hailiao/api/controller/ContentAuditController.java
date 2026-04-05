package com.hailiao.api.controller;

import com.hailiao.api.dto.ContentAuditDTO;
import com.hailiao.api.dto.ResponseDTO;
import com.hailiao.common.entity.ContentAudit;
import com.hailiao.common.service.ContentAuditService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/api/content-audit")
public class ContentAuditController {

    @Autowired
    private ContentAuditService contentAuditService;

    @GetMapping("/mine")
    public ResponseEntity<ResponseDTO<List<ContentAuditDTO>>> getMyAudits(
            @RequestAttribute("userId") Long userId) {
        try {
            List<ContentAudit> audits = contentAuditService.getUserAudits(userId);
            List<ContentAuditDTO> dtos = new ArrayList<>();
            for (ContentAudit audit : audits) {
                dtos.add(toDTO(audit));
            }
            return ResponseEntity.ok(ResponseDTO.success(dtos));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    private ContentAuditDTO toDTO(ContentAudit audit) {
        ContentAuditDTO dto = new ContentAuditDTO();
        dto.setId(audit.getId());
        dto.setContentType(audit.getContentType());
        dto.setContentTypeLabel(getContentTypeLabel(audit.getContentType()));
        dto.setTargetId(audit.getTargetId());
        dto.setContent(audit.getContent());
        dto.setUserId(audit.getUserId());
        dto.setAiResult(audit.getAiResult());
        dto.setAiResultLabel(getResultLabel(audit.getAiResult()));
        dto.setAiScore(audit.getAiScore());
        dto.setManualResult(audit.getManualResult());
        dto.setManualResultLabel(getResultLabel(audit.getManualResult()));
        dto.setHandlerId(audit.getHandlerId());
        dto.setHandleNote(audit.getHandleNote());
        dto.setStatus(audit.getStatus());
        dto.setStatusLabel(getStatusLabel(audit.getStatus()));
        dto.setFinalResultLabel(getFinalResultLabel(audit));
        dto.setCreatedAt(audit.getCreatedAt());
        dto.setHandledAt(audit.getHandledAt());
        return dto;
    }

    private String getContentTypeLabel(Integer contentType) {
        if (contentType == null) {
            return "文本";
        }
        switch (contentType) {
            case 2:
                return "图片";
            case 3:
                return "语音";
            case 4:
                return "视频";
            case 5:
                return "文件";
            case 6:
                return "位置";
            default:
                return "文本";
        }
    }

    private String getResultLabel(Integer result) {
        if (result == null) {
            return "待处理";
        }
        switch (result) {
            case 1:
                return "通过";
            case 2:
                return "拦截";
            default:
                return "待处理";
        }
    }

    private String getStatusLabel(Integer status) {
        if (status == null || status == 0) {
            return "待审核";
        }
        return "已完成";
    }

    private String getFinalResultLabel(ContentAudit audit) {
        if (audit.getManualResult() != null) {
            return getResultLabel(audit.getManualResult());
        }
        if (audit.getAiResult() != null) {
            return getResultLabel(audit.getAiResult());
        }
        return "待处理";
    }
}
