package com.hailiao.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;

/**
 * 添加到黑名单请求DTO
 *
 * @author 嗨聊开发团队
 * @version 1.0.0
 */
@Schema(description = "添加到黑名单请求DTO")
public class AddToBlacklistRequestDTO {

    @Schema(description = "被拉黑用户ID", required = true, example = "2")
    private Long blockedUserId;

    public Long getBlockedUserId() { return blockedUserId; }
    public void setBlockedUserId(Long blockedUserId) { this.blockedUserId = blockedUserId; }
}