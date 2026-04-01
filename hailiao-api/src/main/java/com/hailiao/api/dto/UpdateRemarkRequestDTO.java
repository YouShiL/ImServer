package com.hailiao.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;

/**
 * 更新好友备注请求DTO
 *
 * @author 嗨聊开发团队
 * @version 1.0.0
 */
@Schema(description = "更新好友备注请求DTO")
public class UpdateRemarkRequestDTO {

    @Schema(description = "好友备注", required = true, example = "新备注")
    private String remark;

    public String getRemark() { return remark; }
    public void setRemark(String remark) { this.remark = remark; }
}