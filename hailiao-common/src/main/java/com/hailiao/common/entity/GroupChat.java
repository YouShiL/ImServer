package com.hailiao.common.entity;

import javax.persistence.*;
import java.io.Serializable;
import java.util.Date;

@Entity
@Table(name = "group_chat")
public class GroupChat implements Serializable {
    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "group_id", unique = true, nullable = false, length = 20)
    private String groupId;

    @Column(name = "group_name", nullable = false, length = 100)
    private String groupName;

    @Column(name = "owner_id", nullable = false)
    private Long ownerId;

    @Column(name = "avatar", length = 255)
    private String avatar;

    @Column(name = "description", length = 500)
    private String description;

    @Column(name = "notice", length = 1000)
    private String notice;

    @Column(name = "notice_updated_at")
    private Date noticeUpdatedAt;

    @Column(name = "notice_updated_by")
    private Long noticeUpdatedBy;

    @Column(name = "member_count")
    private Integer memberCount;

    @Column(name = "max_member_count")
    private Integer maxMemberCount;

    @Column(name = "is_mute")
    private Boolean isMute;

    @Column(name = "mute_all")
    private Boolean muteAll;

    @Column(name = "allow_member_invite")
    private Boolean allowMemberInvite;

    @Column(name = "join_type")
    private Integer joinType;

    @Column(name = "status")
    private Integer status;

    @Column(name = "created_at")
    private Date createdAt;

    @Column(name = "updated_at")
    private Date updatedAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getGroupId() { return groupId; }
    public void setGroupId(String groupId) { this.groupId = groupId; }

    public String getGroupName() { return groupName; }
    public void setGroupName(String groupName) { this.groupName = groupName; }

    public Long getOwnerId() { return ownerId; }
    public void setOwnerId(Long ownerId) { this.ownerId = ownerId; }

    public String getAvatar() { return avatar; }
    public void setAvatar(String avatar) { this.avatar = avatar; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getNotice() { return notice; }
    public void setNotice(String notice) { this.notice = notice; }

    public Date getNoticeUpdatedAt() { return noticeUpdatedAt; }
    public void setNoticeUpdatedAt(Date noticeUpdatedAt) { this.noticeUpdatedAt = noticeUpdatedAt; }

    public Long getNoticeUpdatedBy() { return noticeUpdatedBy; }
    public void setNoticeUpdatedBy(Long noticeUpdatedBy) { this.noticeUpdatedBy = noticeUpdatedBy; }

    public Integer getMemberCount() { return memberCount; }
    public void setMemberCount(Integer memberCount) { this.memberCount = memberCount; }

    public Integer getMaxMemberCount() { return maxMemberCount; }
    public void setMaxMemberCount(Integer maxMemberCount) { this.maxMemberCount = maxMemberCount; }

    public Boolean getIsMute() { return isMute; }
    public void setIsMute(Boolean isMute) { this.isMute = isMute; }

    public Boolean getMuteAll() { return muteAll; }
    public void setMuteAll(Boolean muteAll) { this.muteAll = muteAll; }

    public Boolean getAllowMemberInvite() { return allowMemberInvite; }
    public void setAllowMemberInvite(Boolean allowMemberInvite) { this.allowMemberInvite = allowMemberInvite; }

    public Integer getJoinType() { return joinType; }
    public void setJoinType(Integer joinType) { this.joinType = joinType; }

    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }

    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }

    public Date getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Date updatedAt) { this.updatedAt = updatedAt; }
}