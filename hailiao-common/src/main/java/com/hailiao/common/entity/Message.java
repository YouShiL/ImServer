package com.hailiao.common.entity;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.Table;
import java.io.Serializable;
import java.util.Date;

/**
 * 消息实体。
 */
@Entity
@Table(name = "message")
public class Message implements Serializable {
    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "msg_id", unique = true, nullable = false, length = 50)
    private String msgId;

    @Column(name = "from_user_id", nullable = false)
    private Long fromUserId;

    @Column(name = "to_user_id")
    private Long toUserId;

    @Column(name = "group_id")
    private Long groupId;

    @Column(name = "content", columnDefinition = "TEXT")
    private String content;

    @Column(name = "msg_type")
    private Integer msgType;

    @Column(name = "extra", length = 1000)
    private String extra;

    @Column(name = "reply_to_msg_id")
    private Long replyToMsgId;

    @Column(name = "forward_from_msg_id")
    private Long forwardFromMsgId;

    @Column(name = "forward_from_user_id")
    private Long forwardFromUserId;

    @Column(name = "forward_from_nickname", length = 50)
    private String forwardFromNickname;

    @Column(name = "is_edited")
    private Boolean isEdited;

    @Column(name = "edit_time")
    private Date editTime;

    @Column(name = "is_pinned")
    private Boolean isPinned;

    @Column(name = "pin_time")
    private Date pinTime;

    @Column(name = "at_user_ids", length = 500)
    private String atUserIds;

    @Column(name = "is_at_all")
    private Boolean isAtAll;

    @Column(name = "read_count")
    private Integer readCount;

    @Column(name = "status")
    private Integer status;

    @Column(name = "is_read")
    private Boolean isRead;

    @Column(name = "is_recall")
    private Boolean isRecall;

    @Column(name = "recall_time")
    private Date recallTime;

    @Column(name = "created_at")
    private Date createdAt;

    /** 客户端幂等键（文本）；可空，非空时全局唯一 */
    @Column(name = "client_msg_no", length = 64, unique = true)
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

    public String getExtra() { return extra; }
    public void setExtra(String extra) { this.extra = extra; }

    public Long getReplyToMsgId() { return replyToMsgId; }
    public void setReplyToMsgId(Long replyToMsgId) { this.replyToMsgId = replyToMsgId; }

    public Long getForwardFromMsgId() { return forwardFromMsgId; }
    public void setForwardFromMsgId(Long forwardFromMsgId) { this.forwardFromMsgId = forwardFromMsgId; }

    public Long getForwardFromUserId() { return forwardFromUserId; }
    public void setForwardFromUserId(Long forwardFromUserId) { this.forwardFromUserId = forwardFromUserId; }

    public String getForwardFromNickname() { return forwardFromNickname; }
    public void setForwardFromNickname(String forwardFromNickname) { this.forwardFromNickname = forwardFromNickname; }

    public Boolean getIsEdited() { return isEdited; }
    public void setIsEdited(Boolean isEdited) { this.isEdited = isEdited; }

    public Date getEditTime() { return editTime; }
    public void setEditTime(Date editTime) { this.editTime = editTime; }

    public Boolean getIsPinned() { return isPinned; }
    public void setIsPinned(Boolean isPinned) { this.isPinned = isPinned; }

    public Date getPinTime() { return pinTime; }
    public void setPinTime(Date pinTime) { this.pinTime = pinTime; }

    public String getAtUserIds() { return atUserIds; }
    public void setAtUserIds(String atUserIds) { this.atUserIds = atUserIds; }

    public Boolean getIsAtAll() { return isAtAll; }
    public void setIsAtAll(Boolean isAtAll) { this.isAtAll = isAtAll; }

    public Integer getReadCount() { return readCount; }
    public void setReadCount(Integer readCount) { this.readCount = readCount; }

    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }

    public Boolean getIsRead() { return isRead; }
    public void setIsRead(Boolean isRead) { this.isRead = isRead; }

    public Boolean getIsRecall() { return isRecall; }
    public void setIsRecall(Boolean isRecall) { this.isRecall = isRecall; }

    public Date getRecallTime() { return recallTime; }
    public void setRecallTime(Date recallTime) { this.recallTime = recallTime; }

    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }

    public String getClientMsgNo() { return clientMsgNo; }
    public void setClientMsgNo(String clientMsgNo) { this.clientMsgNo = clientMsgNo; }
}
