package com.hailiao.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.util.Date;

@Schema(description = "好友信息DTO - 好友关系详细信息")
public class FriendDTO {

    @Schema(description = "好友关系ID", type = "Long", example = "1", title = "好友关系唯一标识")
    private Long id;

    @Schema(description = "用户ID", type = "Long", example = "1", title = "当前用户的ID")
    private Long userId;

    @Schema(description = "好友用户ID", type = "Long", example = "2", title = "好友用户的ID")
    private Long friendId;

    @Schema(description = "好友备注", type = "String", example = "老王", title = "用户对好友的备注名称，最长20个字符，为空时显示好友昵称")
    private String remark;

    @Schema(description = "好友分组", type = "String", example = "同事", title = "好友所在的分组名称")
    private String groupName;

    @Schema(description = "好友状态", type = "Integer", example = "1", title = "好友状态：0-已删除 1-正常")
    private Integer status;

    @Schema(description = "创建时间", type = "Date", example = "2026-03-12T10:00:00", title = "成为好友的时间")
    private Date createdAt;

    @Schema(description = "更新时间", type = "Date", example = "2026-03-12T10:00:00", title = "最后更新时间")
    private Date updatedAt;

    @Schema(description = "好友用户信息", title = "好友用户的详细信息")
    private UserDTO friendUserInfo;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public Long getFriendId() { return friendId; }
    public void setFriendId(Long friendId) { this.friendId = friendId; }

    public String getRemark() { return remark; }
    public void setRemark(String remark) { this.remark = remark; }

    public String getGroupName() { return groupName; }
    public void setGroupName(String groupName) { this.groupName = groupName; }

    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }

    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }

    public Date getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Date updatedAt) { this.updatedAt = updatedAt; }

    public UserDTO getFriendUserInfo() { return friendUserInfo; }
    public void setFriendUserInfo(UserDTO friendUserInfo) { this.friendUserInfo = friendUserInfo; }
}
