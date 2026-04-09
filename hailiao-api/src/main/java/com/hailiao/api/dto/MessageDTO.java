package com.hailiao.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.util.Date;

@Schema(description = "消息 DTO")
public class MessageDTO {

    private Long id;
    private String msgId;
    private Long fromUserId;
    private Long toUserId;
    private Long groupId;
    private String content;
    private Integer msgType;
    private Integer subType;
    private String extra;
    private Boolean isRead;
    private Boolean isRecalled;
    private Boolean isDeleted;
    private Long replyToMsgId;
    private Long forwardFromMsgId;
    private Long forwardFromUserId;
    private Boolean isEdited;
    private Integer status;
    private Date createdAt;
    private UserDTO fromUserInfo;
    private String clientMsgNo;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getMsgId() { return msgId; }
    public void setMsgId(String msgId) { this.msgId = msgId; }

    public Long getFromUserId() { return fromUserId; }
    public void setFromUserId(Long fromUserId) { this.fromUserId = fromUserId; }

    public Long getToUserId() { return toUserId; }
    public void setToUserId(Long toUserId) { this.toUserId = toUserId; }

    public Long getGroupId() { return groupId; }
    public void setGroupId(Long groupId) { this.groupId = groupId; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public Integer getMsgType() { return msgType; }
    public void setMsgType(Integer msgType) { this.msgType = msgType; }

    public Integer getSubType() { return subType; }
    public void setSubType(Integer subType) { this.subType = subType; }

    public String getExtra() { return extra; }
    public void setExtra(String extra) { this.extra = extra; }

    public Boolean getIsRead() { return isRead; }
    public void setIsRead(Boolean isRead) { this.isRead = isRead; }

    public Boolean getIsRecalled() { return isRecalled; }
    public void setIsRecalled(Boolean isRecalled) { this.isRecalled = isRecalled; }

    public Boolean getIsDeleted() { return isDeleted; }
    public void setIsDeleted(Boolean isDeleted) { this.isDeleted = isDeleted; }

    public Long getReplyToMsgId() { return replyToMsgId; }
    public void setReplyToMsgId(Long replyToMsgId) { this.replyToMsgId = replyToMsgId; }

    public Long getForwardFromMsgId() { return forwardFromMsgId; }
    public void setForwardFromMsgId(Long forwardFromMsgId) { this.forwardFromMsgId = forwardFromMsgId; }

    public Long getForwardFromUserId() { return forwardFromUserId; }
    public void setForwardFromUserId(Long forwardFromUserId) { this.forwardFromUserId = forwardFromUserId; }

    public Boolean getIsEdited() { return isEdited; }
    public void setIsEdited(Boolean isEdited) { this.isEdited = isEdited; }

    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }

    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }

    public UserDTO getFromUserInfo() { return fromUserInfo; }
    public void setFromUserInfo(UserDTO fromUserInfo) { this.fromUserInfo = fromUserInfo; }

    public String getClientMsgNo() { return clientMsgNo; }
    public void setClientMsgNo(String clientMsgNo) { this.clientMsgNo = clientMsgNo; }
}
