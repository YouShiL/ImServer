package com.hailiao.api.dto;

import java.util.Date;

public class ContentAuditDTO {
    private Long id;
    private Integer contentType;
    private String contentTypeLabel;
    private Long targetId;
    private String content;
    private Long userId;
    private Integer aiResult;
    private String aiResultLabel;
    private Integer aiScore;
    private Integer manualResult;
    private String manualResultLabel;
    private Long handlerId;
    private String handleNote;
    private Integer status;
    private String statusLabel;
    private String finalResultLabel;
    private Date createdAt;
    private Date handledAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Integer getContentType() { return contentType; }
    public void setContentType(Integer contentType) { this.contentType = contentType; }
    public String getContentTypeLabel() { return contentTypeLabel; }
    public void setContentTypeLabel(String contentTypeLabel) { this.contentTypeLabel = contentTypeLabel; }
    public Long getTargetId() { return targetId; }
    public void setTargetId(Long targetId) { this.targetId = targetId; }
    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public Integer getAiResult() { return aiResult; }
    public void setAiResult(Integer aiResult) { this.aiResult = aiResult; }
    public String getAiResultLabel() { return aiResultLabel; }
    public void setAiResultLabel(String aiResultLabel) { this.aiResultLabel = aiResultLabel; }
    public Integer getAiScore() { return aiScore; }
    public void setAiScore(Integer aiScore) { this.aiScore = aiScore; }
    public Integer getManualResult() { return manualResult; }
    public void setManualResult(Integer manualResult) { this.manualResult = manualResult; }
    public String getManualResultLabel() { return manualResultLabel; }
    public void setManualResultLabel(String manualResultLabel) { this.manualResultLabel = manualResultLabel; }
    public Long getHandlerId() { return handlerId; }
    public void setHandlerId(Long handlerId) { this.handlerId = handlerId; }
    public String getHandleNote() { return handleNote; }
    public void setHandleNote(String handleNote) { this.handleNote = handleNote; }
    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }
    public String getStatusLabel() { return statusLabel; }
    public void setStatusLabel(String statusLabel) { this.statusLabel = statusLabel; }
    public String getFinalResultLabel() { return finalResultLabel; }
    public void setFinalResultLabel(String finalResultLabel) { this.finalResultLabel = finalResultLabel; }
    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }
    public Date getHandledAt() { return handledAt; }
    public void setHandledAt(Date handledAt) { this.handledAt = handledAt; }
}
