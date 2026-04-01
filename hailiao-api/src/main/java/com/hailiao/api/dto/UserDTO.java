package com.hailiao.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.util.Date;

@Schema(description = "用户信息DTO - 用户详细信息数据结构")
public class UserDTO {

    @Schema(description = "数据库主键ID", type = "Long", example = "1", title = "数据库自增主键，非业务ID")
    private Long id;

    @Schema(description = "用户业务ID", type = "String", example = "1000000001", title = "10位数字组成的唯一业务标识符，用于用户间互相识别")
    private String userId;

    @Schema(description = "手机号", type = "String", example = "13800138000", title = "11位手机号码，用于登录和好友搜索")
    private String phone;

    @Schema(description = "用户昵称", type = "String", example = "测试用户", title = "用户显示名称，长度1-20个字符")
    private String nickname;

    @Schema(description = "头像URL", type = "String", example = "https://example.com/avatar.jpg", title = "用户头像图片地址，支持HTTP/HTTPS URL")
    private String avatar;

    @Schema(description = "性别", type = "Integer", example = "0", title = "性别标识：0-未知 1-男 2-女")
    private Integer gender;

    @Schema(description = "地区", type = "String", example = "北京市朝阳区", title = "用户所在地区，最长50个字符")
    private String region;

    @Schema(description = "个性签名", type = "String", example = "这是我的个性签名", title = "用户个性签名，最长100个字符")
    private String signature;

    @Schema(description = "聊天背景URL", type = "String", example = "https://example.com/background.jpg", title = "聊天背景图片地址")
    private String background;

    @Schema(description = "在线状态", type = "Integer", example = "1", title = "在线状态：0-离线 1-在线 2-忙碌 3-勿扰")
    private Integer onlineStatus;

    @Schema(description = "是否VIP", type = "Boolean", example = "false", title = "是否为VIP用户")
    private Boolean isVip;

    @Schema(description = "是否使用靓号", type = "Boolean", example = "false", title = "是否使用了靓号")
    private Boolean isPrettyNumber;

    @Schema(description = "靓号", type = "String", example = "8888888888", title = "如果使用靓号，显示靓号号码")
    private String prettyNumber;

    @Schema(description = "好友数量上限", type = "Integer", example = "1000", title = "允许添加的好友最大数量")
    private Integer friendLimit;

    @Schema(description = "群组数量上限", type = "Integer", example = "50", title = "允许创建的群组最大数量")
    private Integer groupLimit;

    @Schema(description = "群组成员数量上限", type = "Integer", example = "200", title = "群组成员最大数量")
    private Integer groupMemberLimit;

    @Schema(description = "设备锁状态", type = "Boolean", example = "false", title = "是否开启了设备锁")
    private Boolean deviceLock;

    private Boolean showOnlineStatus;

    private Boolean showLastOnline;

    private Boolean allowSearchByPhone;

    private Boolean needFriendVerification;

    @Schema(description = "账号状态", type = "Integer", example = "1", title = "账号状态：0-禁用 1-正常")
    private Integer status;

    @Schema(description = "创建时间", type = "Date", example = "2026-03-12T13:30:00", title = "账号创建时间，ISO 8601格式")
    private Date createdAt;

    @Schema(description = "更新时间", type = "Date", example = "2026-03-12T13:30:00", title = "最后更新时间，ISO 8601格式")
    private Date updatedAt;

    @Schema(description = "最后登录时间", type = "Date", example = "2026-03-12T13:30:00", title = "最后登录时间，ISO 8601格式")
    private Date lastLoginAt;

    @Schema(description = "最后登录IP", type = "String", example = "127.0.0.1", title = "最后登录的IP地址")
    private String lastLoginIp;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getNickname() { return nickname; }
    public void setNickname(String nickname) { this.nickname = nickname; }

    public String getAvatar() { return avatar; }
    public void setAvatar(String avatar) { this.avatar = avatar; }

    public Integer getGender() { return gender; }
    public void setGender(Integer gender) { this.gender = gender; }

    public String getRegion() { return region; }
    public void setRegion(String region) { this.region = region; }

    public String getSignature() { return signature; }
    public void setSignature(String signature) { this.signature = signature; }

    public String getBackground() { return background; }
    public void setBackground(String background) { this.background = background; }

    public Integer getOnlineStatus() { return onlineStatus; }
    public void setOnlineStatus(Integer onlineStatus) { this.onlineStatus = onlineStatus; }

    public Boolean getIsVip() { return isVip; }
    public void setIsVip(Boolean isVip) { this.isVip = isVip; }

    public Boolean getIsPrettyNumber() { return isPrettyNumber; }
    public void setIsPrettyNumber(Boolean isPrettyNumber) { this.isPrettyNumber = isPrettyNumber; }

    public String getPrettyNumber() { return prettyNumber; }
    public void setPrettyNumber(String prettyNumber) { this.prettyNumber = prettyNumber; }

    public Integer getFriendLimit() { return friendLimit; }
    public void setFriendLimit(Integer friendLimit) { this.friendLimit = friendLimit; }

    public Integer getGroupLimit() { return groupLimit; }
    public void setGroupLimit(Integer groupLimit) { this.groupLimit = groupLimit; }

    public Integer getGroupMemberLimit() { return groupMemberLimit; }
    public void setGroupMemberLimit(Integer groupMemberLimit) { this.groupMemberLimit = groupMemberLimit; }

    public Boolean getDeviceLock() { return deviceLock; }
    public void setDeviceLock(Boolean deviceLock) { this.deviceLock = deviceLock; }

    public Boolean getShowOnlineStatus() { return showOnlineStatus; }
    public void setShowOnlineStatus(Boolean showOnlineStatus) { this.showOnlineStatus = showOnlineStatus; }

    public Boolean getShowLastOnline() { return showLastOnline; }
    public void setShowLastOnline(Boolean showLastOnline) { this.showLastOnline = showLastOnline; }

    public Boolean getAllowSearchByPhone() { return allowSearchByPhone; }
    public void setAllowSearchByPhone(Boolean allowSearchByPhone) { this.allowSearchByPhone = allowSearchByPhone; }

    public Boolean getNeedFriendVerification() { return needFriendVerification; }
    public void setNeedFriendVerification(Boolean needFriendVerification) { this.needFriendVerification = needFriendVerification; }

    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }

    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }

    public Date getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Date updatedAt) { this.updatedAt = updatedAt; }

    public Date getLastLoginAt() { return lastLoginAt; }
    public void setLastLoginAt(Date lastLoginAt) { this.lastLoginAt = lastLoginAt; }

    public String getLastLoginIp() { return lastLoginIp; }
    public void setLastLoginIp(String lastLoginIp) { this.lastLoginIp = lastLoginIp; }
}
