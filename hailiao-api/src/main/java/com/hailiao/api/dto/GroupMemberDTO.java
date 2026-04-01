package com.hailiao.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.util.Date;

@Schema(description = "群组成员DTO - 群组成员详细信息")
public class GroupMemberDTO {

    @Schema(description = "成员ID", type = "Long", example = "1", title = "群组成员关系ID")
    private Long id;

    @Schema(description = "群组ID", type = "Long", example = "1", title = "所属群组的ID")
    private Long groupId;

    @Schema(description = "用户ID", type = "Long", example = "2", title = "成员的用户ID")
    private Long userId;

    @Schema(description = "成员昵称", type = "String", example = "群昵称", title = "成员在群中的昵称")
    private String nickname;

    @Schema(description = "成员角色", type = "Integer", example = "0", title = "成员角色：0-普通成员 1-管理员 2-群主")
    private Integer role;

    @Schema(description = "是否静音", type = "Boolean", example = "false", title = "是否接收群消息通知")
    private Boolean isMute;

    @Schema(description = "加入时间", type = "Date", example = "2026-03-12T10:00:00", title = "加入群组的时间")
    private Date joinedAt;

    @Schema(description = "成员用户信息", title = "成员的用户详细信息")
    private UserDTO userInfo;

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

    public Date getJoinedAt() { return joinedAt; }
    public void setJoinedAt(Date joinedAt) { this.joinedAt = joinedAt; }

    public UserDTO getUserInfo() { return userInfo; }
    public void setUserInfo(UserDTO userInfo) { this.userInfo = userInfo; }
}
