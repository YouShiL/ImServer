package com.hailiao.api.dto;

import java.util.Date;

public class FriendRequestDTO {
    private Long id;
    private Long fromUserId;
    private Long toUserId;
    private String remark;
    private String message;
    private Integer status;
    private Date handledAt;
    private Date createdAt;
    private UserDTO fromUserInfo;
    private UserDTO toUserInfo;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getFromUserId() { return fromUserId; }
    public void setFromUserId(Long fromUserId) { this.fromUserId = fromUserId; }
    public Long getToUserId() { return toUserId; }
    public void setToUserId(Long toUserId) { this.toUserId = toUserId; }
    public String getRemark() { return remark; }
    public void setRemark(String remark) { this.remark = remark; }
    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }
    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }
    public Date getHandledAt() { return handledAt; }
    public void setHandledAt(Date handledAt) { this.handledAt = handledAt; }
    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }
    public UserDTO getFromUserInfo() { return fromUserInfo; }
    public void setFromUserInfo(UserDTO fromUserInfo) { this.fromUserInfo = fromUserInfo; }
    public UserDTO getToUserInfo() { return toUserInfo; }
    public void setToUserInfo(UserDTO toUserInfo) { this.toUserInfo = toUserInfo; }
}
