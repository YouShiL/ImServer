package com.hailiao.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.util.Date;

@Schema(description = "群组信息DTO - 群组详细信息数据结构")
public class GroupDTO {

    @Schema(description = "群组ID", type = "Long", example = "1", title = "群组数据库主键ID")
    private Long id;

    @Schema(description = "群组业务ID", type = "String", example = "G100000001", title = "群组唯一业务标识符")
    private String groupId;

    @Schema(description = "群组名称", type = "String", example = "测试群聊", title = "群组名称，最长50个字符")
    private String groupName;

    @Schema(description = "群组描述", type = "String", example = "这是一个测试群聊", title = "群组描述信息，最长200个字符")
    private String description;

    @Schema(description = "群公告", type = "String", example = "群公告内容", title = "群公告，最长500个字符")
    private String notice;

    @Schema(description = "群头像URL", type = "String", example = "https://example.com/group.jpg", title = "群组头像图片地址")
    private String avatar;

    @Schema(description = "群主ID", type = "Long", example = "1", title = "群主的用户ID")
    private Long ownerId;

    @Schema(description = "群类型", type = "Integer", example = "0", title = "群类型：0-普通群 1-付费群 2-专属群")
    private Integer groupType;

    @Schema(description = "群成员数量", type = "Integer", example = "10", title = "当前群成员数量")
    private Integer memberCount;

    @Schema(description = "最大成员数", type = "Integer", example = "200", title = "群成员最大数量限制")
    private Integer maxMembers;

    @Schema(description = "是否需要验证", type = "Boolean", example = "false", title = "加入群组是否需要验证")
    private Boolean needVerify;

    private Boolean allowMemberInvite;

    private Integer joinType;

    @Schema(description = "是否全员禁言", type = "Boolean", example = "false", title = "是否开启全员禁言")
    private Boolean isMute;

    @Schema(description = "群状态", type = "Integer", example = "1", title = "群状态：0-解散 1-正常")
    private Integer status;

    @Schema(description = "创建时间", type = "Date", example = "2026-03-12T10:00:00", title = "群组创建时间")
    private Date createdAt;

    @Schema(description = "更新时间", type = "Date", example = "2026-03-12T10:00:00", title = "最后更新时间")
    private Date updatedAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getGroupId() { return groupId; }
    public void setGroupId(String groupId) { this.groupId = groupId; }

    public String getGroupName() { return groupName; }
    public void setGroupName(String groupName) { this.groupName = groupName; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getNotice() { return notice; }
    public void setNotice(String notice) { this.notice = notice; }

    public String getAvatar() { return avatar; }
    public void setAvatar(String avatar) { this.avatar = avatar; }

    public Long getOwnerId() { return ownerId; }
    public void setOwnerId(Long ownerId) { this.ownerId = ownerId; }

    public Integer getGroupType() { return groupType; }
    public void setGroupType(Integer groupType) { this.groupType = groupType; }

    public Integer getMemberCount() { return memberCount; }
    public void setMemberCount(Integer memberCount) { this.memberCount = memberCount; }

    public Integer getMaxMembers() { return maxMembers; }
    public void setMaxMembers(Integer maxMembers) { this.maxMembers = maxMembers; }

    public Boolean getNeedVerify() { return needVerify; }
    public void setNeedVerify(Boolean needVerify) { this.needVerify = needVerify; }

    public Boolean getAllowMemberInvite() { return allowMemberInvite; }
    public void setAllowMemberInvite(Boolean allowMemberInvite) { this.allowMemberInvite = allowMemberInvite; }

    public Integer getJoinType() { return joinType; }
    public void setJoinType(Integer joinType) { this.joinType = joinType; }

    public Boolean getIsMute() { return isMute; }
    public void setIsMute(Boolean isMute) { this.isMute = isMute; }

    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }

    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }

    public Date getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Date updatedAt) { this.updatedAt = updatedAt; }
}
