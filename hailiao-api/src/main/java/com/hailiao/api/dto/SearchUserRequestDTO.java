package com.hailiao.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;

/**
 * 搜索用户请求DTO
 *
 * @author 嗨聊开发团队
 * @version 1.0.0
 */
@Schema(description = "搜索用户请求DTO")
public class SearchUserRequestDTO {

    @Schema(description = "搜索关键词，手机号或用户唯一标识", required = true, example = "13800138000")
    private String keyword;

    @Schema(description = "搜索类型，phone-手机号，userId-用户唯一标识", required = true, example = "phone")
    private String type;

    public String getKeyword() { return keyword; }
    public void setKeyword(String keyword) { this.keyword = keyword; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
}