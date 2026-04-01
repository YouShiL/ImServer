package com.hailiao.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;

/**
 * 更新在线状态请求DTO
 *
 * @author 嗨聊开发团队
 * @version 1.0.0
 */
@Schema(description = "更新在线状态请求DTO")
public class UpdateOnlineStatusRequestDTO {

    @Schema(description = "在线状态，0-离线，1-在线，2-忙碌，3-离开", required = true, example = "1")
    private Integer status;

    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }
}