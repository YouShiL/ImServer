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
 * 用户实体。
 */
@Entity
@Table(name = "user")
public class User implements Serializable {
    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", unique = true, nullable = false, length = 20)
    private String userId;

    @Column(name = "phone", unique = true, nullable = false, length = 20)
    private String phone;

    @Column(name = "password", nullable = false, length = 100)
    private String password;

    @Column(name = "nickname", length = 50)
    private String nickname;

    @Column(name = "avatar", length = 255)
    private String avatar;

    @Column(name = "gender")
    private Integer gender;

    @Column(name = "region", length = 100)
    private String region;

    @Column(name = "signature", length = 200)
    private String signature;

    @Column(name = "background", length = 255)
    private String background;

    @Column(name = "online_status")
    private Integer onlineStatus;

    @Column(name = "last_online_at")
    private Date lastOnlineAt;

    @Column(name = "show_online_status")
    private Boolean showOnlineStatus;

    @Column(name = "show_last_online")
    private Boolean showLastOnline;

    @Column(name = "allow_search_by_phone")
    private Boolean allowSearchByPhone;

    @Column(name = "need_friend_verification")
    private Boolean needFriendVerification;

    @Column(name = "is_vip")
    private Boolean isVip;

    @Column(name = "is_pretty_number")
    private Boolean isPrettyNumber;

    @Column(name = "pretty_number", length = 20)
    private String prettyNumber;

    @Column(name = "friend_limit")
    private Integer friendLimit;

    @Column(name = "group_limit")
    private Integer groupLimit;

    @Column(name = "group_member_limit")
    private Integer groupMemberLimit;

    @Column(name = "device_lock")
    private Boolean deviceLock;

    @Column(name = "status")
    private Integer status;

    @Column(name = "created_at")
    private Date createdAt;

    @Column(name = "updated_at")
    private Date updatedAt;

    @Column(name = "last_login_at")
    private Date lastLoginAt;

    @Column(name = "last_login_ip", length = 50)
    private String lastLoginIp;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

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

    public Date getLastOnlineAt() { return lastOnlineAt; }
    public void setLastOnlineAt(Date lastOnlineAt) { this.lastOnlineAt = lastOnlineAt; }

    public Boolean getShowOnlineStatus() { return showOnlineStatus; }
    public void setShowOnlineStatus(Boolean showOnlineStatus) { this.showOnlineStatus = showOnlineStatus; }

    public Boolean getShowLastOnline() { return showLastOnline; }
    public void setShowLastOnline(Boolean showLastOnline) { this.showLastOnline = showLastOnline; }

    public Boolean getAllowSearchByPhone() { return allowSearchByPhone; }
    public void setAllowSearchByPhone(Boolean allowSearchByPhone) { this.allowSearchByPhone = allowSearchByPhone; }

    public Boolean getNeedFriendVerification() { return needFriendVerification; }
    public void setNeedFriendVerification(Boolean needFriendVerification) { this.needFriendVerification = needFriendVerification; }

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
