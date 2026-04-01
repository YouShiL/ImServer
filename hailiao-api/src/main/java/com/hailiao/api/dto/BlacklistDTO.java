package com.hailiao.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.util.Date;

@Schema(description = "黑名单DTO - 黑名单详细信息")
public class BlacklistDTO {

    @Schema(description = "黑名单ID", type = "Long", example = "1", title = "黑名单记录唯一标识")
    private Long id;

    @Schema(description = "用户ID", type = "Long", example = "1", title = "拉黑用户的ID")
    private Long userId;

    @Schema(description = "被拉黑用户ID", type = "Long", example = "2", title = "被拉黑的用户ID")
    private Long blockedUserId;

    @Schema(description = "拉黑时间", type = "Date", example = "2026-03-12T10:00:00", title = "添加到黑名单的时间")
    private Date createdAt;

    @Schema(description = "被拉黑用户信息", title = "被拉黑用户的详细信息")
    private UserDTO blockedUserInfo;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public Long getBlockedUserId() { return blockedUserId; }
    public void setBlockedUserId(Long blockedUserId) { this.blockedUserId = blockedUserId; }

    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }

    public UserDTO getBlockedUserInfo() { return blockedUserInfo; }
    public void setBlockedUserInfo(UserDTO blockedUserInfo) { this.blockedUserInfo = blockedUserInfo; }
}
