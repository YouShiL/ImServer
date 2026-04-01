package com.hailiao.common.entity;

import javax.persistence.*;
import java.io.Serializable;
import java.util.Date;

@Entity
@Table(name = "conversation")
public class Conversation implements Serializable {
    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "target_id", nullable = false)
    private Long targetId;

    @Column(name = "type")
    private Integer type;

    @Column(name = "last_msg_id")
    private Long lastMsgId;

    @Column(name = "last_msg_content", length = 500)
    private String lastMsgContent;

    @Column(name = "unread_count")
    private Integer unreadCount;

    @Column(name = "is_top")
    private Boolean isTop;

    @Column(name = "is_mute")
    private Boolean isMute;

    @Column(name = "updated_at")
    private Date updatedAt;

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public Long getTargetId() { return targetId; }
    public void setTargetId(Long targetId) { this.targetId = targetId; }

    public Integer getType() { return type; }
    public void setType(Integer type) { this.type = type; }

    public Long getLastMsgId() { return lastMsgId; }
    public void setLastMsgId(Long lastMsgId) { this.lastMsgId = lastMsgId; }

    public String getLastMsgContent() { return lastMsgContent; }
    public void setLastMsgContent(String lastMsgContent) { this.lastMsgContent = lastMsgContent; }

    public Integer getUnreadCount() { return unreadCount; }
    public void setUnreadCount(Integer unreadCount) { this.unreadCount = unreadCount; }

    public Boolean getIsTop() { return isTop; }
    public void setIsTop(Boolean isTop) { this.isTop = isTop; }

    public Boolean getIsMute() { return isMute; }
    public void setIsMute(Boolean isMute) { this.isMute = isMute; }

    public Date getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Date updatedAt) { this.updatedAt = updatedAt; }
}