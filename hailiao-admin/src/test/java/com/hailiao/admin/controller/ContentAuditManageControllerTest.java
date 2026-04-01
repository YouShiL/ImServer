package com.hailiao.admin.controller;

import com.hailiao.common.entity.ContentAudit;
import com.hailiao.common.service.ContentAuditService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ContentAuditManageControllerTest {

    @Mock
    private ContentAuditService contentAuditService;

    @InjectMocks
    private ContentAuditManageController contentAuditManageController;

    @Test
    void getAuditListReturnsSummaryAndLabels() {
        ContentAudit audit = new ContentAudit();
        audit.setId(4L);
        audit.setContentType(2);
        audit.setStatus(0);
        audit.setAiResult(2);

        List<ContentAudit> audits = new ArrayList<ContentAudit>();
        audits.add(audit);
        Page<ContentAudit> page = new PageImpl<ContentAudit>(audits, PageRequest.of(0, 20), 1);
        when(contentAuditService.getAuditList(0, 2, null, PageRequest.of(0, 20, org.springframework.data.domain.Sort.by("createdAt").descending())))
                .thenReturn(page);

        ResponseEntity<?> actual = contentAuditManageController.getAuditList(0, 2, null, 0, 20);

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        Map<?, ?> body = assertInstanceOf(Map.class, actual.getBody());
        Map<?, ?> summary = assertInstanceOf(Map.class, body.get("summary"));
        assertEquals(1L, summary.get("filteredTotal"));
        assertEquals(1L, summary.get("pendingCount"));

        List<?> content = assertInstanceOf(List.class, body.get("content"));
        Map<?, ?> first = assertInstanceOf(Map.class, content.get(0));
        assertEquals("图片", first.get("contentTypeLabel"));
        assertEquals("待处理", first.get("statusLabel"));
        assertEquals("拦截", first.get("aiResultLabel"));
    }

    @Test
    void handleAuditReturnsLabeledResponse() {
        ContentAudit audit = new ContentAudit();
        audit.setId(6L);
        audit.setContentType(1);
        audit.setStatus(1);
        audit.setManualResult(1);
        when(contentAuditService.manualAudit(6L, 8L, 1, "人工通过")).thenReturn(audit);

        ResponseEntity<?> actual = contentAuditManageController.handleAudit(8L, 6L, mapOf("manualResult", 1, "handleNote", "人工通过"));

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        Map<?, ?> body = assertInstanceOf(Map.class, actual.getBody());
        assertEquals("文本", body.get("contentTypeLabel"));
        assertEquals("通过", body.get("manualResultLabel"));
        assertEquals("已处理", body.get("statusLabel"));
        verify(contentAuditService).manualAudit(6L, 8L, 1, "人工通过");
    }

    private Map<String, Object> mapOf(Object... values) {
        java.util.LinkedHashMap<String, Object> map = new java.util.LinkedHashMap<String, Object>();
        for (int i = 0; i < values.length; i += 2) {
            map.put(String.valueOf(values[i]), values[i + 1]);
        }
        return map;
    }
}
