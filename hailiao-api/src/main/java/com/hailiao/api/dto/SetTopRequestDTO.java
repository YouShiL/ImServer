package com.hailiao.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;

/**
 * 设置会话置顶请求DTO
 *
 * @author 嗨聊开发团队
 * @version 1.0.0
 */
@Schema(description = "设置会话置顶请求DTO")
public class SetTopRequestDTO {

    @Schema(description = "会话类型（1：私聊，2：群聊）", required = true, example = "1")
    private Integer type;

    @Schema(description = "是否置顶", required = true, example = "true")
    private Boolean isTop;

    public Integer getType() { return type; }
    public void setType(Integer type) { this.type = type; }
    public Boolean getIsTop() { return isTop; }
    public void setIsTop(Boolean isTop) { this.isTop = isTop; }
}