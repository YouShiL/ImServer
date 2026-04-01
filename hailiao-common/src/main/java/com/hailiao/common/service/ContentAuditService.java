package com.hailiao.common.service;

import com.hailiao.common.entity.ContentAudit;
import com.hailiao.common.repository.ContentAuditRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.persistence.criteria.Predicate;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

@Service
public class ContentAuditService {

    @Autowired
    private ContentAuditRepository contentAuditRepository;

    @Transactional
    public ContentAudit createAudit(ContentAudit audit) {
        audit.setStatus(0);
        audit.setCreatedAt(new Date());
        return contentAuditRepository.save(audit);
    }

    public ContentAudit getAuditById(Long id) {
        return contentAuditRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("\u5ba1\u6838\u8bb0\u5f55\u4e0d\u5b58\u5728"));
    }

    public Page<ContentAudit> getAuditList(Integer status, Integer contentType, Long userId, Pageable pageable) {
        Specification<ContentAudit> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            if (status != null) {
                predicates.add(cb.equal(root.get("status"), status));
            }
            if (contentType != null) {
                predicates.add(cb.equal(root.get("contentType"), contentType));
            }
            if (userId != null) {
                predicates.add(cb.equal(root.get("userId"), userId));
            }
            return cb.and(predicates.toArray(new Predicate[0]));
        };

        return contentAuditRepository.findAll(spec, pageable);
    }

    @Transactional
    public ContentAudit aiAudit(Long auditId, Integer aiResult, Integer aiScore) {
        ContentAudit audit = getAuditById(auditId);
        audit.setAiResult(aiResult);
        audit.setAiScore(aiScore);
        return contentAuditRepository.save(audit);
    }

    @Transactional
    public ContentAudit manualAudit(Long auditId, Long handlerId, Integer manualResult, String handleNote) {
        ContentAudit audit = getAuditById(auditId);
        audit.setHandlerId(handlerId);
        audit.setManualResult(manualResult);
        audit.setHandleNote(handleNote);
        audit.setStatus(1);
        audit.setHandledAt(new Date());
        return contentAuditRepository.save(audit);
    }

    public long getPendingAuditCount() {
        return contentAuditRepository.countByStatus(0);
    }

    public long getAiBlockedCount() {
        return contentAuditRepository.countByAiResult(2);
    }

    public List<ContentAudit> getUserAudits(Long userId) {
        return contentAuditRepository.findByUserId(userId);
    }
}
