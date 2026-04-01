package com.hailiao.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;

/**
 * 修改密码请求DTO
 *
 * @author 嗨聊开发团队
 * @version 1.0.0
 */
@Schema(description = "修改密码请求DTO")
public class ChangePasswordRequestDTO {

    @Schema(description = "原密码", required = true, example = "oldPassword123")
    private String oldPassword;

    @Schema(description = "新密码", required = true, example = "newPassword123")
    private String newPassword;

    public String getOldPassword() { return oldPassword; }
    public void setOldPassword(String oldPassword) { this.oldPassword = oldPassword; }
    public String getNewPassword() { return newPassword; }
    public void setNewPassword(String newPassword) { this.newPassword = newPassword; }
}