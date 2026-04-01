package com.hailiao.api.dto;

import java.util.Date;

public class GroupJoinRequestDTO {
    private Long id;
    private Long groupId;
    private Long userId;
    private String message;
    private Integer status;
    private Long handledBy;
    private Date handledAt;
    private Date createdAt;
    private UserDTO userInfo;
    private GroupDTO groupInfo;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getGroupId() { return groupId; }
    public void setGroupId(Long groupId) { this.groupId = groupId; }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }

    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }

    public Long getHandledBy() { return handledBy; }
    public void setHandledBy(Long handledBy) { this.handledBy = handledBy; }

    public Date getHandledAt() { return handledAt; }
    public void setHandledAt(Date handledAt) { this.handledAt = handledAt; }

    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }

    public UserDTO getUserInfo() { return userInfo; }
    public void setUserInfo(UserDTO userInfo) { this.userInfo = userInfo; }

    public GroupDTO getGroupInfo() { return groupInfo; }
    public void setGroupInfo(GroupDTO groupInfo) { this.groupInfo = groupInfo; }
}
