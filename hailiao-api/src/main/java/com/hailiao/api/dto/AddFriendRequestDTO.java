package com.hailiao.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;

/**
 * 添加好友请求DTO
 *
 * @author 嗨聊开发团队
 * @version 1.0.0
 */
@Schema(description = "添加好友请求DTO")
public class AddFriendRequestDTO {

    @Schema(description = "好友ID", required = true, example = "2")
    private Long friendId;

    @Schema(description = "好友备注", required = false, example = "老王")
    private String remark;

    public Long getFriendId() { return friendId; }
    public void setFriendId(Long friendId) { this.friendId = friendId; }
    public String getRemark() { return remark; }
    public void setRemark(String remark) { this.remark = remark; }
}