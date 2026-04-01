package com.hailiao.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "用户注册请求DTO - 用户注册接口的请求参数")
public class RegisterRequestDTO {

    @Schema(description = "手机号", type = "String", required = true, example = "13800138000", 
            title = "用户手机号，用于登录和唯一标识，必须为11位数字")
    private String phone;

    @Schema(description = "密码", type = "String", required = true, example = "password123", 
            title = "用户密码，长度6-20位，建议包含字母和数字")
    private String password;

    @Schema(description = "昵称", type = "String", required = false, example = "新用户", 
            title = "用户昵称，长度1-50个字符，不传则使用默认昵称")
    private String nickname;

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getNickname() {
        return nickname;
    }

    public void setNickname(String nickname) {
        this.nickname = nickname;
    }
}
