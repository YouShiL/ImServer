package com.hailiao.api.controller;

import com.hailiao.api.dto.ContentAuditDTO;
import com.hailiao.api.dto.ResponseDTO;
import com.hailiao.common.entity.ContentAudit;
import com.hailiao.common.service.ContentAuditService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ContentAuditControllerTest {

    @Mock
    private ContentAuditService contentAuditService;

    @InjectMocks
    private ContentAuditController contentAuditController;

    @Test
    void getMyAuditsShouldReturnLabeledDtos() {
        List<ContentAudit> audits = new ArrayList<ContentAudit>();
        ContentAudit audit = new ContentAudit();
        audit.setId(1L);
        audit.setContentType(2);
        audit.setTargetId(10L);
        audit.setContent("图片地址");
        audit.setUserId(1L);
        audit.setAiResult(2);
        audit.setManualResult(1);
        audit.setStatus(1);
        audits.add(audit);

        when(contentAuditService.getUserAudits(1L)).thenReturn(audits);

        ResponseEntity<ResponseDTO<List<ContentAuditDTO>>> response = contentAuditController.getMyAudits(1L);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(1, response.getBody().getData().size());
        assertEquals("图片", response.getBody().getData().get(0).getContentTypeLabel());
        assertEquals("拦截", response.getBody().getData().get(0).getAiResultLabel());
        assertEquals("通过", response.getBody().getData().get(0).getManualResultLabel());
        assertEquals("已完成", response.getBody().getData().get(0).getStatusLabel());
        assertEquals("通过", response.getBody().getData().get(0).getFinalResultLabel());
    }
}
