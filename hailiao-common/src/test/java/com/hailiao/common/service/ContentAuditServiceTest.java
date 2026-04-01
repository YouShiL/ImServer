package com.hailiao.common.service;

import com.hailiao.common.entity.ContentAudit;
import com.hailiao.common.repository.ContentAuditRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ContentAuditServiceTest {

    @Mock
    private ContentAuditRepository contentAuditRepository;

    @InjectMocks
    private ContentAuditService contentAuditService;

    @Test
    void createAuditShouldApplyPendingStatusAndCreatedAt() {
        when(contentAuditRepository.save(any(ContentAudit.class))).thenAnswer(new org.mockito.stubbing.Answer<ContentAudit>() {
            @Override
            public ContentAudit answer(org.mockito.invocation.InvocationOnMock invocation) {
                return (ContentAudit) invocation.getArgument(0);
            }
        });

        ContentAudit audit = new ContentAudit();
        audit.setContentType(2);
        audit.setUserId(1L);

        ContentAudit saved = contentAuditService.createAudit(audit);

        assertEquals(Integer.valueOf(0), saved.getStatus());
        assertNotNull(saved.getCreatedAt());
    }

    @Test
    void getAuditByIdShouldThrowWhenMissing() {
        when(contentAuditRepository.findById(1L)).thenReturn(Optional.<ContentAudit>empty());

        RuntimeException error = assertThrows(RuntimeException.class,
                new org.junit.jupiter.api.function.Executable() {
                    @Override
                    public void execute() {
                        contentAuditService.getAuditById(1L);
                    }
                });

        assertEquals("审核记录不存在", error.getMessage());
    }

    @Test
    void aiAuditShouldUpdateResultAndScore() {
        ContentAudit audit = new ContentAudit();
        audit.setId(1L);

        when(contentAuditRepository.findById(1L)).thenReturn(Optional.of(audit));
        when(contentAuditRepository.save(any(ContentAudit.class))).thenAnswer(new org.mockito.stubbing.Answer<ContentAudit>() {
            @Override
            public ContentAudit answer(org.mockito.invocation.InvocationOnMock invocation) {
                return (ContentAudit) invocation.getArgument(0);
            }
        });

        ContentAudit saved = contentAuditService.aiAudit(1L, 2, 95);

        assertEquals(Integer.valueOf(2), saved.getAiResult());
        assertEquals(Integer.valueOf(95), saved.getAiScore());
    }

    @Test
    void manualAuditShouldFinalizeAudit() {
        ContentAudit audit = new ContentAudit();
        audit.setId(1L);
        audit.setStatus(0);

        when(contentAuditRepository.findById(1L)).thenReturn(Optional.of(audit));
        when(contentAuditRepository.save(any(ContentAudit.class))).thenAnswer(new org.mockito.stubbing.Answer<ContentAudit>() {
            @Override
            public ContentAudit answer(org.mockito.invocation.InvocationOnMock invocation) {
                return (ContentAudit) invocation.getArgument(0);
            }
        });

        ContentAudit saved = contentAuditService.manualAudit(1L, 9L, 1, "人工通过");

        assertEquals(Long.valueOf(9L), saved.getHandlerId());
        assertEquals(Integer.valueOf(1), saved.getManualResult());
        assertEquals(Integer.valueOf(1), saved.getStatus());
        assertEquals("人工通过", saved.getHandleNote());
        assertNotNull(saved.getHandledAt());
    }

    @Test
    void getUserAuditsShouldDelegateToRepository() {
        List<ContentAudit> audits = Arrays.asList(new ContentAudit());
        when(contentAuditRepository.findByUserId(1L)).thenReturn(audits);

        List<ContentAudit> result = contentAuditService.getUserAudits(1L);

        assertEquals(1, result.size());
        verify(contentAuditRepository).findByUserId(1L);
    }
}
