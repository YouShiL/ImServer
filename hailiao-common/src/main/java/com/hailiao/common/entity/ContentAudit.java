package com.hailiao.common.entity;

import javax.persistence.*;
import java.io.Serializable;
import java.util.Date;

@Entity
@Table(name = "content_audit")
public class ContentAudit implements Serializable {
    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "content_type")
    private Integer contentType;

    @Column(name = "target_id")
    private Long targetId;

    @Column(name = "content", columnDefinition = "TEXT")
    private String content;

    @Column(name = "user_id")
    private Long userId;

    @Column(name = "ai_result")
    private Integer aiResult;

    @Column(name = "ai_score")
    private Integer aiScore;

    @Column(name = "manual_result")
    private Integer manualResult;

    @Column(name = "handler_id")
    private Long handlerId;

    @Column(name = "handle_note", length = 500)
    private String handleNote;

    @Column(name = "status")
    private Integer status;

    @Column(name = "created_at")
    private Date createdAt;

    @Column(name = "handled_at")
    private Date handledAt;

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Integer getContentType() { return contentType; }
    public void setContentType(Integer contentType) { this.contentType = contentType; }

    public Long getTargetId() { return targetId; }
    public void setTargetId(Long targetId) { this.targetId = targetId; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public Integer getAiResult() { return aiResult; }
    public void setAiResult(Integer aiResult) { this.aiResult = aiResult; }

    public Integer getAiScore() { return aiScore; }
    public void setAiScore(Integer aiScore) { this.aiScore = aiScore; }

    public Integer getManualResult() { return manualResult; }
    public void setManualResult(Integer manualResult) { this.manualResult = manualResult; }

    public Long getHandlerId() { return handlerId; }
    public void setHandlerId(Long handlerId) { this.handlerId = handlerId; }

    public String getHandleNote() { return handleNote; }
    public void setHandleNote(String handleNote) { this.handleNote = handleNote; }

    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }

    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }

    public Date getHandledAt() { return handledAt; }
    public void setHandledAt(Date handledAt) { this.handledAt = handledAt; }
}