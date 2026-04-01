package com.hailiao.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "认证响应DTO - 登录/注册成功后返回的用户信息和令牌")
public class AuthResponseDTO {

    @Schema(description = "用户信息", title = "登录/注册用户的详细信息")
    private UserDTO user;

    @Schema(description = "JWT访问令牌", type = "String", example = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMDAwMDAwMDAxIiwidXNlcm5hbWUiOiIxMzgwMDEzODAwMCIsInNlbnRfdGltZSI6MTcwNjc0MDgwMCwiZXhwIjoxNzA2ODI3MjAwfQ.xxxxx", title = "用于后续接口认证的JWT令牌，有效期7天")
    private String token;

    public UserDTO getUser() { return user; }
    public void setUser(UserDTO user) { this.user = user; }
    public String getToken() { return token; }
    public void setToken(String token) { this.token = token; }
}
