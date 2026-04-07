package com.hailiao.common.model;

/**
 * App 端 PUT /api/user/profile 的 JSON patch 标记：仅当对应键出现在请求体中时
 * {@code true}，用于区分「未传不改」与「传了（含 null / 空串）则按资料更新规则处理」。
 */
public final class UserProfilePatchFlags {

    private final boolean nickname;
    private final boolean avatar;
    private final boolean signature;
    private final boolean region;
    private final boolean birthday;
    private final boolean gender;

    public UserProfilePatchFlags(
            boolean nickname,
            boolean avatar,
            boolean signature,
            boolean region,
            boolean birthday,
            boolean gender) {
        this.nickname = nickname;
        this.avatar = avatar;
        this.signature = signature;
        this.region = region;
        this.birthday = birthday;
        this.gender = gender;
    }

    public boolean isNickname() {
        return nickname;
    }

    public boolean isAvatar() {
        return avatar;
    }

    public boolean isSignature() {
        return signature;
    }

    public boolean isRegion() {
        return region;
    }

    public boolean isBirthday() {
        return birthday;
    }

    public boolean isGender() {
        return gender;
    }
}
