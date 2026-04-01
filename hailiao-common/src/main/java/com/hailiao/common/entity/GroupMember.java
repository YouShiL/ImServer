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
 * 群成员实体。
 */
@Entity
@Table(name = "group_member")
public class GroupMember implements Serializable {
    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "group_id", nullable = false)
    private Long groupId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "nickname", length = 50)
    private String nickname;

    @Column(name = "role", nullable = false)
    private Integer role;

    @Column(name = "is_mute")
    private Boolean isMute;

    @Column(name = "mute_until")
    private Date muteUntil;

    @Column(name = "join_time")
    private Date joinTime;

    @Column(name = "last_read_msg_id")
    private Long lastReadMsgId;

    @Column(name = "is_top")
    private Boolean isTop;

    @Column(name = "is_mute_notification")
    private Boolean isMuteNotification;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getGroupId() { return groupId; }
    public void setGroupId(Long groupId) { this.groupId = groupId; }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public String getNickname() { return nickname; }
    public void setNickname(String nickname) { this.nickname = nickname; }

    public Integer getRole() { return role; }
    public void setRole(Integer role) { this.role = role; }

    public Boolean getIsMute() { return isMute; }
    public void setIsMute(Boolean isMute) { this.isMute = isMute; }

    public Date getMuteUntil() { return muteUntil; }
    public void setMuteUntil(Date muteUntil) { this.muteUntil = muteUntil; }

    public Date getJoinTime() { return joinTime; }
    public void setJoinTime(Date joinTime) { this.joinTime = joinTime; }

    public Long getLastReadMsgId() { return lastReadMsgId; }
    public void setLastReadMsgId(Long lastReadMsgId) { this.lastReadMsgId = lastReadMsgId; }

    public Boolean getIsTop() { return isTop; }
    public void setIsTop(Boolean isTop) { this.isTop = isTop; }

    public Boolean getIsMuteNotification() { return isMuteNotification; }
    public void setIsMuteNotification(Boolean isMuteNotification) { this.isMuteNotification = isMuteNotification; }
}
